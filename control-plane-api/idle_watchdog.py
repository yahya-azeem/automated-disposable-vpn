#!/usr/bin/env python3
"""
Serverless Idle Watchdog for Automated VPN Teardown.
Can be deployed as an AWS Lambda function (lambda_handler) or run as a standalone cron job.
Queries AWS CloudWatch metrics (NetworkOut) for active EC2 instances matching the TrustTunnel tag.
If traffic remains below the idle threshold for the specified duration, triggers the GitHub Actions destroy workflow.
"""

import os
import urllib.request
import urllib.parse
import json
from datetime import datetime, timedelta
import boto3

# Configuration Constants
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "YOUR_GITHUB_PAT_HERE")
GITHUB_REPO = os.environ.get("GITHUB_REPO", "OWNER/REPO")
IDLE_THRESHOLD_BYTES = int(os.environ.get("IDLE_THRESHOLD_BYTES", 512000)) # 500 KB per 15 mins
IDLE_DURATION_MINUTES = int(os.environ.get("IDLE_DURATION_MINUTES", 30))

def trigger_github_destroy_workflow():
    """Triggers the destroy-active.yml workflow via GitHub REST API."""
    url = f"https://api.github.com/repos/{GITHUB_REPO}/actions/workflows/destroy-active.yml/dispatches"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json"
    }
    data = json.dumps({"ref": "main"}).encode("utf-8")
    
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as response:
            print(f"Successfully dispatched destroy workflow. HTTP Status: {response.status}")
            return True
    except Exception as e:
        print(f"Failed to trigger destroy workflow: {e}")
        return False

def check_ec2_idle_status(ec2_client, cw_client, region):
    """Finds active VPN instances in a region and checks their network metrics."""
    instances = ec2_client.describe_instances(
        Filters=[
            {"Name": "tag:Project", "Values": ["TrustTunnel-VPN"]},
            {"Name": "instance-state-name", "Values": ["running"]}
        ]
    )
    
    active_instances = []
    for reservation in instances.get("Reservations", []):
        for instance in reservation.get("Instances", []):
            active_instances.append(instance["InstanceId"])
            
    if not active_instances:
        return False # No active instances in this region

    for instance_id in active_instances:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=IDLE_DURATION_MINUTES)
        
        metrics = cw_client.get_metric_statistics(
            Namespace="AWS/EC2",
            MetricName="NetworkOut",
            Dimensions=[{"Name": "InstanceId", "Value": instance_id}],
            StartTime=start_time,
            EndTime=end_time,
            Period=300, # 5-minute periods
            Statistics=["Sum"]
        )
        
        datapoints = metrics.get("Datapoints", [])
        if not datapoints:
            continue
            
        total_network_out = sum(dp["Sum"] for dp in datapoints)
        print(f"Region {region} | Instance {instance_id} | Total NetworkOut over last {IDLE_DURATION_MINUTES} mins: {total_network_out} bytes")
        
        if total_network_out < IDLE_THRESHOLD_BYTES:
            print(f"[ALARM] Instance {instance_id} is IDLE! Triggering automated teardown...")
            return trigger_github_destroy_workflow()
            
    return False

def lambda_handler(event, context):
    """AWS Lambda entry point."""
    regions = ["us-east-1", "eu-central-1", "ap-northeast-1"]
    teardown_triggered = False
    
    for region in regions:
        try:
            ec2 = boto3.client("ec2", region_name=region)
            cw = boto3.client("cloudwatch", region_name=region)
            if check_ec2_idle_status(ec2, cw, region):
                teardown_triggered = True
                break # Teardown initiated, exit loop
        except Exception as e:
            print(f"Error checking region {region}: {e}")
            
    return {
        "statusCode": 200,
        "body": json.dumps({"teardown_triggered": teardown_triggered})
    }

if __name__ == "__main__":
    lambda_handler({}, None)

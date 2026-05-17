#!/usr/bin/env python3
"""
AWS Free Tier Compliance Audit Script.
Queries EC2 instances and EBS volumes across all AWS regions.
Verifies that only a single micro-instance is running and total EBS storage is within the 30 GB Free Tier limit.
Alerts immediately if any non-compliant resources or multiple instances are discovered.
"""

import sys
import boto3

FREE_TIER_ELIGIBLE_INSTANCES = ["t4g.micro", "t3.micro", "t2.micro"]
FREE_TIER_MAX_EBS_GB = 30

def audit_free_tier_compliance():
    ec2_global = boto3.client("ec2", region_name="us-east-1")
    regions = [reg["RegionName"] for reg in ec2_global.describe_regions()["Regions"]]
    
    total_running_instances = 0
    total_ebs_volume_gb = 0
    non_compliant_resources = []
    
    print("="*60)
    print("🔍 STARTING AWS FREE TIER COMPLIANCE AUDIT...")
    print("="*60)
    
    for region in regions:
        try:
            ec2 = boto3.client("ec2", region_name=region)
            
            # Check EC2 Instances
            instances = ec2.describe_instances(Filters=[{"Name": "instance-state-name", "Values": ["running"]}])
            for reservation in instances.get("Reservations", []):
                for inst in reservation.get("Instances", []):
                    total_running_instances += 1
                    inst_type = inst["InstanceType"]
                    inst_id = inst["InstanceId"]
                    
                    print(f"📍 Region: {region} | Running Instance: {inst_id} ({inst_type})")
                    if inst_type not in FREE_TIER_ELIGIBLE_INSTANCES:
                        non_compliant_resources.append(f"Non-Free-Tier Instance {inst_id} ({inst_type}) in {region}")
                        
            # Check EBS Volumes
            volumes = ec2.describe_volumes()
            for vol in volumes.get("Volumes", []):
                vol_size = vol["Size"]
                vol_id = vol["VolumeId"]
                total_ebs_volume_gb += vol_size
                print(f"📍 Region: {region} | EBS Volume: {vol_id} ({vol_size} GB)")
                
        except Exception as e:
            # Some regions might not be enabled or accessible
            continue

    print("="*60)
    print("📊 AUDIT SUMMARY")
    print("="*60)
    print(f"Total Running EC2 Instances : {total_running_instances} (Max Allowed: 1)")
    print(f"Total Allocated EBS Storage : {total_ebs_volume_gb} GB (Max Allowed: {FREE_TIER_MAX_EBS_GB} GB)")
    
    status_passed = True
    if total_running_instances > 1:
        print("❌ [VIOLATION] Multiple running instances detected! Free Tier allows 750 hours/month total across all instances.")
        status_passed = False
    elif total_running_instances == 1:
        print("✅ EC2 Instance count is within Free Tier limits.")
    else:
        print("✅ No running EC2 instances detected.")
        
    if total_ebs_volume_gb > FREE_TIER_MAX_EBS_GB:
        print(f"❌ [VIOLATION] Total EBS storage ({total_ebs_volume_gb} GB) exceeds Free Tier limit ({FREE_TIER_MAX_EBS_GB} GB)!")
        status_passed = False
    else:
        print(f"✅ EBS Storage is within Free Tier limits ({total_ebs_volume_gb} GB / {FREE_TIER_MAX_EBS_GB} GB).")
        
    if non_compliant_resources:
        print("❌ [VIOLATION] Non-compliant resource types detected:")
        for res in non_compliant_resources:
            print(f"   - {res}")
        status_passed = False
        
    print("="*60)
    if status_passed:
        print("🎉 AUDIT PASSED: All verified resources comply with AWS Free Tier guardrails.")
        sys.exit(0)
    else:
        print("⚠️ AUDIT FAILED: Action required to avoid unexpected AWS charges!")
        sys.exit(1)

if __name__ == "__main__":
    audit_free_tier_compliance()

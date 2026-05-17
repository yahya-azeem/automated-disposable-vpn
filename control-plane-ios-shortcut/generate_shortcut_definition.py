#!/usr/bin/env python3
import json
import os

def generate_shortcut_json():
    shortcut_structure = {
        "WFWorkflowMinimumClientVersion": 1100,
        "WFWorkflowMinimumClientVersionString": "11.0",
        "WFWorkflowActions": [
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
                "WFWorkflowActionParameters": {
                    "WFTextActionText": "YOUR_GITHUB_PAT_HERE",
                    "CustomOutputName": "GitHubToken"
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.url",
                "WFWorkflowActionParameters": {
                    "WFURLActionURL": "https://api.github.com/repos/OWNER/REPO",
                    "CustomOutputName": "GitHubApiBase"
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.choosefrommenu",
                "WFWorkflowActionParameters": {
                    "WFMenuPrompt": "Select TrustTunnel VPN Action",
                    "WFMenuItems": [
                        "Deploy N. Virginia (us-east-1)",
                        "Deploy Frankfurt (eu-central-1)",
                        "Deploy Tokyo (ap-northeast-1)",
                        "Destroy Active VPN",
                        "Check Status"
                    ]
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.downloadurl",
                "WFWorkflowActionParameters": {
                    "WFURL": {"Value": {"string": "Attachments.GitHubApiBase/actions/workflows/deploy-region.yml/dispatches"}},
                    "WFHTTPMethod": "POST",
                    "WFHTTPHeaders": [
                        {"Key": "Authorization", "Value": "Bearer Attachments.GitHubToken"},
                        {"Key": "Accept", "Value": "application/vnd.github+json"},
                        {"Key": "X-GitHub-Api-Version", "Value": "2022-11-28"}
                    ],
                    "WFHTTPBodyType": "JSON",
                    "WFJSONValues": [
                        {"Key": "ref", "Value": "main"},
                        {"Key": "inputs", "Value": {"region": "us-east-1"}}
                    ]
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.repeat.count",
                "WFWorkflowActionParameters": {
                    "WFRepeatCount": 20
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.delay",
                "WFWorkflowActionParameters": {
                    "WFDelayTime": 15
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.downloadurl",
                "WFWorkflowActionParameters": {
                    "WFURL": {"Value": {"string": "Attachments.GitHubApiBase/actions/runs?per_page=1"}},
                    "WFHTTPMethod": "GET",
                    "WFHTTPHeaders": [
                        {"Key": "Authorization", "Value": "Bearer Attachments.GitHubToken"},
                        {"Key": "Accept", "Value": "application/vnd.github+json"}
                    ]
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.extractarchive",
                "WFWorkflowActionParameters": {
                    "WFArchiveFormat": "Zip"
                }
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.share",
                "WFWorkflowActionParameters": {
                    "WFInput": {"Value": {"string": "Attachments.ExtractArchiveOutput"}}
                }
            }
        ]
    }

    output_path = os.path.join(os.path.dirname(__file__), "TrustTunnel_Control_Plane.shortcut.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(shortcut_structure, f, indent=4)
    print(f"Successfully generated iOS Shortcut definition at: {output_path}")

if __name__ == "__main__":
    generate_shortcut_json()

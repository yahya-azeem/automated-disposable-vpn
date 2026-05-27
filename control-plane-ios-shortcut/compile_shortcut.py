#!/usr/bin/env python3
import json
import plistlib
import os

def compile_shortcut():
    json_path = os.path.join(os.path.dirname(__file__), "TrustTunnel_Control_Plane.shortcut.json")
    shortcut_path = os.path.join(os.path.dirname(__file__), "TrustTunnel_Control_Plane.shortcut")

    if not os.path.exists(json_path):
        print(f"Error: JSON definition not found at {json_path}")
        return

    with open(json_path, "r", encoding="utf-8") as f:
        shortcut_data = json.load(f)

    # Write as XML Property List (plist) format
    with open(shortcut_path, "wb") as f:
        plistlib.dump(shortcut_data, f, fmt=plistlib.FMT_XML)
    
    print(f"Successfully compiled XML plist shortcut to: {shortcut_path}")

if __name__ == "__main__":
    compile_shortcut()

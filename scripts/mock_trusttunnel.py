#!/usr/bin/env python3
"""
Mock TrustTunnel VPN Endpoint Daemon & Client Generator.
Provides a robust, fully functional simulation of the TrustTunnel VPN binary.
Supports daemon mode (--daemon / -d) listening on 0.0.0.0:443 and client config verification.
Guarantees clean CI/CD execution and local testing on Alpine Linux.
"""

import sys
import os
import argparse
import json
import socket
import http.server
import socketserver
import threading

class MockVPNDaemonHandler(http.server.BaseHTTPRequestHandler):
    """Handles mock VPN keepalive and health check requests simulating HTTPS encapsulation."""
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        response = {
            "status": "healthy",
            "tunnel_mode": "system-wide",
            "client_count": 1,
            "active_dns_upstream": ["1.1.1.1", "8.8.8.8"]
        }
        self.wfile.write(json.dumps(response).encode("utf-8"))

    def log_message(self, format, *args):
        # Log to file or stdout matching daemon config
        print(f"[TrustTunnel Daemon] {self.client_address[0]} - {format%args}")

def run_daemon(config_path):
    """Starts the mock VPN endpoint server."""
    if not os.path.exists(config_path):
        print(f"Error: Configuration file not found at {config_path}")
        sys.exit(1)
        
    with open(config_path, "r") as f:
        config = json.load(f)
        
    listen_addr = config.get("listen_address", "0.0.0.0:443")
    host, port = listen_addr.split(":")
    port = int(port)
    
    print(f"[TrustTunnel] Starting VPN Endpoint Daemon on {host}:{port}...")
    print(f"[TrustTunnel] Tunnel Mode: {config.get('tunnel_mode')} | Subnet: {config.get('tunnel_subnet')}")
    
    # Start TCP server simulating VPN endpoint
    with socketserver.TCPServer((host, port), MockVPNDaemonHandler) as httpd:
        print("[TrustTunnel] Daemon is active and listening for tunneled packets.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[TrustTunnel] Shutting down daemon.")

def generate_client_keys():
    """Simulates generating cryptographic key pairs for client configuration."""
    # Return mock static keys for deterministic verification
    return {
        "private_key": "c0ntr0lPlan3Privat3K3yM0ckValu3TrustTunn3l=",
        "public_key": "s3rv3rPublicK3yM0ckValu3TrustTunn3lEndpoint="
    }

def main():
    parser = argparse.ArgumentParser(description="TrustTunnel VPN Endpoint Utility")
    parser.add_argument("-c", "--config", help="Path to endpoint configuration file", default="/etc/trusttunnel/endpoint.conf")
    parser.add_argument("-d", "--daemon", action="store_true", help="Run in background daemon mode")
    parser.add_argument("--generate-client", action="store_true", help="Generate client profile keys")
    
    args = parser.parse_args()
    
    if args.generate_client:
        keys = generate_client_keys()
        print(json.dumps(keys, indent=2))
        sys.exit(0)
        
    if args.daemon:
        run_daemon(args.config)
    else:
        print("[TrustTunnel] Running in foreground debug mode.")
        run_daemon(args.config)

if __name__ == "__main__":
    main()

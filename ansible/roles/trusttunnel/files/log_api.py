#!/usr/bin/env python3
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess

class LogHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/logs':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            logs = []
            log_file = '/var/log/suricata/eve.json'
            if os.path.exists(log_file):
                try:
                    # Get the last 100 lines of eve.json
                    output = subprocess.check_output(['tail', '-n', '100', log_file]).decode('utf-8')
                    for line in output.strip().split('\n'):
                        if line:
                            logs.append(json.loads(line))
                except Exception as e:
                    logs = [{"error": str(e)}]
            else:
                logs = [{"message": "Suricata log file not found or not yet generated."}]
                
            self.wfile.write(json.dumps(logs).encode())
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == '__main__':
    server_address = ('10.8.0.1', 8000)
    httpd = HTTPServer(server_address, LogHandler)
    print("Starting log API server on 10.8.0.1:8000...")
    httpd.serve_forever()

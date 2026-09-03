#!/usr/bin/env python3
"""Launcher for Kased Graph Analytics Dashboard."""
import http.server
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
DIR = Path(__file__).parent.resolve()

print(f"Starting Kased Graph Analytics Dashboard on http://localhost:{PORT}")
print(f"Press Ctrl+C to stop the server\n")

# Open browser in a thread
def open_browser():
    time.sleep(1)
    subprocess.Popen(f'open http://localhost:{PORT}/dashboard.html'
                     if sys.platform == 'darwin'
                     else f'start http://localhost:{PORT}/dashboard.html'
                     if sys.platform == 'win32'
                     else f'xdg-open http://localhost:{PORT}/dashboard.html')

threading.Thread(target=open_browser, daemon=True).start()

# Start server
handler = http.server.SimpleHTTPRequestHandler
server = http.server.HTTPServer(('0.0.0.0', PORT), handler)
try:
    server.serve_forever()
except KeyboardInterrupt:
    print("\nServer stopped.")
    server.shutdown()

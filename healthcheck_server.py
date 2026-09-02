#!/usr/bin/env python3
"""Minimal stdlib health server for Railway.

/health -> 200 {"status":"ok","bot":<bool>} while the hummingbot process is
alive; 503 when the bot process has died. Hummingbot itself has no HTTP
endpoint (its debug console is SSH on localhost only), so this process check
is the liveness signal for the Railway healthcheck.
"""
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8080"))


def bot_alive():
    # /proc scan (no pgrep dependency — minimal image may lack procps)
    try:
        for pid in os.listdir("/proc"):
            if not pid.isdigit():
                continue
            try:
                with open(f"/proc/{pid}/cmdline", "rb") as f:
                    cmd = f.read().decode(errors="replace")
            except OSError:
                continue
            if "hummingbot_quickstart" in cmd and pid != str(os.getpid()):
                return True
        return False
    except Exception:
        return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/health", "/health/"):
            self.send_response(404)
            self.end_headers()
            return
        alive = bot_alive()
        body = json.dumps({"status": "ok" if alive else "bot_down", "bot": alive}).encode()
        self.send_response(200 if alive else 503)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
#!/usr/bin/env python3
import argparse
import json
import os
import re
import socket
import subprocess
import sys
import time
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from socketserver import TCPServer
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
CONFIG = Path.home() / ".config" / "cyberbrain"
TASK_RE = re.compile(r"^(?P<indent> *)(?:- \[(?P<done>[ xX])\] )(?P<text>.*)$")
DONE_DATE_RE = re.compile(r"^(?P<text>.*?)(?:\s+✓\s+(?P<date>\d{4}-\d{2}-\d{2}))?$")
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def data_dir():
    if not CONFIG.exists():
        raise RuntimeError(f"Missing config: {CONFIG}")
    path = Path(CONFIG.read_text(encoding="utf-8").strip()).expanduser()
    if not path.exists():
        raise RuntimeError(f"Configured data directory does not exist: {path}")
    return path


def split_done_date(text):
    match = DONE_DATE_RE.match(text)
    if not match:
        return text, None
    return match.group("text"), match.group("date")


def source_hint(url):
    if url.startswith("./") or url.startswith("../") or not re.match(r"^[a-z]+://", url):
        return "local"
    host = urlparse(url).netloc.lower()
    if "github" in host:
        return "GitHub"
    if "sharepoint" in host:
        return "SharePoint"
    if "twiki" in host:
        return "TWiki"
    return host.replace("www.", "") or "link"


def parse_note(text):
    links = [{"label": label, "url": url, "source": source_hint(url)} for label, url in LINK_RE.findall(text)]
    return {"text": text, "links": links}


def parse_threads(markdown):
    threads = []
    current = None
    current_task = None

    for raw in markdown.splitlines():
        line = raw.rstrip()
        if line.startswith("## "):
            current = {"name": line[3:].strip(), "summary": "", "tasks": []}
            threads.append(current)
            current_task = None
            continue
        if not current:
            continue
        if line.startswith("Summary:"):
            current["summary"] = line[len("Summary:") :].strip()
            continue

        task = TASK_RE.match(line)
        if task:
            indent = len(task.group("indent"))
            text, date = split_done_date(task.group("text").strip())
            item = {
                "text": text,
                "done": task.group("done").lower() == "x",
                "date": date,
                "notes": [],
                "children": [],
            }
            if indent == 0:
                current["tasks"].append(item)
                current_task = item
            elif indent == 2 and current_task:
                current_task["children"].append(item)
            continue

        if line.startswith("  - ") and current_task:
            current_task["notes"].append(parse_note(line[4:].strip()))

    open_count = 0
    done_count = 0
    for thread in threads:
        thread_open = 0
        thread_done = 0
        for task in thread["tasks"]:
            items = [task] + task["children"]
            thread_open += sum(1 for item in items if not item["done"])
            thread_done += sum(1 for item in items if item["done"])
        thread["counts"] = {"open": thread_open, "done": thread_done}
        open_count += thread_open
        done_count += thread_done

    return {"threads": threads, "counts": {"threads": len(threads), "open": open_count, "done": done_count}}


def is_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        return sock.connect_ex(("127.0.0.1", port)) != 0


def find_port(start):
    port = start
    while port < start + 100:
        if is_free(port):
            return port
        port += 1
    raise RuntimeError("No free local port found")


def api_ready(port):
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/api/threads", timeout=0.2):
            return True
    except Exception:
        return False


def launch_daemon(port, open_browser):
    port = find_port(port)
    log_path = Path(os.environ.get("TMPDIR", "/tmp")) / "cyberbrain-web.log"
    log = log_path.open("ab")
    subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--port", str(port), "--no-open"],
        stdin=subprocess.DEVNULL,
        stdout=log,
        stderr=log,
        start_new_session=True,
    )
    for _ in range(20):
        if api_ready(port):
            break
        time.sleep(0.1)
    url = f"http://127.0.0.1:{port}/"
    if open_browser:
        webbrowser.open(url)
    print(f"Cyberbrain dashboard: {url}")
    print(f"Log: {log_path}")


class Handler(BaseHTTPRequestHandler):
    server_version = "CyberbrainWeb/1.0"

    def send(self, status, body, content_type):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        parsed = urlparse(self.path)
        try:
            if parsed.path in ("/", "/index.html"):
                self.send(200, (ROOT / "dashboard" / "index.html").read_text(encoding="utf-8"), "text/html; charset=utf-8")
            elif parsed.path == "/api/threads":
                md = (self.server.data_dir / "threads.md").read_text(encoding="utf-8")
                self.send(200, json.dumps(parse_threads(md)), "application/json; charset=utf-8")
            elif parsed.path == "/threads.md":
                self.send(200, (self.server.data_dir / "threads.md").read_text(encoding="utf-8"), "text/markdown; charset=utf-8")
            elif parsed.path.startswith("/notes/"):
                self.serve_note(parsed.path)
            else:
                self.send(404, "Not found", "text/plain; charset=utf-8")
        except Exception as exc:
            self.send(500, str(exc), "text/plain; charset=utf-8")

    def serve_note(self, path):
        name = unquote(path.removeprefix("/notes/"))
        target = (self.server.data_dir / "notes" / name).resolve()
        notes = (self.server.data_dir / "notes").resolve()
        if notes not in target.parents or not target.is_file():
            self.send(404, "Not found", "text/plain; charset=utf-8")
            return
        self.send(200, target.read_text(encoding="utf-8"), "text/markdown; charset=utf-8")

    def log_message(self, fmt, *args):
        return


class LocalServer(ThreadingHTTPServer):
    def server_bind(self):
        TCPServer.server_bind(self)
        self.server_name = "127.0.0.1"
        self.server_port = self.server_address[1]


def main():
    parser = argparse.ArgumentParser(description="Serve the Cyberbrain dashboard")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--no-open", action="store_true")
    parser.add_argument("--daemon", action="store_true")
    args = parser.parse_args()

    if args.daemon:
        launch_daemon(args.port, not args.no_open)
        return

    port = find_port(args.port)
    server = LocalServer(("127.0.0.1", port), Handler)
    server.data_dir = data_dir()
    url = f"http://127.0.0.1:{port}/"
    print(f"Cyberbrain dashboard: {url}", flush=True)
    if not args.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped", file=sys.stderr)


if __name__ == "__main__":
    main()

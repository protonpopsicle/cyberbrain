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
from pathlib import Path
from socketserver import TCPServer
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
DASHBOARD = ROOT / "dashboard" / "index.html"
CONFIG = Path.home() / ".config" / "cyberbrain"
DEFAULT_PORT = 8765
PORT_SEARCH_LIMIT = 100
STARTUP_CHECKS = 20
STARTUP_CHECK_INTERVAL = 0.1

TASK_RE = re.compile(r"^(?P<indent> *)(?:- \[(?P<done>[ xX])\] )(?P<text>.*)$")
DONE_DATE_RE = re.compile(r"^(?P<text>.*?)(?:\s+✓\s+(?P<date>\d{4}-\d{2}-\d{2}))?$")
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
URL_SCHEME_RE = re.compile(r"^[a-z]+://")


def load_data_dir():
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
    if url.startswith(("./", "../")) or not URL_SCHEME_RE.match(url):
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
    return {
        "text": text,
        "links": [
            {"label": label, "url": url, "source": source_hint(url)}
            for label, url in LINK_RE.findall(text)
        ],
    }


def parse_task(match):
    text, date = split_done_date(match.group("text").strip())
    return {
        "text": text,
        "done": match.group("done").lower() == "x",
        "date": date,
        "notes": [],
        "children": [],
    }


def count_tasks(tasks):
    open_count = 0
    done_count = 0

    for task in tasks:
        items = [task] + task["children"]
        open_count += sum(1 for item in items if not item["done"])
        done_count += sum(1 for item in items if item["done"])

    return {"open": open_count, "done": done_count}


def parse_threads(markdown):
    threads = []
    current_thread = None
    current_task = None

    for raw in markdown.splitlines():
        line = raw.rstrip()

        if line.startswith("## "):
            current_thread = {"name": line[3:].strip(), "summary": "", "tasks": []}
            threads.append(current_thread)
            current_task = None
            continue

        if not current_thread:
            continue

        if line.startswith("Summary:"):
            current_thread["summary"] = line[len("Summary:") :].strip()
            continue

        task_match = TASK_RE.match(line)
        if task_match:
            task = parse_task(task_match)
            indent = len(task_match.group("indent"))

            if indent == 0:
                current_thread["tasks"].append(task)
                current_task = task
            elif indent == 2 and current_task:
                current_task["children"].append(task)
            continue

        if line.startswith("  - ") and current_task:
            current_task["notes"].append(parse_note(line[4:].strip()))

    total_open = 0
    total_done = 0
    for thread in threads:
        thread_counts = count_tasks(thread["tasks"])
        thread["counts"] = thread_counts
        total_open += thread_counts["open"]
        total_done += thread_counts["done"]

    return {
        "threads": threads,
        "counts": {"threads": len(threads), "open": total_open, "done": total_done},
    }


def is_free(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        return sock.connect_ex(("127.0.0.1", port)) != 0


def find_port(start):
    for port in range(start, start + PORT_SEARCH_LIMIT):
        if is_free(port):
            return port
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

    with log_path.open("ab") as log:
        subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), "--port", str(port), "--no-open"],
            stdin=subprocess.DEVNULL,
            stdout=log,
            stderr=log,
            start_new_session=True,
        )

    for _ in range(STARTUP_CHECKS):
        if api_ready(port):
            break
        time.sleep(STARTUP_CHECK_INTERVAL)

    url = f"http://127.0.0.1:{port}/"
    if open_browser:
        webbrowser.open(url)
    print(f"Cyberbrain dashboard: {url}")
    print(f"Log: {log_path}")


class Handler(BaseHTTPRequestHandler):
    server_version = "CyberbrainWeb/1.0"

    def write_response(self, status, body, content_type):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def text_response(self, status, body, content_type="text/plain"):
        self.write_response(status, body, f"{content_type}; charset=utf-8")

    def json_response(self, body):
        self.write_response(200, json.dumps(body), "application/json; charset=utf-8")

    def do_GET(self):
        parsed = urlparse(self.path)
        try:
            self.route(parsed.path)
        except Exception as exc:
            self.text_response(500, str(exc))

    def route(self, path):
        if path in ("/", "/index.html"):
            self.text_response(200, DASHBOARD.read_text(encoding="utf-8"), "text/html")
            return

        if path == "/api/threads":
            markdown = self.read_data_file("threads.md")
            self.json_response(parse_threads(markdown))
            return

        if path == "/threads.md":
            self.text_response(200, self.read_data_file("threads.md"), "text/markdown")
            return

        if path.startswith("/notes/"):
            self.serve_note(path)
            return

        self.text_response(404, "Not found")

    def read_data_file(self, name):
        return (self.server.data_dir / name).read_text(encoding="utf-8")

    def serve_note(self, path):
        name = unquote(path.removeprefix("/notes/"))
        notes_dir = (self.server.data_dir / "notes").resolve()
        target = (notes_dir / name).resolve()

        if notes_dir not in target.parents or not target.is_file():
            self.text_response(404, "Not found")
            return

        self.text_response(200, target.read_text(encoding="utf-8"), "text/markdown")

    def log_message(self, fmt, *args):
        return


class LocalServer(ThreadingHTTPServer):
    def server_bind(self):
        TCPServer.server_bind(self)
        self.server_name = "127.0.0.1"
        self.server_port = self.server_address[1]


def build_parser():
    parser = argparse.ArgumentParser(description="Serve the Cyberbrain dashboard")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--no-open", action="store_true")
    parser.add_argument("--daemon", action="store_true")
    return parser


def main():
    args = build_parser().parse_args()

    if args.daemon:
        launch_daemon(args.port, not args.no_open)
        return

    port = find_port(args.port)
    server = LocalServer(("127.0.0.1", port), Handler)
    server.data_dir = load_data_dir()

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

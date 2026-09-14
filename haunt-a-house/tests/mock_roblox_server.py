#!/usr/bin/env python3
"""Serveur factice imitant les points d'entree Open Cloud utilises par publish/ (pour les tests locaux)."""
import json
import re
import sys
import threading
from email.parser import BytesParser
from email.policy import default as email_policy
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

API_KEY = "test-key"
STATE = {"passes": [], "products": [], "next_id": 1000, "published": [], "place_patches": [], "universe_patches": [], "tasks": {}, "polls": {}}
LOCK = threading.Lock()


def parse_multipart(headers, body):
    content_type = headers.get("Content-Type", "")
    message = BytesParser(policy=email_policy).parsebytes(b"Content-Type: " + content_type.encode() + b"\r\n\r\n" + body)
    fields = {}
    for part in message.iter_parts():
        name = part.get_param("name", header="content-disposition")
        fields[name] = part.get_payload(decode=True).decode("utf-8")
    return fields


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[mock] " + (fmt % args) + "\n")

    def send_json(self, status, payload):
        raw = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def read_body(self):
        length = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(length) if length else b""

    def check_auth(self):
        if self.headers.get("x-api-key") != API_KEY:
            self.send_json(401, {"message": "Invalid API key"})
            return False
        return True

    def do_GET(self):
        if not self.check_auth():
            return
        path = self.path.split("?")[0]
        with LOCK:
            if re.match(r"^/game-passes/v1/universes/\d+/game-passes/creator$", path):
                return self.send_json(200, {"gamePasses": list(STATE["passes"])})
            if re.match(r"^/developer-products/v2/universes/\d+/developer-products/creator$", path):
                return self.send_json(200, {"developerProducts": list(STATE["products"])})
            m = re.match(r"^/cloud/v2/(universes/\d+/places/\d+/luau-execution-sessions/[^/]+/tasks/[^/]+)$", path)
            if m:
                task_path = m.group(1)
                STATE["polls"][task_path] = STATE["polls"].get(task_path, 0) + 1
                state = "COMPLETE" if STATE["polls"][task_path] >= 2 else "PROCESSING"
                return self.send_json(200, {"path": task_path, "state": state})
            m = re.match(r"^/cloud/v2/(universes/\d+/places/\d+/luau-execution-sessions/[^/]+/tasks/[^/]+)/logs$", path)
            if m:
                return self.send_json(200, {"luauExecutionSessionTaskLogs": [{"messages": ["OK    Module partage Config", "Parts de la carte : 1234", "RESULTAT : tous les tests passent"]}]})
        self.send_json(404, {"message": "not found " + path})

    def do_POST(self):
        if not self.check_auth():
            return
        path = self.path.split("?")[0]
        body = self.read_body()
        with LOCK:
            if re.match(r"^/game-passes/v1/universes/\d+/game-passes$", path):
                fields = parse_multipart(self.headers, body)
                STATE["next_id"] += 1
                item = {"gamePassId": STATE["next_id"], "name": fields["name"], "description": fields.get("description", ""), "isForSale": fields.get("isForSale") == "true", "priceInformation": {"defaultPriceInRobux": int(fields["price"])}}
                STATE["passes"].append(item)
                return self.send_json(200, item)
            if re.match(r"^/developer-products/v2/universes/\d+/developer-products$", path):
                fields = parse_multipart(self.headers, body)
                STATE["next_id"] += 1
                item = {"productId": STATE["next_id"], "name": fields["name"], "description": fields.get("description", ""), "isForSale": fields.get("isForSale") == "true", "priceInformation": {"defaultPriceInRobux": int(fields["price"])}}
                STATE["products"].append(item)
                return self.send_json(200, item)
            if re.match(r"^/universes/v1/\d+/places/\d+/versions$", path):
                if self.headers.get("Content-Type") != "application/xml":
                    return self.send_json(400, {"message": "bad content type " + str(self.headers.get("Content-Type"))})
                if b"<roblox" not in body[:200]:
                    return self.send_json(400, {"message": "not an rbxlx"})
                STATE["published"].append({"size": len(body), "versionType": self.path.split("versionType=")[-1] if "versionType=" in self.path else None, "body": body})
                return self.send_json(200, {"versionNumber": len(STATE["published"])})
            m = re.match(r"^/cloud/v2/universes/(\d+)/places/(\d+)/luau-execution-session-tasks$", path)
            if m:
                payload = json.loads(body.decode("utf-8"))
                assert "script" in payload and "print(" in payload["script"], "script manquant"
                task_path = f"universes/{m.group(1)}/places/{m.group(2)}/luau-execution-sessions/s1/tasks/t1"
                STATE["tasks"][task_path] = payload
                return self.send_json(200, {"path": task_path, "state": "QUEUED"})
        self.send_json(404, {"message": "not found " + path})

    def do_PATCH(self):
        if not self.check_auth():
            return
        path = self.path.split("?")[0]
        body = self.read_body()
        payload = json.loads(body.decode("utf-8")) if body else {}
        with LOCK:
            if re.match(r"^/cloud/v2/universes/\d+/places/\d+$", path):
                STATE["place_patches"].append({"query": self.path, "body": payload})
                return self.send_json(200, payload)
            if re.match(r"^/cloud/v2/universes/\d+$", path):
                STATE["universe_patches"].append({"query": self.path, "body": payload})
                return self.send_json(200, payload)
        self.send_json(404, {"message": "not found " + path})

    def do_DUMP(self):
        with LOCK:
            snapshot = {k: v for k, v in STATE.items() if k != "published"}
            snapshot["published"] = [{"size": p["size"], "versionType": p["versionType"], "hasIds": b"DoubleCoins = { Id = 0" not in p["body"]} for p in STATE["published"]]
        self.send_json(200, snapshot)


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"mock listening on {port}", flush=True)
    server.serve_forever()

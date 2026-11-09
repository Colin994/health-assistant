#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Export frames as PNG via Pixso MCP get_export_image. Usage: python export_frames.py <guid>:<out.png> ..."""
import base64, json, re, sys, os, urllib.request

URL = "http://127.0.0.1:3667/mcp"

def post(payload, sid=None):
    req = urllib.request.Request(URL, data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json",
                 "Accept": "application/json, text/event-stream"})
    if sid:
        req.add_header("Mcp-Session-Id", sid)
    resp = urllib.request.urlopen(req, timeout=300)
    sid_out = resp.headers.get("Mcp-Session-Id")
    raw = resp.read().decode("utf-8")
    if not raw.strip():
        return {}, sid_out
    m = re.search(r"^data: (.+)$", raw, re.M)
    body = m.group(1) if m else next((l for l in raw.splitlines() if l.lstrip().startswith("{")), raw)
    return json.loads(body), sid_out

def call_tool(name, args):
    _, sid = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
        "protocolVersion": "2024-11-05", "capabilities": {},
        "clientInfo": {"name": "zcode", "version": "1.0"}}})
    post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)
    result, _ = post({"jsonrpc": "2.0", "id": 2, "method": "tools/call",
                      "params": {"name": name, "arguments": args}}, sid)
    return result

def main():
    for spec in sys.argv[1:]:
        guid, out = spec.split("=", 1)
        res = call_tool("get_export_image", {
            "guid": guid,
            "exportSettings": {"constraint": {"type": 1, "value": 2}, "imageType": 1}})
        saved = False
        for c in res.get("result", {}).get("content", res.get("content", [])) or []:
            if c.get("type") == "image" and c.get("data"):
                open(out, "wb").write(base64.b64decode(c["data"]))
                print("saved", out, os.path.getsize(out), "bytes")
                saved = True
            elif c.get("type") == "text" and "localhost" in c.get("text", ""):
                m = re.search(r"http://\S+\.png", c["text"])
                if m:
                    urllib.request.urlretrieve(m.group(0), out)
                    print("saved", out, os.path.getsize(out), "bytes")
                    saved = True
        if not saved:
            print("NO IMAGE for", guid, "->", json.dumps(res, ensure_ascii=False)[:500])

if __name__ == "__main__":
    main()

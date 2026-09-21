#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Minimal Pixso MCP caller: init session -> tools/call -> print JSON result."""
import json, sys, re, os, urllib.request

URL = "http://127.0.0.1:3667/mcp"

def post(payload, sid=None):
    req = urllib.request.Request(URL, data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json",
                 "Accept": "application/json, text/event-stream"})
    if sid:
        req.add_header("Mcp-Session-Id", sid)
    resp = urllib.request.urlopen(req, timeout=int(os.environ.get("MCP_TIMEOUT", "300")))
    sid_out = resp.headers.get("Mcp-Session-Id")
    raw = resp.read().decode("utf-8")
    if not raw.strip():
        return {}, sid_out
    m = re.search(r"^data: (.+)$", raw, re.M)
    body = m.group(1) if m else next((l for l in raw.splitlines() if l.lstrip().startswith("{")), raw)
    return json.loads(body), sid_out

def main():
    tool = sys.argv[1]
    args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    _, sid = post({"jsonrpc":"2.0","id":1,"method":"initialize","params":{
        "protocolVersion":"2024-11-05","capabilities":{},
        "clientInfo":{"name":"zcode","version":"1.0"}}})
    post({"jsonrpc":"2.0","method":"notifications/initialized"}, sid)
    result, _ = post({"jsonrpc":"2.0","id":2,"method":"tools/call",
        "params":{"name":tool,"arguments":args}}, sid)
    out = json.dumps(result, ensure_ascii=False, indent=1)
    open("pixso_last_result.json", "w", encoding="utf-8").write(out)
    # print text content (skip huge base64 blobs)
    for c in result.get("result", {}).get("content", result.get("content", [])) or []:
        if c.get("type") == "text":
            print(c["text"][:12000])
        elif c.get("type") == "image":
            print("[image content: %d chars base64 -> pixso_image.b64]" % len(c.get("data","")))
            open("pixso_image.b64", "w").write(c.get("data",""))
    if result.get("isError"):
        print("[ERROR]", out[:2000])

if __name__ == "__main__":
    main()

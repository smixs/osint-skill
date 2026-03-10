#!/usr/bin/env python3
"""Lightweight MCP client for Streamable HTTP/SSE transport.

Usage:
    python3 mcp-client.py <mcp_url> --list-tools
    python3 mcp-client.py <mcp_url> <tool_name> '<json_args>'
"""

import json
import sys
import http.client
from urllib.parse import urlparse, urlencode


def mcp_request(url: str, method: str, params: dict | None = None, 
                req_id: int = 1, session_id: str | None = None) -> tuple[dict, str | None]:
    """Send MCP JSON-RPC request and parse SSE response. Returns (result, session_id)."""
    parsed = urlparse(url)
    
    payload = {
        "jsonrpc": "2.0",
        "id": req_id,
        "method": method,
    }
    if params:
        payload["params"] = params

    data = json.dumps(payload).encode()
    
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }
    if session_id:
        headers["Mcp-Session-Id"] = session_id
    
    conn = http.client.HTTPSConnection(parsed.hostname, timeout=120)
    path = parsed.path
    if parsed.query:
        path += "?" + parsed.query
    
    conn.request("POST", path, body=data, headers=headers)
    resp = conn.getresponse()
    
    # Get session ID from response headers
    new_session_id = resp.getheader("Mcp-Session-Id") or session_id
    
    body = resp.read().decode()
    conn.close()
    
    if resp.status >= 400:
        return {"error": f"HTTP {resp.status}: {body[:200]}"}, new_session_id
    
    # Parse SSE: look for data: lines
    for line in body.split("\n"):
        if line.startswith("data: "):
            try:
                return json.loads(line[6:]), new_session_id
            except json.JSONDecodeError:
                continue

    # Try direct JSON
    try:
        return json.loads(body), new_session_id
    except json.JSONDecodeError:
        return {"raw": body[:500]}, new_session_id


def init_and_call(url: str, method: str, params: dict | None = None) -> dict:
    """Initialize session then make a call."""
    # Step 1: Initialize
    init_result, session_id = mcp_request(url, "initialize", {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "osint-skill", "version": "3.1"},
    }, req_id=1)
    
    if "error" in init_result:
        return init_result
    
    # Step 2: Send initialized notification (optional but polite)
    # Step 3: Make actual call
    result, _ = mcp_request(url, method, params, req_id=2, session_id=session_id)
    return result


def list_tools(url: str) -> list:
    """List available tools on MCP server."""
    result = init_and_call(url, "tools/list")
    tools = result.get("result", {}).get("tools", [])
    return tools


def call_tool(url: str, tool_name: str, arguments: dict) -> dict:
    """Call a specific tool on MCP server."""
    result = init_and_call(url, "tools/call", {
        "name": tool_name,
        "arguments": arguments,
    })
    return result


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    url = sys.argv[1]

    if sys.argv[2] == "--list-tools":
        tools = list_tools(url)
        if not tools:
            print("No tools found or error occurred")
            return
        for t in tools:
            desc = t.get("description", "")[:100]
            print(f"  {t['name']}: {desc}")
        return

    tool_name = sys.argv[2]
    args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}

    result = call_tool(url, tool_name, args)

    # Extract content from MCP response
    content = result.get("result", {}).get("content", [])
    if content:
        for item in content:
            if item.get("type") == "text":
                print(item["text"])
    else:
        print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

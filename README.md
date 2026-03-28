# Delphi MCP SDK

![Preview](https://raw.githubusercontent.com/paud/DelphiMCP/main/assets/logo-social.png)
<h1 align="center">MCP SDK For Delphi</h1>
<p align="center">
A complete MCP parser and SDK implementation.
</p>
<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-D4A5A5?style=flat-square" alt="MIT License">
</p>
Model Context Protocol SDK for Delphi.

This project implements a full MCP server/client stack compatible with modern AI tools.

Features:

- JSON-RPC 2.0
- MCP protocol
- stdio transport
- HTTP transport
- tools registry
- resources
- prompts
- streaming

Compatible with:

- Claude Desktop
- Cursor
- Continue
- other MCP clients


MIT License




Project structure:
<pre style="white-space: pre-wrap; word-wrap: break-word; overflow-wrap: break-word;">

root/
│
delphi-mcp-sdk/
│
├─ README.md
├─ LICENSE
├─ CHANGELOG.md
├─ CONTRIBUTING.md
│
├─ src/
│   ├─ MCP.pas
│   ├─ MCP.Types.pas
│   ├─ MCP.JSONRPC.pas
│   ├─ MCP.Parser.pas
│   ├─ MCP.Transport.Stdio.pas
│   ├─ MCP.Transport.HTTP.pas
│   ├─ MCP.Server.pas
│   ├─ MCP.Client.pas
│   │
│   ├─ tools/
│   │   ├─ MCP.Tools.pas
│   │   └─ MCP.ToolSchema.pas
│   │
│   ├─ resources/
│   │   └─ MCP.Resources.pas
│   │
│   ├─ prompts/
│   │   └─ MCP.Prompts.pas
│   │
│   ├─ streaming/
│   │   └─ MCP.Streaming.pas
│   │
│   └─ utils/
│       ├─ MCP.JSONUtils.pas
│       └─ MCP.Log.pas
│
├─ examples/
│   ├─ echo-server/
│   │   └─ EchoServer.dpr
│   │
│   ├─ file-server/
│   │   └─ FileServer.dpr
│   │
│   └─ http-server/
│       └─ HttpMcpServer.dpr
│
├─ tests/
│   ├─ ParserTests.dpr
│   ├─ ToolTests.dpr
│   └─ JsonRpcTests.dpr
│
└─ docs/
    ├─ architecture.md
    ├─ protocol.md
    └─ examples.md

</pre>
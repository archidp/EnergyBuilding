# Ladybug Tools MCP setup

This workspace is prepared to install [LoftyTao/ladybug-tools-mcp](https://github.com/LoftyTao/ladybug-tools-mcp) into a local, untracked `.mcp/ladybug-tools-mcp` checkout and wire it into Codex.

## Install and configure Codex

Run this from the repository root:

```bash
./scripts/install_ladybug_tools_mcp.sh
```

The script will:

1. clone `https://github.com/LoftyTao/ladybug-tools-mcp.git` into `.mcp/ladybug-tools-mcp`;
2. create a Python 3.12 virtual environment with `uv`;
3. install the upstream `requirements.txt` and the MCP package in editable mode;
4. verify `import ladybug_tools_mcp`; and
5. update `~/.codex/config.toml` with a `ladybug-tools-mcp` stdio MCP server.

Restart the agent application after the script succeeds so the MCP client reloads the server list.

## Configuration snippets

- `ladybug-tools-mcp.codex.toml` is the Codex TOML server block for this workspace.
- `ladybug-tools-mcp.mcp.json` is the equivalent `mcpServers` JSON block for clients that read JSON MCP configuration.

The checked-in snippets use `/workspace/EnergyBuilding/.mcp/ladybug-tools-mcp`. If you install the server elsewhere, replace the `command` and `cwd` paths with the absolute path to your local checkout and virtual environment.

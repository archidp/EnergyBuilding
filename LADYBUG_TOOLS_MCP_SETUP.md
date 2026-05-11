# Ladybug Tools MCP setup for this workspace

This workspace is prepared to use the Ladybug Tools MCP server from
<https://github.com/LoftyTao/ladybug-tools-mcp>.

## Quick start

Run the workspace installer from any directory:

```bash
/workspace/EnergyBuilding/scripts/install_ladybug_tools_mcp.sh
```

The script resolves this repository root from its own location, so it does not
matter what your current shell directory is when you run it.

## What the installer does

The script will:

1. Check that `git`, `uv`, and Python 3.12 are available.
2. Clone `https://github.com/LoftyTao/ladybug-tools-mcp.git` into
   `tools/ladybug-tools-mcp`.
3. Create a Python 3.12 virtual environment at `tools/ladybug-tools-mcp/.venv`.
4. Install the upstream `requirements.txt` and the MCP package in editable mode
   using `uv`.
5. Verify the package import by printing `ladybug_tools_mcp.__version__`.
6. Copy the upstream `ladybug-tools-mcp-use` skill into this workspace at
   `.agents/skills/ladybug-tools-mcp-use` so agent apps that discover
   project-level skills can load the Ladybug Tools operating guidance.
7. Add a `ladybug-tools-mcp` server block to `~/.codex/config.toml`.

Restart Codex, Claude Code, Cursor, OpenCode, or any other MCP-capable agent
after installation so the MCP client reloads its server list and project skills.

## First use

After restarting the agent application:

1. Invoke the project skill with `/ladybug-tools-mcp-use` if your agent app
   requires explicit skill activation.
2. Say `Hi, Ladybug Tools!` to start the Ladybug Tools onboarding flow.
   The upstream skill also treats close variants, including `Hi,Ladybug Tools!`
   and host-specific mentions such as `@ladybug-tools-mcp Hi,Ladybug Tools!`,
   as a broad English start once the MCP server and project skill are loaded.
3. Choose one of the top-level directions that the onboarding flow offers.
4. Select an existing Garden or create a new Garden before asking the agent to
   model, prepare resources, or collaborate with Rhino / Grasshopper.

## Configuration files included here

- `.mcp.json` provides an `mcpServers` configuration for MCP clients that read
  workspace JSON configuration.
- `mcp/ladybug-tools-mcp.codex.toml` provides the Codex TOML server block for
  manual installation or review.
- `scripts/install_ladybug_tools_mcp.sh` performs the clone, Python setup,
  project skill setup, and Codex configuration update.

## Customization

You can override the default locations and commands with environment variables:

```bash
LADYBUG_TOOLS_MCP_DIR=/absolute/path/to/ladybug-tools-mcp \
PYTHON_BIN=python3.12 \
CODEX_CONFIG="$HOME/.codex/config.toml" \
PROJECT_SKILLS_DIR=/absolute/path/to/.agents/skills \
scripts/install_ladybug_tools_mcp.sh
```

## Notes

The upstream project currently documents Python 3.12, Git, `uv`, Ladybug Tools
1.10-series packages, and an MCP-capable agent as prerequisites. The MCP server
is started with:

```bash
/workspace/EnergyBuilding/tools/ladybug-tools-mcp/.venv/bin/python -m ladybug_tools_mcp.server
```

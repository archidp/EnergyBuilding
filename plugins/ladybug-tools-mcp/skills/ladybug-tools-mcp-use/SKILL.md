---
name: ladybug-tools-mcp-use
description: Use when the user invokes Ladybug Tools MCP, says "Hi, Ladybug Tools!", or asks for Ladybug/Honeybee modeling, simulation, visualization, Garden setup, EPW/weather workflows, or Flowerpot collaboration through this workspace MCP server.
---

# Ladybug Tools MCP workspace guide

When this skill is active, first verify that the Ladybug Tools MCP server is installed and connected. If the MCP server is not available, tell the user to run:

```bash
/workspace/EnergyBuilding/scripts/install_ladybug_tools_mcp.sh
```

After installation, restart the agent application and invoke the plugin as `@Ladybug Tools MCP` or say `Hi, Ladybug Tools!`.

## Operating flow

1. Start by helping the user choose or create a Garden directory for generated Ladybug Tools MCP work.
2. Keep model, weather, simulation, visualization, and collaboration artifacts inside the selected Garden.
3. Use MCP tools for Ladybug/Honeybee modeling and simulation once the server is connected.
4. If the user mentions Grasshopper, Rhino, or Flowerpot, ask what context or files they want to exchange before creating or editing artifacts.
5. Summarize created files and next manual steps after each workflow.

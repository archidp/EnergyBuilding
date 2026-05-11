#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_URL="${LADYBUG_TOOLS_MCP_REPO_URL:-https://github.com/LoftyTao/ladybug-tools-mcp.git}"
INSTALL_DIR="${LADYBUG_TOOLS_MCP_DIR:-$WORKSPACE_DIR/tools/ladybug-tools-mcp}"
PYTHON_BIN="${PYTHON_BIN:-python3.12}"
CODEX_CONFIG="${CODEX_CONFIG:-$HOME/.codex/config.toml}"
PROJECT_SKILLS_DIR="${PROJECT_SKILLS_DIR:-$WORKSPACE_DIR/.agents/skills}"
SKILL_NAME="ladybug-tools-mcp-use"
REGISTER_CODEX_MARKETPLACE="${REGISTER_CODEX_MARKETPLACE:-auto}"
REGISTER_CLAUDE_MCP="${REGISTER_CLAUDE_MCP:-auto}"

require_command() {
  local command_name="$1"
  local install_hint="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    echo "$install_hint" >&2
    exit 1
  fi
}

require_command git "Install Git, then rerun this script."
require_command uv "Install uv first: https://docs.astral.sh/uv/getting-started/installation/"
require_command "$PYTHON_BIN" "Install Python 3.12 or set PYTHON_BIN to a compatible Python executable."

register_codex_marketplace() {
  local mode
  mode="$(printf '%s' "$REGISTER_CODEX_MARKETPLACE" | tr '[:upper:]' '[:lower:]')"

  case "$mode" in
    0|false|no|never)
      echo "Skipping Codex plugin marketplace registration."
      return 0
      ;;
    auto)
      if ! command -v codex >/dev/null 2>&1; then
        echo "Codex CLI not found; skipping automatic plugin marketplace registration." >&2
        echo "To register later, run: codex plugin marketplace add $WORKSPACE_DIR" >&2
        return 0
      fi
      ;;
    1|true|yes|always)
      require_command codex "Install the Codex CLI or set REGISTER_CODEX_MARKETPLACE=auto/no."
      ;;
    *)
      echo "Unsupported REGISTER_CODEX_MARKETPLACE value: $REGISTER_CODEX_MARKETPLACE" >&2
      echo "Use auto, yes, or no." >&2
      exit 1
      ;;
  esac

  codex plugin marketplace add "$WORKSPACE_DIR" || {
    echo "Warning: Codex plugin marketplace registration failed." >&2
    echo "You can retry manually with: codex plugin marketplace add $WORKSPACE_DIR" >&2
    return 0
  }
  echo "Registered Codex plugin marketplace: $WORKSPACE_DIR"
}

register_claude_mcp() {
  local mode
  local python_command
  mode="$(printf '%s' "$REGISTER_CLAUDE_MCP" | tr '[:upper:]' '[:lower:]')"
  python_command="$INSTALL_DIR/.venv/bin/python"

  case "$mode" in
    0|false|no|never)
      echo "Skipping Claude MCP registration."
      return 0
      ;;
    auto)
      if ! command -v claude >/dev/null 2>&1; then
        echo "Claude CLI not found; skipping automatic Claude MCP registration." >&2
        echo "To register later, run: claude mcp add ladybug-tools-mcp -- $python_command -m ladybug_tools_mcp.server" >&2
        return 0
      fi
      ;;
    1|true|yes|always)
      require_command claude "Install the Claude CLI or set REGISTER_CLAUDE_MCP=auto/no."
      ;;
    *)
      echo "Unsupported REGISTER_CLAUDE_MCP value: $REGISTER_CLAUDE_MCP" >&2
      echo "Use auto, yes, or no." >&2
      exit 1
      ;;
  esac

  claude mcp add ladybug-tools-mcp -- "$python_command" -m ladybug_tools_mcp.server || {
    echo "Warning: Claude MCP registration failed." >&2
    echo "You can retry manually with: claude mcp add ladybug-tools-mcp -- $python_command -m ladybug_tools_mcp.server" >&2
    return 0
  }
  echo "Registered Claude MCP server: ladybug-tools-mcp"
}

mkdir -p "$(dirname "$INSTALL_DIR")"

if [ ! -d "$INSTALL_DIR/.git" ]; then
  if [ -e "$INSTALL_DIR" ]; then
    echo "Install directory exists but is not a Git checkout: $INSTALL_DIR" >&2
    exit 1
  fi
  git clone "$REPO_URL" "$INSTALL_DIR"
else
  git -C "$INSTALL_DIR" pull --ff-only
fi

cd "$INSTALL_DIR"
uv venv --python "$PYTHON_BIN" .venv
uv pip install -r requirements.txt
uv pip install -e .
uv run python -c 'import ladybug_tools_mcp; print(ladybug_tools_mcp.__version__)'

UPSTREAM_SKILL_DIR="$INSTALL_DIR/.agents/skills/$SKILL_NAME"
PROJECT_SKILL_DIR="$PROJECT_SKILLS_DIR/$SKILL_NAME"
if [ -d "$UPSTREAM_SKILL_DIR" ]; then
  mkdir -p "$PROJECT_SKILLS_DIR"
  rm -rf "$PROJECT_SKILL_DIR"
  cp -R "$UPSTREAM_SKILL_DIR" "$PROJECT_SKILL_DIR"
  echo "Installed project skill: $PROJECT_SKILL_DIR"
else
  echo "Warning: upstream skill was not found at $UPSTREAM_SKILL_DIR" >&2
fi

mkdir -p "$(dirname "$CODEX_CONFIG")"
python - "$CODEX_CONFIG" "$INSTALL_DIR" <<'PY'
from pathlib import Path
import sys

config_path = Path(sys.argv[1]).expanduser()
install_dir = Path(sys.argv[2]).resolve()
python_command = install_dir / ".venv" / "bin" / "python"
block_header = "[mcp_servers.ladybug-tools-mcp]"
block = "\n".join(
    [
        block_header,
        f'command = "{python_command}"',
        'args = ["-m", "ladybug_tools_mcp.server"]',
        f'cwd = "{install_dir}"',
        "",
    ]
)

existing = config_path.read_text() if config_path.exists() else ""
lines = existing.splitlines()
out = []
skip = False
for line in lines:
    stripped = line.strip()
    if stripped == block_header:
        skip = True
        continue
    if skip and stripped.startswith("[") and stripped.endswith("]"):
        skip = False
    if not skip:
        out.append(line)

text = "\n".join(out).rstrip()
if text:
    text += "\n\n"
text += block
config_path.write_text(text)
print(f"Wrote Codex MCP configuration to {config_path}")
PY

register_codex_marketplace
register_claude_mcp

cat <<EOF2

Ladybug Tools MCP is installed at:
  $INSTALL_DIR

Codex MCP configuration was written to:
  $CODEX_CONFIG

Project skill directory:
  $PROJECT_SKILL_DIR

Restart the agent application so it reloads MCP servers, skills, and plugins.
After restart, invoke @Ladybug Tools MCP or /$SKILL_NAME and say: Hi, Ladybug Tools!
EOF2

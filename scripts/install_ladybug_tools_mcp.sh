#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${LADYBUG_TOOLS_MCP_REPO_URL:-https://github.com/LoftyTao/ladybug-tools-mcp.git}"
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${LADYBUG_TOOLS_MCP_DIR:-${WORKSPACE_ROOT}/.mcp/ladybug-tools-mcp}"
PYTHON_VERSION="${LADYBUG_TOOLS_MCP_PYTHON_VERSION:-3.12}"
CODEX_CONFIG="${CODEX_CONFIG:-${HOME}/.codex/config.toml}"

command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
command -v uv >/dev/null || { echo "uv is required; install it from https://astral.sh/uv" >&2; exit 1; }

mkdir -p "$(dirname "${INSTALL_DIR}")"
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  git -C "${INSTALL_DIR}" fetch --depth 1 origin main
  git -C "${INSTALL_DIR}" checkout main
  git -C "${INSTALL_DIR}" reset --hard origin/main
else
  rm -rf "${INSTALL_DIR}"
  git clone --depth 1 "${REPO_URL}" "${INSTALL_DIR}"
fi

uv venv --python "${PYTHON_VERSION}" "${INSTALL_DIR}/.venv"
uv pip --python "${INSTALL_DIR}/.venv/bin/python" install -r "${INSTALL_DIR}/requirements.txt"
uv pip --python "${INSTALL_DIR}/.venv/bin/python" install -e "${INSTALL_DIR}"
"${INSTALL_DIR}/.venv/bin/python" -c 'import ladybug_tools_mcp; print(ladybug_tools_mcp.__version__)'

mkdir -p "$(dirname "${CODEX_CONFIG}")"
python3 - "${CODEX_CONFIG}" "${INSTALL_DIR}" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1]).expanduser()
install_dir = Path(sys.argv[2]).resolve()
python_command = install_dir / ".venv" / "bin" / "python"
block = f'''[mcp_servers.ladybug-tools-mcp]
command = "{python_command}"
args = ["-m", "ladybug_tools_mcp.server"]
cwd = "{install_dir}"
'''
text = config_path.read_text() if config_path.exists() else ""
pattern = re.compile(r'(?ms)^\[mcp_servers\.ladybug-tools-mcp\]\n.*?(?=^\[|\Z)')
if pattern.search(text):
    text = pattern.sub(block.rstrip() + "\n", text)
else:
    if text and not text.endswith("\n"):
        text += "\n"
    if text:
        text += "\n"
    text += block
config_path.write_text(text)
PY

echo "Ladybug Tools MCP installed at: ${INSTALL_DIR}"
echo "Codex MCP config updated at: ${CODEX_CONFIG}"
echo "Restart your agent application before using ladybug-tools-mcp."

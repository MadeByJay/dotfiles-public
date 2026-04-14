#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "dotfiles: installing from $DOTFILES"

# ── Helper ────────────────────────────────────────────────────────────────────
link() {
    local rel="$1"
    local src="$DOTFILES/$rel"
    local dst="$HOME/$rel"
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "  linked ~/$rel"
}

# ── Shell ─────────────────────────────────────────────────────────────────────
if [ -f /.dockerenv ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${CODESPACES:-}" ]; then
    ln -sf "$DOTFILES/.zshrc-container" "$HOME/.zshrc"
    echo "  linked .zshrc-container → ~/.zshrc (container)"
else
    link .zshrc
fi

# ── ZSH config ────────────────────────────────────────────────────────────────
link .config/zsh/aliases.zsh
link .config/zsh/env.zsh
link .config/zsh/history.zsh

# ── Prompt ────────────────────────────────────────────────────────────────────
link .config/starship.toml

# ── Editor ────────────────────────────────────────────────────────────────────
link .config/nvim/init.lua
link .config/nvim/lua/config/autocmds.lua
link .config/nvim/lua/config/keymaps.lua
link .config/nvim/lua/config/lazy.lua
link .config/nvim/lua/config/options.lua
link .config/nvim/lua/plugins/example.lua
link .config/nvim/lua/plugins/lang.lua
link .config/nvim/lua/plugins/tools.lua

# ── Codegraph (MCP for Claude Code) ──────────────────────────────────────────
if command -v npm &>/dev/null; then
    echo "  installing codegraph..."
    npm install -g @colbymchenry/codegraph

    # Wire up MCP server in ~/.claude.json
    if command -v python3 &>/dev/null; then
        python3 - <<'EOF'
import json, os, sys

claude_json = os.path.expanduser("~/.claude.json")
config = {}
if os.path.exists(claude_json):
    with open(claude_json) as f:
        config = json.load(f)

config.setdefault("mcpServers", {})["codegraph"] = {
    "type": "stdio",
    "command": "codegraph",
    "args": ["serve", "--mcp"]
}

with open(claude_json, "w") as f:
    json.dump(config, f, indent=2)

print("  wired codegraph MCP → ~/.claude.json")
EOF
    fi
else
    echo "  npm not found — skipping codegraph install"
fi

echo "dotfiles: done"

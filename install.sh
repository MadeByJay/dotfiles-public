#!/usr/bin/env bash
set -eo pipefail
trap 'echo "dotfiles: FAILED at line $LINENO (exit $?)" >&2' ERR

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
    # Container: inject into existing ~/.bashrc (idempotent)
    MARKER="# dotfiles: container config"
    if ! grep -qF "$MARKER" "$HOME/.bashrc" 2>/dev/null; then
        printf '\n%s\n[ -f "%s/.bashrc-container" ] && source "%s/.bashrc-container"\n' \
            "$MARKER" "$DOTFILES" "$DOTFILES" >> "$HOME/.bashrc"
    fi
    echo "  sourcing .bashrc-container from ~/.bashrc"
else
    link .zshrc
    # ── ZSH config ──────────────────────────────────────────────────────────
    link .config/zsh/aliases.zsh
    link .config/zsh/env.zsh
    link .config/zsh/history.zsh
fi

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
    # Use user-local npm prefix so no sudo needed and binaries are on PATH
    npm config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"

    echo "  installing codegraph..."
    npm install -g @colbymchenry/codegraph

    # Wire up MCP servers in ~/.claude.json
    if command -v python3 &>/dev/null; then
        python3 - <<'EOF'
import json, os

claude_json = os.path.expanduser("~/.claude.json")
config = {}
if os.path.exists(claude_json):
    with open(claude_json) as f:
        config = json.load(f)

mcp = config.setdefault("mcpServers", {})

mcp["codegraph"] = {
    "type": "stdio",
    "command": "codegraph",
    "args": ["serve", "--mcp"]
}

mcp["playwright"] = {
    "type": "stdio",
    "command": "npx",
    "args": ["@playwright/mcp@latest", "--no-sandbox"]
}

with open(claude_json, "w") as f:
    json.dump(config, f, indent=2)

print("  wired codegraph + playwright MCP → ~/.claude.json")
EOF
    fi
else
    echo "  npm not found — skipping codegraph install"
fi

echo "dotfiles: done"

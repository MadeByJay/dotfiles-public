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
        printf '
%s
[ -f "%s/.bashrc-container" ] && source "%s/.bashrc-container"
' \
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

# ── Starship (install if missing) ─────────────────────────────────────────────
if ! command -v starship &>/dev/null; then
    echo "  installing starship..."
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
else
    echo "  starship already installed"
fi

# ── GitHub CLI ────────────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
    echo "  installing gh CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt-get update -qq && apt-get install -y gh
else
    echo "  gh already installed"
fi

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

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
        | sudo -n dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo -n chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo -n tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo -n apt-get update -qq && sudo -n apt-get install -y gh
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

# ── Neovim (install if missing) ──────────────────────────────────────────────
if ! command -v nvim &>/dev/null; then
    echo "  installing neovim..."
    NVIM_VERSION="v0.10.4"
    NVIM_PREFIX="$HOME/.local/share/nvim-bin"
    mkdir -p "$NVIM_PREFIX" "$HOME/.local/bin"
    curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz" \
        | tar xz -C "$NVIM_PREFIX" --strip-components=1
    ln -sf "$NVIM_PREFIX/bin/nvim" "$HOME/.local/bin/nvim"
    echo "  installed nvim to $HOME/.local/bin/nvim"
else
    echo "  nvim already installed: $(nvim --version | head -1)"
fi

# ── LazyVim bootstrap ────────────────────────────────────────────────────────
# Headless plugin sync — installs lazy.nvim and all plugins on first run.
# Non-fatal if it fails so container setup completes.
if command -v nvim &>/dev/null; then
    echo "  bootstrapping lazyvim plugins..."
    nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5 || echo "  lazyvim bootstrap had issues (non-fatal)"
else
    echo "  nvim not found — skipping lazyvim bootstrap"
fi

# ── Codegraph (MCP for Claude Code) ──────────────────────────────────────────
if command -v npm &>/dev/null; then
    npm config set prefix "$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"

    echo "  installing codegraph..."
    npm install -g @colbymchenry/codegraph

    if command -v python3 &>/dev/null; then
        python3 - <<'PYEOF'
import json, os

claude_json = os.path.expanduser("~/.claude.json")
config = {}
if os.path.exists(claude_json):
    with open(claude_json) as f:
        config = json.load(f)

mcp = config.setdefault("mcpServers", {})
mcp["codegraph"] = {"type": "stdio", "command": "codegraph", "args": ["serve", "--mcp"]}
mcp["playwright"] = {"type": "stdio", "command": "npx", "args": ["@playwright/mcp@latest", "--no-sandbox"]}

with open(claude_json, "w") as f:
    json.dump(config, f, indent=2)

print("  wired codegraph + playwright MCP -> ~/.claude.json")
PYEOF
    fi
else
    echo "  npm not found — skipping codegraph install"
fi

echo "dotfiles: done"

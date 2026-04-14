alias ll='ls -lhF --color=auto'
alias la='ls -lAhF --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias zshrc='$EDITOR ~/.zshrc'
alias reload='source ~/.zshrc'

# Better defaults
alias cat='bat --paging=never'
alias find='fd'
alias lg='lazygit'
alias diff='diff --color=auto'

# Git shortcuts
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

# Docker shortcuts
alias dps='docker ps'
alias dcp='docker compose'
alias dcup='docker compose up -d'
alias dcdn='docker compose down'

# Neovim
alias v='nvim'
alias vh='nvim .'

# npm
alias nr='npm run'

# fzf
alias f='fzf'

# Navigation
alias repos='cd ~/repos'

# Misc
alias ports='ss -tulanp'
alias myip='curl -s ifconfig.me'

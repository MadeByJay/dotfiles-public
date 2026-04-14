# Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

export EDITOR="nvim"
export VISUAL="nvim"
export LANG="en_US.UTF-8"
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

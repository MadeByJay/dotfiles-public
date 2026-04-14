HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"

setopt HIST_IGNORE_DUPS       # Don't record duplicate consecutive commands
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate entries from history
setopt HIST_FIND_NO_DUPS      # Don't show duplicates when searching
setopt HIST_IGNORE_SPACE      # Don't record commands prefixed with a space
setopt SHARE_HISTORY          # Share history across all open terminal sessions
setopt APPEND_HISTORY         # Append rather than overwrite history file

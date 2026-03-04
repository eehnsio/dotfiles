# Fix TERM for remote machines that don't recognize ghostty
if [[ "$TERM" == "xterm-ghostty" ]] && [[ -n "$SSH_CONNECTION" ]]; then
  export TERM=xterm-256color
fi

# Node.js 24 (Homebrew keg-only)
export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

# License: MIT Enable color support of ls
if ls --color=auto &>/dev/null; then
	alias ls='ls -p --color=auto'
else
	alias ls='ls -p -G'
fi

# Aliases
#alias ..='echo "cd .."; cd ..'
alias ..='cd ..;pwd'
alias tree='tree --dirsfirst -F'

# Calendar
alias jan='cal -m 01'
alias feb='cal -m 02'
alias mar='cal -m 03'
alias apr='cal -m 04'
alias may='cal -m 05'
alias jun='cal -m 06'
alias jul='cal -m 07'
alias aug='cal -m 08'
alias sep='cal -m 09'
alias oct='cal -m 10'
alias nov='cal -m 11'
alias dec='cal -m 12'
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/Users/erik/.bun/_bun" ] && source "/Users/erik/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export POSTHOG_MCP_URL="https://mcp-eu.posthog.com/mcp"

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"

# Privata alias och config (ej versionshanterad)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

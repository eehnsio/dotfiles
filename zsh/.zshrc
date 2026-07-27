# Node.js 24 (Homebrew keg-only) — macOS only
[[ -d "/opt/homebrew/opt/node@24/bin" ]] && export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

# lsd aliases
alias ls='lsd'
alias ll='lsd -la'
alias la='lsd -a'
alias lt='lsd --tree'

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
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export POSTHOG_MCP_URL="https://mcp-eu.posthog.com/mcp"

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Prompt: starship, Pure-stil (config: starship-paketet → ~/.config/starship.toml)
eval "$(starship init zsh)"

# Deja — historik-autocomplete (daemonen auto-spawnas vid första prompten)
if command -v deja &> /dev/null; then
  eval "$(deja init zsh)"
fi

# Privata alias och config (ej versionshanterad)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

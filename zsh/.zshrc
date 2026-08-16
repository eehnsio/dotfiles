# Node.js 24 (Homebrew keg-only) — macOS only
[[ -d "/opt/homebrew/opt/node@24/bin" ]] && export PATH="/opt/homebrew/opt/node@24/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

export POSTHOG_MCP_URL="https://mcp-eu.posthog.com/mcp"

# ── Historik ────────────────────────────────────────────────────────────
# Utan de här sparas ingen historik alls mellan sessioner (zsh:s default).
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY       # spara tidsstämpel per kommando
setopt SHARE_HISTORY          # nya kommandon syns direkt i andra öppna terminaler
setopt HIST_IGNORE_ALL_DUPS   # en upprepning ersätter den gamla raden
setopt HIST_IGNORE_SPACE      # rader som börjar med mellanslag hamnar inte i historiken
setopt HIST_VERIFY            # !! expanderas till raden istället för att köras direkt

# ── Completion ──────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select                     # pila runt i träfflistan
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # skiftlägesokänsligt

# ── Tangenter ───────────────────────────────────────────────────────────
bindkey -e                    # emacs-bindningar (ctrl+a, ctrl+e, ctrl+r …)

# ↑/↓ söker i historiken på det du redan hunnit skriva
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Hoppa ord med alt+pil (macOS-vana). Emacs-lagets ^[b och ^[f gor redan detta,
# men terminalen skickar CSI-sekvenser for alt+pil som zsh inte binder sjalv.
# Ctrl+pil med, eftersom niri bara tar Mod+Ctrl+pil och lamnar Ctrl+pil ifred.
bindkey '^[[1;3D' backward-word   # alt+vanster
bindkey '^[[1;3C' forward-word    # alt+hoger
bindkey '^[[1;5D' backward-word   # ctrl+vanster
bindkey '^[[1;5C' forward-word    # ctrl+hoger

# ── Prompt ──────────────────────────────────────────────────────────────
# Pure-stil i ren zsh: grön hostname, cyan katalog, lila ❯ som blir röd vid felkod.
# %m = hostname · %(4~|…/%3~|%~) = full path upp till 3 nivåer, annars …/tre-sista
_prompt_user=''
[[ -n $SSH_CONNECTION || $EUID -eq 0 ]] && _prompt_user='%B%F{green}%n%f%b@'
PROMPT="${_prompt_user}%B%F{green}%m%f%b %B%F{cyan}%(4~|…/%3~|%~)%f%b %(?.%F{magenta}.%F{red})%B❯%b%f "
unset _prompt_user

# ── Alias ───────────────────────────────────────────────────────────────
alias ls='lsd'
alias ll='lsd -la'
alias la='lsd -a'
# Djupbegransat med flit: ett obegransat trad i ett repo med node_modules
# scrollar forbi i evigheter. Djupare vid behov: lsd --tree --depth 4
alias lt='lsd --tree --depth 2'

# fastfetch delat i tva vyer: standard visar miljon man sitter i, hardware
# visar specarna. Configarna ligger i ~/.config/fastfetch/.
alias ffhw='fastfetch --config hardware'

alias ..='cd ..;pwd'
alias tree='tree --dirsfirst -F'

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

# ── Verktyg ─────────────────────────────────────────────────────────────
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# fzf: ctrl+r fuzzy-historik, ctrl+t filväljare, alt+c cd. Sökvägarna skiljer
# sig mellan Arch (/usr/share/fzf) och Homebrew (fzf --zsh).
if [[ -d /usr/share/fzf ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
elif command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi

# Privata alias och config (ej versionshanterad)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

#!/usr/bin/env bash
# ============================================================
# bootstrap.sh — från ingenting till länkade dotfiles, på vilken maskin
# som helst.
#
#   curl -fsSL https://raw.githubusercontent.com/eehnsio/dotfiles/main/bootstrap.sh | bash
#
# Skriptet är med flit dumt och har noll val: git, stow, klona, länka. Vill
# du bara en delmängd, sätt STOW_FOLDERS och kör ./install själv.
#
# Stödda mål: macOS arm64/x64, Linux amd64/arm64/armv7 (Pi 2B och uppåt).
# ============================================================
set -euo pipefail

REPO_URL="https://github.com/eehnsio/dotfiles.git"
DOTFILES="${DOTFILES:-$HOME/Developer/dotfiles}"
BINDIR="$HOME/.local/bin"

say()  { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

# ── 1. Ta reda på var vi står ────────────────────────────────────────────
uname_s="$(uname -s)"
uname_m="$(uname -m)"
case "$uname_s" in
    Darwin) os=darwin ;;
    Linux)  os=linux ;;
    *)      die "stöds inte: $uname_s" ;;
esac
case "$uname_m" in
    arm64|aarch64) arch=arm64 ;;
    x86_64|amd64)  arch=amd64 ;;
    armv7l|armv6l) arch=armv7 ;;
    *)             die "okänd arkitektur: $uname_m" ;;
esac
say "$os/$arch"

# ── 2. git — allt annat hänger på att repot går att hämta ────────────────
if ! command -v git >/dev/null 2>&1; then
    if [[ "$os" == darwin ]]; then
        say "installerar Xcode Command Line Tools (ger git) …"
        xcode-select --install 2>/dev/null || true
        # xcode-select returnerar direkt medan installationen kör i ett
        # eget fönster — vänta in den istället för att falla på nästa rad.
        until command -v git >/dev/null 2>&1; do
            printf '\r    väntar på att installationen ska bli klar …'
            sleep 5
        done
        printf '\n'
    else
        say "installerar git …"
        sudo apt-get update -qq && sudo apt-get install -y git
    fi
fi

# ── 3. Repot ─────────────────────────────────────────────────────────────
if [[ -d "$DOTFILES/.git" ]]; then
    say "repot finns, hämtar senaste …"
    git -C "$DOTFILES" pull --ff-only || warn "kunde inte pulla — fortsätter med det som finns"
else
    say "klonar dotfiles → $DOTFILES"
    mkdir -p "$(dirname "$DOTFILES")"
    git clone --depth 1 "$REPO_URL" "$DOTFILES"
fi

# ── 4. GNU Stow — det är den som gör själva länkandet ────────────────────
if ! command -v stow >/dev/null 2>&1; then
    say "installerar GNU Stow …"
    if [[ "$os" == darwin ]]; then
        command -v brew >/dev/null 2>&1 \
            || die "brew saknas — installera det först: https://brew.sh"
        brew install stow
    else
        sudo apt-get update -qq && sudo apt-get install -y stow
    fi
fi

# ── 5. PATH ──────────────────────────────────────────────────────────────
# zsh/.zshrc lägger själv till ~/.local/bin, men på en maskin där dotfiles
# ännu inte är stowade finns den raden inte — påminn istället för att
# redigera en fil användaren inte valt att installera än.
case ":$PATH:" in
    *":$BINDIR:"*) ;;
    *) warn "$BINDIR ligger inte på PATH — lägg till:"
       printf '      export PATH="%s:$PATH"\n' "$BINDIR" ;;
esac

# ── 6. Överlämning ───────────────────────────────────────────────────────
# Bootstrap gör bara det som är obligatoriskt oavsett maskin. Vilka paket
# som ska länkas är ett val, och val smyger inte förbi — särskilt inte på en
# maskin där hälften av paketen är fel (tmux på en burk utan multiplexer).
say "klart — repot ligger i $DOTFILES"
printf '\n    cd %s\n' "$DOTFILES"
printf '    ./install                        # allt\n'
printf '    STOW_FOLDERS="nvim,zsh" ./install  # en delmängd\n\n'

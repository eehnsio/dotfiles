# Dotfiles

Personal configuration files for development environment setup.

> **Note:** These configurations are optimized for macOS and may require adjustments for other operating systems.

## What's Included

- **claude** - Claude Code CLI settings, skills, and commands
- **ghostty** - Terminal emulator configuration
- **nvim** - Neovim editor with plugins and themes
- **starship** - Prompt (Pure-style: cyan dir + magenta `❯`, red on error)
- **zsh** - Shell configuration and aliases

## Installation

Uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink management.

### Prerequisites

Install GNU Stow:

```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow

# Arch Linux
sudo pacman -S stow
```

### Quick Setup

```bash
git clone <repo-url> ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install
```

The install script will automatically stow all configurations to your home directory.

### Selective Installation

Install only specific packages:

```bash
STOW_FOLDERS="nvim,zsh" ./install
```

## Structure

Each directory represents a package that can be independently stowed:

```
.dotfiles/
├── claude/           # Claude Code CLI
├── ghostty/          # Terminal emulator
├── nvim/             # Neovim editor
├── starship/         # Prompt (config → ~/.config/starship.toml)
└── zsh/              # Shell
```

## Shell Extras (installed via Homebrew, wired up in `zsh/.zshrc`)

| Tool | Install | Purpose |
|------|---------|---------|
| [starship](https://starship.rs) | `brew install starship` | Prompt — config in the `starship` package |
| [deja](https://github.com/Giammarco-ferranti/deja) | `brew install Giammarco-Ferranti/deja/deja` | History autocomplete (ghost text); daemon auto-spawns. Bootstrap history on a new machine: `deja import` |

Both are guarded/initialized at the end of `zsh/.zshrc`. Prompt colors map to the
terminal's ANSI palette — the exact look depends on the active Ghostty theme.

## How It Works

- **Stow creates symlinks** from this repo to your home directory
- **Edit files here** in the dotfiles directory, not in `~/.config`
- **Re-run `./install`** to update symlinks after pulling changes
- **Conflicts?** The script automatically removes old symlinks before creating new ones

## Claude Code

Marketplace plugins are declared in `claude/.claude/settings.json` and installed automatically by Claude Code — no local copies needed.

Custom skills live in `claude/.claude/skills/`. Private or company-internal skills use the `-private` suffix (e.g. `my-skill-private/`) and are excluded from git via a wildcard pattern in `.gitignore`.

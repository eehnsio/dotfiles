# Dotfiles

Personal configuration files for development environment setup.

> **Note:** These configurations are optimized for macOS and may require adjustments for other operating systems.

## What's Included

- **ghostty** - Terminal emulator configuration
- **nvim** - Neovim editor with plugins and themes
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
├── ghostty/          # Terminal emulator
├── nvim/             # Neovim editor
└── zsh/              # Shell
```

## How It Works

- **Stow creates symlinks** from this repo to your home directory
- **Edit files here** in the dotfiles directory, not in `~/.config`
- **Re-run `./install`** to update symlinks after pulling changes
- **Conflicts?** The script automatically removes old symlinks before creating new ones

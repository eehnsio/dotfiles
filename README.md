# dotfiles

Collection of my configs and settings for some applications

# Structure

Each directory represents a package that can be independently stowed:

```
.dotfiles/
├── ghostty/          # Terminal emulator
├── nvim/             # Neovim editor
├── zsh/              # zsh shell
```

# Setup

## Prerequisites

Install GNU Stow:

```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow

# Arch Linux
sudo pacman -S stow
```

## Initial Setup

1. Clone this repository to your preferred location:
```bash
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
```

2. Stow the configurations you want:
```bash
# Stow individual packages
stow ghostty
stow nvim
stow zsh

# Or stow everything at once
stow */
```

# Usage

## Stowing Configurations

Each folder can be stowed using:

```bash
stow <folder> --target=$HOME -v
```

The `--target=$HOME` is optional (it's the default), and `-v` enables verbose output.

## Working with Configuration Updates

When you make changes to configuration files:

1. **Edit files directly** in this dotfiles directory (not in your home directory)
2. **Re-stow** to update symlinks:
```bash
stow <folder>
```

3. **No need to unstow first** - stow will update existing symlinks

## Managing Conflicts

If you encounter conflicts during stowing:

```bash
# Remove conflicting files manually, then stow
rm ~/.config/conflicting-file
stow <folder>

# Or use --adopt to move existing files into the stow directory
stow --adopt <folder>
```

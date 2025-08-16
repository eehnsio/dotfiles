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

# Stow

I use GNU Stow to handle the files - Each folder can be stowed using:

```
stow <folder> --target=$HOME -v
```

# zsh

Shell config: prompt, history, completion, aliases.

The prompt is plain zsh, no external tool. Pure-style: green host, cyan path,
magenta `❯` that turns red on error, and `user@host` over SSH. Colours map to the
terminal's ANSI palette, so the exact look follows the active Ghostty theme.

`.zshrc.local` is gitignored and sourced if present.

## Extras

Wired up here, each guarded with `command -v` so a missing tool degrades quietly
instead of erroring on shell start.

| Tool | Install (Arch / macOS) | Purpose |
|------|------------------------|---------|
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `pacman -S zoxide` / `brew install zoxide` | Smarter `cd` — jump to frecent dirs by fragment |
| [fzf](https://github.com/junegunn/fzf) | `pacman -S fzf` / `brew install fzf` | Fuzzy `ctrl+r` history, `ctrl+t` files, `alt+c` cd |
| [lsd](https://github.com/lsd-rs/lsd) | `pacman -S lsd` / `brew install lsd` | `ls`/`ll`/`la`/`lt` aliases |
| [deja](https://github.com/Giammarco-Ferranti/deja) | [curl installer](https://github.com/Giammarco-Ferranti/deja#curl-any-linuxmacos-no-homebrew-required) / `brew install Giammarco-Ferranti/deja/deja` | Inline ghost-text suggestions from history (`→` accepts, `ctrl+n` cycles alternatives) |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | `pacman -S zsh-syntax-highlighting` / `brew install zsh-syntax-highlighting` | Colours commands as you type, red when not found |

Word jumping is bound for both `alt+arrow` and `ctrl+arrow`.

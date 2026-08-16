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

Word jumping is bound for both `alt+arrow` and `ctrl+arrow`.

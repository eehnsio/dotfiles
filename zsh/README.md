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

## bwc

`bw`, the official Bitwarden CLI, pointed at **cloud Bitwarden** — beside
`vw-run`/`vw-render` from the homelab repo, which run `bw` against Vaultwarden.
`BITWARDENCLI_APPDATA_DIR=~/.config/bw-cloud` gives it its own server, login and
cache, so the two never share a session. One shell can use both in turn; two
shells can sit in one vault each.

```bash
bwc login --apikey   # once per machine — client_id/secret from the web vault
bwc unlock           # master password; the session then lives in this shell
bwc list items --search github
bwc lock
```

The unlocked session is an **unexported** shell variable: it dies with the
shell and is never written anywhere. Vaultwarden's session sits in tmpfs until
reboot, but the cloud vault holds everything, break-glass included, so it gets
the stricter rule.

`bw` itself comes from Bitwarden's release zip, not a package — Arch's
`bitwarden-cli` pulls in Node 22 and evicts a newer Node. Same version as the
rest of the fleet, which is pinned to what has been tested against Vaultwarden.

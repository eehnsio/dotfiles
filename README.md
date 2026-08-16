# Dotfiles

![Drivis](.github/assets/drivis.png)

Personal configuration for Arch Linux with niri, and macOS. Managed with
[GNU Stow](https://www.gnu.org/software/stow/).

**Every visible top-level directory is a stow package**, and each one documents
itself. Anything that is not a package lives out of the way: repo assets under
`.github/`, and material kept for reference but never symlinked under
`reference/`.

| Package | | Platform |
|---|---|---|
| [bin](bin/) | Helper scripts → `~/.local/bin` | both |
| [claude](claude/) | Claude Code settings, skills, statusline | both |
| [dms](dms/) | DankMaterialShell theme + plugin lock | Linux |
| [ghostty](ghostty/) | Terminal emulator, incl. cursor shader | both |
| [lsd](lsd/) | `ls` replacement, follows the terminal palette | both |
| [niri](niri/) | Scrolling tiling compositor | Linux |
| [nvim](nvim/) | Neovim (LazyVim) + keybind cheatsheet | both |
| [spotify](spotify/) | Forces the client onto native Wayland | Linux |
| [wireplumber](wireplumber/) | Elgato Wave XLR microphone fix | Linux |
| [tmux](tmux/) | Session persistence over SSH, not local splits | both |
| [xremap](xremap/) | `super` → `ctrl` per app, below the compositor | Linux |
| [zsh](zsh/) | Shell, prompt, aliases | both |

## New machine

```bash
curl -fsSL https://raw.githubusercontent.com/eehnsio/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` deliberately offers no choices: it installs git and GNU Stow,
clones the repo and hands over. Which packages get linked is up to you —
`./install` or `STOW_FOLDERS="nvim,zsh" ./install`. Bootstrap links nothing on
your behalf, which matters on a machine where half the packages are wrong.

> **Secrets belong in no repo** — not this public one, not a private one.
> Machine secrets live in Vaultwarden and are fetched with `vw-render`; public
> keys are distributed by `baseline.yml` in the homelab repo.

## Installation

```bash
sudo pacman -S stow          # or: brew install stow
git clone <repo-url> ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install
```

`install` stows every package, picking the Linux-only ones by `uname`. Its
package list is deliberately explicit rather than "every directory" —
`reference/` and `.github/` sit at the top level too and must never be stowed.

Install a subset instead:

```bash
STOW_FOLDERS="nvim,zsh" ./install
```

Package READMEs are not symlinked into `$HOME`. Stow ignores top-level
`README.*` on its own — **do not add a `.stow-local-ignore` to "help" it.** A
local ignore file *replaces* stow's built-in list rather than extending it,
which is exactly how `~/KEYBINDS.md` once ended up as a symlink into this repo.

`.DS_Store` is not on that built-in list either, and it is the more dangerous
case. Finder scatters them through the packages on macOS; git ignores them but
stow does not, and one stray file aborts the **entire** package. Since `install`
unstows before it stows, that abort leaves the package unlinked — `~/.zshrc`
simply disappears. `install` therefore deletes them before stowing, rather than
reaching for a local ignore file. Linux never sees this.

## Two machines

Nothing needs cherry-picking between them. `install` picks the Linux-only
packages by `uname`, so a niri commit landing on the Mac is just inert files in
a directory nothing reads. Pull everything, run `./install`, done.

The one thing that does fight you is lockfiles. `lazy-lock.json` and
`plugins.lock.json` are rewritten by their own tools at different times on each
machine, so they conflict without anyone having made a decision. `.gitattributes`
marks them `merge=ours` and `install` registers the driver, so each machine keeps
its own copy and the pull goes through.

Note that `enabledPlugins` in `claude/.claude/settings.json` also churns, but
that one is left alone on purpose — the other ten keys in that file are genuine
shared preferences that should propagate.

## Machine-specific config

Anything that differs per machine — monitors, resolutions, scaling, font size —
lives in `.local` files that are gitignored but sit *inside* the packages, so
stow symlinks them like everything else. The content stays local while the path
stays identical everywhere.

| File | Seeded from | Loaded by |
|---|---|---|
| `niri/.config/niri/local.kdl` | `local.kdl.example` | `include "local.kdl"` |
| `ghostty/.config/ghostty/config.local` | `config.local.example` | `config-file = ?config.local` |
| `zsh/.zshrc.local` | — | sourced if present |

`./install` copies each `.example` to its real name when missing. That matters
for niri: it refuses to start when an `include` target does not exist, so the
file has to be there before the first launch. Ghostty is relaxed — the `?`
prefix makes the include optional.

Both `.local` files load **last**, so they override whatever the tracked config
set.

## Theme

One accent, `#7fc8ff`, shared by niri's focus ring, the shell, the terminal
listing and the statusline. Surfaces are near-neutral greys on purpose: the blue
is what points, so nothing else should compete with it.

Ghostty carries the palette. lsd, the zsh prompt and the Claude statusline
express all their colour as ANSI indices and own no palette of their own, so
`ghostty/.config/ghostty/themes/drivis` decides how three tools look. The indices
there are assigned by **role**, not by name — 6 is the accent, 4 is directories
and branches, 8 is metadata everywhere — which is why an auto-generated palette
was not usable: `dms dank16` put a dark blue at index 5, where magenta carries
the prompt arrow and the model name.

Index 8 matters most. Nearly every character in a listing is metadata, and the
statusline rests on the same index. It sits deliberately lighter than Tokyo
Night's `#414868`, which turned out unreadable once Claude Code's own dimming was
applied on top.

Warm colours are reserved. Yellow and red appear only when something is wrong: a
git conflict, a context window running out. Never as decoration.

## How it works

- Stow creates symlinks from this repo into `$HOME`
- Edit files **here**, not in `~/.config`
- Re-run `./install` after pulling; it unstows before stowing, so it is safe to
  repeat

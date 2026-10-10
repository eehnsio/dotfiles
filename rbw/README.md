# rbw

Bitwarden from the keyboard: `Mod+P` opens the vault in rofi, `Enter` types the
login into the window you came from. Linux only. For apps and terminals — the
browser extension still fills web forms.

This package is the README. The picker is `rbw-pick` in the [bin](../bin/)
package, its look is `rbw.rasi` in the [rofi](../rofi/) package, and rbw's own
config holds the account email, so it stays out of this public repo and is set by
hand.

| Key | Does |
|---|---|
| `Enter` | types username, Tab, password |
| `Ctrl+Enter` | types only the password, for two-step logins |
| `Shift+Enter` | types username, Tab, password, then presses Enter |
| `Alt+C` | copies the password — or a note's text, a card's number |
| `Alt+U` | copies the username |
| `Alt+T` | copies the TOTP code |
| `Alt+V` | switches vault |

Notes, cards and SSH keys are always copied; only Login entries are typed.

## two vaults, two rbw profiles

Cloud Bitwarden is what a human logs in with; Vaultwarden in the homelab holds
what machines read. `RBW_PROFILE` gives each its own config, local database,
agent and lock, so unlocking one says nothing about the other. Cloud is the
default; `Alt+V` flips, and if the other vault fails (not logged in, away from
home) the picker returns to the one it came from instead of closing.

```bash
sudo pacman -S rbw wl-clipboard wtype pinentry
rbw config set email <bitwarden-email>
rbw config set pinentry pinentry-gtk
rbw register    # personal API key: web vault → Account settings → Security → Keys
rbw login

export RBW_PROFILE=vaultwarden
rbw config set base_url https://vaultwarden.ehnsio.se
rbw config set email <vaultwarden-email>
rbw config set pinentry pinentry-gtk
rbw login
```

bitwarden.com refuses logins from devices it has not seen, so the cloud profile
needs `rbw register` once; both API key halves are asked for in pinentry, never
on the command line. Vaultwarden does not.

## pinentry-gtk, not the default

rbw asks for secrets through pinentry. Started from a niri bind there is no
terminal for a curses prompt to draw in, so it has to be a graphical one.

Not `pinentry-qt`: its Qt6 backend links against KDE's `kguiaddons` and
`kwindowsystem`, which are only optional dependencies of `pinentry`. Without them
it dies on a missing library and rbw reports only
`error reading pinentry output: unexpected EOF`. `pinentry-gtk` needs nothing
beyond gtk3, which is already installed.

The prompt floats instead of taking a column: the window rule lives in niri's
config and matches `(?i)^pinentry`. The case-insensitive flag is load-bearing —
pinentry-gtk calls itself `Pinentry-gtk` with a capital P, and niri's regexes
are case-sensitive.

## our own picker, not rofi-rbw

rofi-rbw 1.7 was tried twice. What ended it:

- **It types by default.** `action = type` hands the password to `wtype` as an
  argument, where `ps` shows it to every process while it is typed. Copy-only is
  a config away, but it still crashes at start unless a typer is installed.
- **Columns by padding.** It pads name and username with spaces to line them up,
  which needs a monospace font and overflows the card into a trailing `…`.
- **No icons.** rofi can draw one per row; rofi-rbw never passes one.

`rbw-pick` is ~340 lines of Python on `rbw list --raw`, which carries name,
folder, user, type and URIs but no secrets. Each row is two lines — name, then
username and folder dimmed — so search hits the folder too: typing `homelab`
narrows to that folder.

## favicons

From each entry's first URI, fetched in a detached process so rofi never waits
on the network, cached in `~/.cache/rbw-pick/icons/`. Until a host is fetched,
or if it has no icon, the row gets its type's icon instead (key, note, card,
person).

Cloud entries ask `icons.bitwarden.net`, as Bitwarden's own apps do by default;
Vaultwarden entries ask Vaultwarden, so homelab hostnames stay home. Neither ever
sees more than a domain. IP addresses and `.local`/`.lan` names are never sent.

Both services answer **200 with a grey globe** for a domain they cannot find,
never 404. The picker fetches that globe from a domain that cannot exist
(`rbw-pick.invalid`) and compares, so a miss becomes the type icon instead of a
row of globes. Hits refresh after a month, misses retry after a week.

## typing, for apps

The idea comes from [bw-picker](https://github.com/capkz/bw-picker), which does
the same on Windows, X11 and other Wayland desktops. On GNOME and KDE it needs the
RemoteDesktop portal to send keys and AT-SPI to tell which window has focus.
niri needs neither: it has the virtual-keyboard protocol that `wtype` speaks, and
`niri msg --json focused-window` gives the window's id, pid, app-id and title.

- **The target is read before rofi opens.** Once rofi is up, it has focus.
- **Matching entries float to the top.** They score on the app-id's last part
  (`org.gnome.Nautilus` → `nautilus`) and the title's words, against the entry's
  name and URI hosts. Generic words such as `steam`, `firefox` and `login` don't
  count. This is bw-picker's heuristic.
- **Nothing is typed until niri hands focus back to that same window** (id and
  pid, not title — apps rename themselves after login). Focus is checked again
  before every field and before the final Enter. If focus moved, you get a
  notification instead of typed keys.
- **Text goes to `wtype -` on stdin**, never in argv, with 5 ms between keys.
  Electron drops characters sent faster than that.
- **Values with control characters are copied instead.** A newline in a password
  would submit the form halfway.
- **With no focused window** (an empty workspace), `Enter` copies as it used to.

What it can't do: on Wayland there is no way to read whether Shift is still held.
A short pause after rofi closes is the only guard against `Shift+Enter` typing a
shifted password. XWayland windows (Proton, Battle.net) get keys through
XWayland's keymap, so test them before relying on non-ASCII passwords there.

## copying

The password reaches `wl-copy` on **stdin**, never in argv.

`wl-copy --sensitive` adds the `x-kde-passwordManagerHint` mime type, and
noctalia's clipboard history skips anything carrying it. Measured 2026-09-24: a
plain `wl-copy` added an entry under `~/.local/state/noctalia/clipboard/entries`,
the same copy with `--sensitive` added none. Without the flag every password
copied would sit among the last 100 entries until it aged out.

After 45 seconds a detached child clears the clipboard — but only if it still
holds the secret, so something copied in the meantime survives. rbw itself locks
after `lock_timeout` (one hour); the next `Mod+P` asks for the master password
again.

## bw is something else

`rbw` reads. Moving entries between folders or changing URI match detection
needs the official `bw` CLI, which is the `bwc` function in the [zsh](../zsh/)
package.

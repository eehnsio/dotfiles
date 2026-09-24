# rbw

Bitwarden from the keyboard: `Mod+P` opens noctalia's launcher, `Enter` copies the
password. Linux only. For apps and terminals — the browser extension still fills
web forms.

This package is the README. The picker is `noctalia-rbw` in the [bin](../bin/)
package, and rbw's own `~/.config/rbw/config.json` holds the account email, so it
stays out of this public repo and is set by hand:

```bash
sudo pacman -S rbw wl-clipboard
rbw config set email <bitwarden-email>
rbw config set pinentry pinentry-gtk
rbw register    # personal API key: web vault → Account settings → Security → Keys
rbw login
```

The account is on bitwarden.com, which is rbw's default, so no `base_url`.

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

## register before login

bitwarden.com refuses logins from devices it has not seen. `rbw register` uses
the personal API key (client id + secret) to register this machine once; both
are asked for in pinentry, never on the command line.

## the shell's launcher, not rofi-rbw

rofi-rbw drew its own window in the middle of a themed shell, so `rofi/rbw.rasi`
existed only to imitate the launcher next to it — 680 px card, radius 12, colours
copied out of the theme by hand and re-copied whenever it changed. `noctalia
dmenu` *is* that launcher, so the imitation and its upkeep are gone.

What went with it: rofi-rbw's `Alt+U` and `Alt+T` for username and TOTP. Only the
password is one keypress now; the rest is `rbw get` in a terminal.

## the list is two columns, not one

`noctalia dmenu` splits each line on the first tab and draws what precedes it as
a bold title, what follows as a smaller dimmed subtitle. A line with no tab is
bold the whole way, which turned the vault into a wall of bold text. So the
script emits `name<TAB>folder - username`. Search covers both halves, so a folder
name still finds its entries.

`rbw ls --fields folder,name,user` returns the whole folder path as one field, so
nested folders need no extra work. The chosen line is matched back against that
same list instead of looked up by name, because one name can exist in several
folders.

## copy, never type

The password reaches `wl-copy` on **stdin**. `noctalia msg clipboard-copy <text>`
would put it in argv, where `ps` shows it to every process on the machine.

`wl-copy --sensitive` adds the `x-kde-passwordManagerHint` mime type, and
noctalia's clipboard history skips anything carrying it — the same contract DMS
had. Measured 2026-09-24: a plain `wl-copy` added an entry under
`~/.local/state/noctalia/clipboard/entries`, the same copy with `--sensitive`
added none. Without the flag every password copied would sit among the last 100
entries, and entries survive until they age out of the history.

The script then clears the live clipboard after 45 seconds. rbw itself locks
after `lock_timeout` (default one hour); the next `Mod+P` asks for the master
password again.

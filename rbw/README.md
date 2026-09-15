# rbw

Bitwarden from the keyboard: `Mod+P` opens a rofi list, `Enter` copies the
password. Linux only. For apps and terminals — the browser extension still fills
web forms.

Only `rofi-rbw.rc` is stowed. rbw's own `~/.config/rbw/config.json` holds the
account email and stays out of this public repo, so it is set by hand:

```bash
sudo pacman -S rbw rofi-rbw rofi wtype
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

## register before login

bitwarden.com refuses logins from devices it has not seen. `rbw register` uses
the personal API key (client id + secret) to register this machine once; both
are asked for in pinentry, never on the command line.

## rofi, not fuzzel

rofi-rbw 1.7 passes its key bindings to fuzzel as `--override=key-bindings.…`,
an option that only exists from fuzzel 1.15. Arch ships 1.14.1, which rejects it
with `invalid option` and exit code 1 — and rofi-rbw reads exit code 1 as the
user pressing Escape, so it quits silently. rofi 2.0 in `extra` is native
Wayland and takes `-kb-custom-N` bindings. Worth revisiting once fuzzel 1.15
lands.

## Looks

`rofi/rbw.rasi` draws rofi as the DMS spotlight launcher: the 680 px card,
radius 12, the blue icon circle and the selected-row tint were measured from a
screenshot of the launcher. The colours come from the Drivis theme — copied, not
linked, so a change to `dms/themes/drivis/theme.json` has to be made here too.
The icon is a padlock and the placeholder says Bitwarden, so it is not mistaken
for the launcher itself.

Like spotlight it dims the screen: rofi runs fullscreen in 50 % black and the
card is an inner box, centred by the padding on `mainbox`. `listview` has
`fixed-height: true`: in a card that sizes to its content the list otherwise
collapsed to nothing and only the search row showed.

The list is monospace on purpose: rofi-rbw pads name and username with spaces
into columns, which only line up in a fixed-width font.

## Copy, never type

`Enter` copies the password, `Alt+U` the username, `Alt+T` the TOTP code.
rofi-rbw's default bindings *type* text instead; they are replaced because the
browser already covers autofill.

`wtype` is installed anyway: rofi-rbw asks the typer for the active window when
it starts, before it knows the action, and exits with `NoTyperFoundException`
when there is none. From the niri bind that looks like `Mod+P` doing nothing.
It never types anything with this config.

Copying goes through `wl-copy --sensitive`, which offers the
`x-kde-passwordManagerHint` mime type. DMS will not store anything carrying that
hint, so these passwords never reach the clipboard history — unlike copies from
the Bitwarden desktop app, which does not set it. `clear-after = 30` empties the
live clipboard as well.

rbw locks itself after `lock_timeout` (default one hour); the next `Mod+P` asks
for the master password again.

# rofi

The launcher. `Mod+Space` lists applications, and `rbw-pick` in the [bin](../bin/)
package draws the vault on `Mod+P` in the same card. Linux only. Replaced
noctalia's launcher in October 2026 — that one could not be styled far enough,
and one theme for both is the point.

| File | |
|---|---|
| `drivis.rasi` | The palette, nothing else. Imported by the other two |
| `config.rasi` | The card, used by `rofi -show drun` |
| `rbw.rasi` | Imports `config.rasi`; changes only the icon, placeholder and row size |
| `icons/` | Search glass, key, vault shield, and type icons for `rbw-pick` |

## it looks like the login screen

The look is taken from the SDDM theme (`reference/sddm/drivis.conf`), not from
noctalia: Red Hat Display, a `#16181d` surface at 85 % with a 1 px `#4a505c`
border, and the selected row in the colours SDDM uses for its menus. The key
icon is SilentSDDM's own `password.svg`, recoloured to the accent; the others
are drawn to match it.

The glass behind the card is **niri's** blur, not rofi's — rofi cannot blur. It
is a `layer-rule` on namespace `rofi` in niri's config, with
`geometry-corner-radius 14`. That radius has to equal `border-radius` on
`window` in `config.rasi`, or blurred square corners stick out past the card.

## toggles, not launches

The binds are `pkill -x rofi || rofi …`. rofi refuses a second instance and
does not close itself when its key is pressed again, so without the `pkill` a
second `Mod+Space` does nothing at all.

## fixed height

`fixed-height: true` in `listview` keeps the card the same size while typing.
Without it the list shrinks with every match and the centred card jumps.

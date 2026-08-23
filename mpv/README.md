# mpv

Video player. It is the system default for `video/*` on this machine, so
double-clicking a clip in Nautilus lands here.

Two things are configured, and the second one is split across two packages.

## It no longer disappears at the end of the clip

mpv's default is `keep-open=no`: at end of file the process exits and the window
vanishes. `keep-open=yes` pauses on the last frame instead, so a clip that ends
leaves something on screen to seek back into. `q` still quits.

The `always` variant exists too and additionally overrides playlist advancement.
Not wanted — with a folder of clips open, moving on to the next file is the
right behaviour.

Worth knowing that the `mpv.desktop` file — the path every double-click in
Nautilus takes — launches with `--player-operation-mode=pseudo-gui`, which sets
`idle=once` and therefore quits after playback ends. `keep-open` still wins,
because pausing on the last frame means playback never ends in the first place.
Verified rather than assumed; the two settings look like they should collide.

## The window is sized by the clip, not by a rule

This half lives in **`niri/.config/niri/config.kdl`**, which opens `app-id=mpv`
floating. A clip is something you watch beside your work, not a column in the
layout.

That rule deliberately sets **no `default-column-width` and no
`default-window-height`**. niri gives a floating window the size the client asks
for whenever a rule does not override it, and mpv asks for the video's own
dimensions — so a portrait phone clip opens portrait and a widescreen one opens
wide. Pin a size in the rule and both get the same box, with letterboxing to
make up the difference.

`autofit-larger` and `autofit-smaller` here are the bounds on that request, as a
share of the output the window opens on. They preserve aspect ratio — the values
are a frame to fit inside, not a shape to stretch to. Without the ceiling a 4K
clip opens larger than the screen; without the floor an old 480p clip is a
postage stamp. Note the second monitor is rotated, so 60% of it is 648×1152:
percentages follow the screen, which is the point of using them over pixels.

## Maximizing, and the layer it happens in

Floating does not mean stuck small, but the obvious key is the wrong one.

niri draws the **whole floating layer above the whole tiling layer**, and
fullscreen above both. Which layer a window ends up in therefore decides what
can cover it — and that is ordering, not focus, so clicking the covered window
does not raise it.

`Mod+M` (`maximize-window-to-edges`) fills the screen but **moves the window out
of the floating layer into the tiling one**. A maximized video therefore ends up
underneath every floating neighbour — Nautilus in particular, which this repo
also opens floating. Focusing the video does not help.

`Mod+F` (`maximize-column`) does nothing at all here. It acts on a *column*, and
a floating window is not in one.

| | |
|---|---|
| `Mod+Shift+M` | fill the screen, **stay floating** — the one to use |
| `f` | mpv's own fullscreen, from inside the player |
| `Mod+Shift+F` | niri fullscreen — above everything, including floating |
| `Mod+M` | fills the screen, but tiles the window — gets covered |
| `Mod+V` | drop the window into the tiling layout deliberately |

`Mod+Shift+M` is three IPC calls rather than an action, because niri allows only
one action per keybind and none of them does this. The third call,
`center-window`, is not cosmetic: a floating window keeps its top-left corner as
it grows, so widening it to 100% without recentring pushes the right half off
the screen. Back to normal is `Mod+Alt+2` for the width and `Mod+Ctrl+R` for the
height.

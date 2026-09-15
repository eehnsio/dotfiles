# xremap

App-specific `super` → `ctrl` translation, below the compositor. Linux only.

Runs as a systemd user unit tied to the niri session. Needs the user in the
`input` group and a udev rule for `/dev/uinput`.

```bash
systemctl --user daemon-reload
systemctl --user enable --now xremap.service
```

## Why a unit and not spawn-at-startup

It used to be spawned by niri, and that **killed the keyboard on log out and back
in**. niri does not stop what it spawns when it quits. Wayland clients die anyway
because their compositor is gone; xremap is not one, so it outlived the session.
The next login spawned a second instance, and with `--watch=device` each grabbed
the virtual keyboard the other one creates. Keys went round in a loop between
them — the new instance burned 16 s of CPU in 27 s — and nothing reached the
greeter or the session. Only a reboot got out of it.

`PartOf=graphical-session.target` stops it at log out, so there is exactly one
per session. It still knows the focused window: niri imports `NIRI_SOCKET` into
the user manager's environment before `graphical-session.target` is reached, so
the unit sees the current session's socket without being niri's child.

If the keyboard ever dies after a log out again, a TTY will not help: xremap
grabs the device itself, so every VT loses the keyboard too. Get in over SSH from
another machine and count the instances — `pkill xremap` gives the keyboard back
without a reboot:

```bash
pgrep -a xremap
```

## exact_match is not optional

Every app block sets `exact_match: true`. Without it xremap matches **loosely**:
a rule for `Super-q` also swallows `Super+Ctrl+Q` and passes the extra modifier
through, which would eat the lock screen bind whenever that app had focus.

The first keymap has no `application` filter and identity-maps the lock screen,
so no later block can reach it at all.

Keys are deliberately left unmapped where the app already has its own meaning —
`Super-f` stays with niri's maximize rather than becoming find-in-page.

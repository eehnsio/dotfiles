# xremap

App-specific `super` → `ctrl` translation, below the compositor. Linux only.

Started from niri's `spawn-at-startup` by absolute path, for the same PATH
reason as the `bin` package. Needs the user in the `input` group and a udev rule
for `/dev/uinput`.

## exact_match is not optional

Every app block sets `exact_match: true`. Without it xremap matches **loosely**:
a rule for `Super-q` also swallows `Super+Ctrl+Q` and passes the extra modifier
through, which would eat the lock screen bind whenever that app had focus.

The first keymap has no `application` filter and identity-maps the lock screen,
so no later block can reach it at all.

Keys are deliberately left unmapped where the app already has its own meaning —
`Super-f` stays with niri's maximize rather than becoming find-in-page.

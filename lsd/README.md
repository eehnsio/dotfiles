# lsd

`ls` replacement, wired to `ls`/`ll`/`la`/`lt` in `.zshrc`.

## Two gotchas

**`colors.yaml` is ignored unless `config.yaml` says so.** It needs

```yaml
color:
  theme: custom
```

Without that line lsd silently falls back to its built-in palette and never
mentions the file.

**Colours are ANSI indices, not hex.** lsd then follows the active terminal
theme by itself, the same way the zsh prompt does. A hardcoded palette pins a
second theme that drifts out of sync the moment Ghostty changes.

## The rule

Metadata is noise and goes grey. The filename is what you read, and lsd already
colours it by type. The accent is spent only on things that are *rare* — an
unusually large file, git status. Permission bits are grey **including the exec
bit**: directories are always executable, so highlighting it lit up every row in
a directory-heavy listing and the accent became the noise it was meant to remove.

Dates vary by brightness rather than hue, so recent changes surface without
adding another colour.

Red survives for deleted and conflicted only. Semantic colour and accent colour
are different things.

`lt` is depth-limited to 2; pass `--depth N` for more.

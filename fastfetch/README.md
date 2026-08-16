# fastfetch

Two views instead of one wall of text.

| | |
|---|---|
| `fastfetch` | System, session, uptime — what environment am I sitting in |
| `ffhw` | Machine, memory, displays — what hardware is this |

`ff` and `ffhw` are aliases in `zsh/.zshrc`; fastfetch resolves the config name
against this directory.

## Notes on the layout

**Escape sequences must be written `` in the JSON.** Raw control characters
are rejected by the parser, which is easy to trip over when building the section
rules.

**Keys carry an icon *and* a label.** Icon-only reads well in a screenshot but
requires knowing what every glyph means; the label costs one column and removes
the guessing.

**A uniform `│` gutter, never `┌ ├ └`.** fastfetch sets the key per *module*, not
per row, and cannot know how many rows a module will produce. GPU emits one row
per card and Displays one per monitor, so a closing `└` appears twice and a
section can start mid-tree. Tree shapes are therefore unachievable, not merely
unchosen.

**`key.width` aligns the colons**, and it does so by emitting a cursor-column
escape. That is why a raw `[61G` shows up if you pipe the output through a filter
that only strips colour codes — it is doing its job.

Set it **wider than the longest key**, with room to spare. A cursor-column escape
cannot move backwards, so a key that reaches the width swallows the separator
entirely: `Packages8 (flatpak)` instead of `Packages : 8 (flatpak)`. The longest
labels here are `Packages` and `Terminal`; 21 leaves headroom for the gutter, the
icon and a longer label later.

`host` is left out entirely — it produced no row on this machine, so `board`
carries the machine identity instead.

**Icons are Nerd Font glyphs from the Font Awesome range** (`\uf0xx`–`\uf2xx`),
which every Nerd Font ships. The terminal must be running one; Ghostty is set to
`UbuntuMono Nerd Font Mono`. Empty boxes instead of icons means the terminal
fell back to a font without them.

**No `title` module**, so `user@host` is not printed. One less thing to redact in
a screenshot.

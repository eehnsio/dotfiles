# fastfetch

Two views instead of one wall of text.

| | |
|---|---|
| `fastfetch` | System, session, uptime — what environment am I sitting in |
| `ffhw` | Machine, memory, displays — what hardware is this |

`ffhw` is an alias in `zsh/.zshrc` for `fastfetch --config hardware`; fastfetch
resolves the name against this directory.

## Notes on the layout

**Escape sequences must be written `` in the JSON.** Raw control characters
are rejected by the parser, which is easy to trip over when building the section
rules.

**The default view uses tree connectors, the hardware view does not.** That is
deliberate, not an inconsistency. fastfetch sets the key per *module*, not per
row, and cannot know how many rows a module will produce. Every module in the
default view is single-row, so `┌ ├ └` is always correct there. In the hardware
view GPU emits one row per card and Displays one per monitor, so a closing `└`
would appear twice and a section could start mid-tree. Those use a uniform `│`.

`host` is left out entirely — it produced no row on this machine.

**Icons are Nerd Font glyphs from the Font Awesome range** (`\uf0xx`–`\uf2xx`),
which every Nerd Font ships. The terminal must be running one; Ghostty is set to
`UbuntuMono Nerd Font Mono`. Empty boxes instead of icons means the terminal
fell back to a font without them.

**No `title` module**, so `user@host` is not printed. One less thing to redact in
a screenshot.

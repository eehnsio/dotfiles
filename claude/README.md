# claude

Claude Code settings, custom skills, and the statusline.

Marketplace plugins are declared in `.claude/settings.json` and installed by
Claude Code itself, so there are no local copies here.

Private or company-internal skills use a `-private` suffix and are excluded by a
wildcard in the root `.gitignore`.

## statusline-command.sh

Colours are ANSI codes rather than hex, so the line follows whatever theme
Ghostty is set to.

| Level | Carries |
|---|---|
| magenta / cyan / blue | the three values you read: model, directory, branch |
| green | quantities: commits to push, changed lines, context left |
| dim | only `in`, parentheses and the separator |

Nothing sits on `\033[39m`. That is the terminal's default foreground with no
hue of its own, and Claude Code already renders the whole line dimmed — an
uncoloured tone loses the most to that, which is how "13 commits to push"
became invisible. Colour was the fix, not a brighter grey.

Yellow and red are reserved for the context window running low, so the warning
is the only warm colour on the line.

# claude

Claude Code settings, custom skills, and the statusline.

Marketplace plugins are declared in `.claude/settings.json` and installed by
Claude Code itself, so there are no local copies here.

Private or company-internal skills use a `-private` suffix and are excluded by a
wildcard in the root `.gitignore`.

## hooks

Three guards, wired up in `settings.json`:

| Hook | Event | Job |
|---|---|---|
| `block-rm-rf.sh` | PreToolUse, Bash | recursive force deletes always need approval |
| `damage-control/guard.py` | PreToolUse, Bash + Edit + Write | reads `patterns.toml`: allow, ask, or block |
| `settings-drift.sh` | SessionStart | warns when `~/.claude/settings.json` has drifted from the repo |

The two Bash guards overlap on purpose. `permissions.ask` in `settings.json`
covers `rm -rf` a third time. Layers are cheap; a gap is not.

`guard.py` strips heredoc bodies before matching, because they are input rather
than commands — without that, a commit message describing a dangerous command
becomes a wall against committing at all. It also fails open and prints to
stderr: a broken guard must not lock the session.

**Failing open is not enough on its own.** A hook whose *command* cannot be
resolved fails closed, and that is the trap: `~/.claude/hooks` is a stow symlink
into this repo, so any operation that removes `guard.py` from the working tree —
a `git reset --hard` to a commit predating it, a checkout of an older branch —
kills Bash, Edit and Write in one stroke, including every tool needed to put the
file back. Recovering means running the copy by hand outside Claude Code. Move
between commits that straddle these hooks with that in mind.

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

## Hooks

The scripts are shared through this repo, but **they are passive until a
machine opts in.** Sharing a guard and imposing one are different things.

```bash
touch ~/.claude/hooks.enabled      # arm them on this machine
rm ~/.claude/hooks.enabled         # back to passive
```

All three check for that file first and exit silently without it. It
deliberately lives in `~/.claude/` and not in `~/.claude/hooks/` — the latter is
a stow symlink into this repo, so a marker there would be committed and arm the
hooks on every machine at once.

The cost of opt-in is worth stating: a machine that had them armed loses that
protection the moment it is set up fresh, and nothing announces it. Check with
`ls ~/.claude/hooks.enabled` if you expect them to be running.

**Run `./install` immediately after pulling.** `settings.json` is a symlink, so a
pull activates new hook config the instant it lands — while the scripts it points
at are still missing until stow has run. A hook that cannot start counts as
blocking, and the tool it guards dies. That window is unrecoverable from inside
Claude Code when the blocked tool is Bash.

The hook commands are written as `[ -f <script> ] && <run> || exit 0` for the
same reason: a missing file now fails open instead of taking the session with it.
`guard.py` already defends every internal failure this way, including Python
older than 3.11 without `tomllib`, but it cannot defend against not existing.

#!/bin/sh
# Markerar klara subagenter i Rex (OSC 7501, id=agents/<id>, state=done).
# Claude Code rapporterar redan pågående subagenter själv, men posten försvinner
# när agenten är klar. Den här ligger kvar som "done" tills nästa prompt.
# Anropas från SubagentStop och UserPromptSubmit.
# Hooks saknar styrande terminal, så sekvensen skrivs till claude-processens tty.
# Gör ingenting utanför Rex.

[ -n "$REX_BLOCK" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
[ -n "$REX_STATUS_DEBUG" ] && printf '%s\n' "$input" >> "${TMPDIR:-/tmp}/rex-subagent-hook.log"

event=$(printf '%s' "$input" | jq -r '.hook_event_name // empty')
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty' | tr -cd 'A-Za-z0-9_.+-' | cut -c1-32)
agent_type=$(printf '%s' "$input" | jq -r '.agent_type // "agent"')

# Gå uppåt i processträdet till första förälder som har en tty.
tty=""
p=$PPID
while [ -n "$p" ] && [ "$p" -gt 1 ]; do
  t=$(ps -o tty= -p "$p" 2>/dev/null | tr -d ' ')
  case "$t" in
    ""|"??") p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ') ;;
    *) tty="/dev/$t"; break ;;
  esac
done
[ -n "$tty" ] && [ -w "$tty" ] || exit 0

b64() { printf '%s' "$1" | tr -d '\000-\037\177' | base64 | tr -d '\n'; }
emit() { printf '\033]7501;%s\033\\' "$1" > "$tty"; }

case "$event" in
  SubagentStop)
    [ -n "$agent_id" ] || exit 0
    emit "id=agents/$agent_id:state=done:app=claude-code:title=$(b64 "$agent_type"):msg=$(b64 "Subagent klar")"
    ;;
  UserPromptSubmit)
    # Ny fråga: städa bort förra rundans klara agenter.
    emit "id=agents:state=clear"
    ;;
esac
exit 0

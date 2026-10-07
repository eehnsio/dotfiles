// En levande Claude Code-session på maskinen, som ~/.claude/sessions/<pid>.json
// beskriver den. `status` är busy (jobbar), waiting (står på en fråga eller
// en behörighetsdialog, `waitingFor` säger vilken) eller idle (klar, väntar
// på nästa prompt). `since` är när statusen senast bytte, i epoch-ms.
export type SessionRow = {
  pid: number
  name: string
  cwd: string
  status: string
  waitingFor?: string
  since: number
  isSelf: boolean
  isApp: boolean
}

// Något som hänt en annan session och som du bör se: den står på en fråga
// (waiting) eller har jobbat klart (done). Ligger kvar i bandet tills
// sessionen byter läge igen, en klar-notis högst DONE_NOTICE_MS.
export type SessionNotice = {
  pid: number
  name: string
  kind: 'waiting' | 'done'
  detail: string
  at: number
}

// Promptcachen i notisraden: snart kall (med minuter kvar) eller kall. Null
// när det inte finns något att säga, som medan en tur kör.
export type CacheNotice = { kind: 'warn' | 'cold'; minutesLeft: number }

// ~/.claude/settings.json har slutat vara en länk in i dotfiles: den saknas,
// är en vanlig fil med samma innehåll, eller har glidit isär. `fix` är
// kommandot som återställer eller visar skillnaden. Null när länken håller.
export type SettingsDrift = { kind: 'missing' | 'unlinked' | 'diverged'; fix: string }

declare module 'claude-code' {
  interface PluginState {
    sessions: {
      rows: SessionRow[]
      notices: SessionNotice[]
      cache: CacheNotice | null
      // När huvudloopens senaste tur tog slut, så en omladdning kan ställa om
      // cachens timrar.
      lastTurnAt: number | null
      drift: SettingsDrift | null
    }
  }
}

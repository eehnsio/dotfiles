-- Migrated from Ghostty: ~/.config/ghostty/config:55
rex.bind("shift+cmd+e", "pane.balance")

-- Flikbyte med Cmd+< (svenskt tangentbord). §-tangenten går inte att binda här, och macOS har Cmd+§ för fönsterbyte
rex.bind("cmd+[Backquote]", "client.tab.next")
rex.bind("shift+cmd+[Backquote]", "client.tab.previous")

-- Samma muskelminne som i niri (Mod = Cmd): en Rex-ruta motsvarar ett niri-fönster.
-- Cmd+Enter (ny ruta) och Cmd+W (stäng) är redan samma som i niri.
rex.bind("cmd+f", "pane.zoom")                               -- niri Mod+F, maximera
rex.bind("shift+cmd+f", "client.window.fullscreen.toggle")   -- niri Mod+Shift+F
rex.bind("ctrl+cmd+v", "pane.float")                         -- niri Mod+V, men Cmd+V är klistra in på Mac

-- Pilar som i Ghostty: Cmd+Alt byter ruta (Rex standard redan), Cmd+Ctrl ändrar storlek.
-- Cmd+pil lämnas åt radredigeringen. Shift+Cmd+pil flyttar rutan, som Mod+Shift+pil i niri.
for _, dir in ipairs{ "left", "right", "up", "down" } do
  rex.bind("ctrl+cmd+" .. dir, "pane.resize", { direction = dir })
  rex.bind("shift+cmd+" .. dir, "pane.move." .. dir)
end

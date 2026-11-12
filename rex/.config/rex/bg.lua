-- Kör ett kommando i en minimerad flytande ruta i sessionen. Avslutas det med
-- fel visas rutan flytande (inte maximerad), annars ligger den kvar minimerad
-- med utdatan kvar. Startas av rexbg, eller direkt:
--   rex do ~/.config/rex/bg.lua cmd="go test ./..." cwd="$PWD"

local cmd = rex.args.cmd or error("cmd saknas", 0)
local cwd = rex.args.cwd
local label = rex.args.label or cmd:match("^%S+")

local layer, err = rex.session.new_layer{
  bounds = { 0.55, 0.5, 0.43, 0.47 },
  focus  = false,
  layout = rex.layout.block{
    flavor  = "com.superlogical.terminal.shell",
    options = {
      command = { "sh", "-c", cmd },
      cwd     = cwd,
      exit    = { on_completion = false },
    },
  },
}
if err ~= nil then error(err, 0) end
local block_id = layer.block_ids[1]

rex.session.set_block_label{ block_id = block_id, label = label }
rex.session.set_layer_state{ layer_id = layer.layer_id, state = "minimized" }

-- Dev-servrar kör tills vidare, så vänta i omgångar. Skriptet slutar också
-- om sessionen stängs.
local ev
repeat
  ev = rex.wait("terminal.child_exited", { block_id = block_id }, 3600)
until ev ~= nil

if ev.exit_code ~= 0 then
  rex.session.set_layer_state{ layer_id = layer.layer_id, state = "normal" }
  rex.session.raise_layer{ layer_id = layer.layer_id }
end

return { block_id = block_id, layer_id = layer.layer_id, exit_code = ev.exit_code }

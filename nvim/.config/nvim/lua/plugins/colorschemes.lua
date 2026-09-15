-- Bada temana ar installerade och bada kor transparent bakgrund, sa ghosttys
-- background-opacity 0.90 och blur slar igenom i editorn precis som i skalet.
-- Byt i farten med :colorscheme oxocarbon respektive :colorscheme kanagawa-wave.
-- Det som startar ar det som star i colorscheme.lua.

-- Drivis, samma varden som ghostty/.config/ghostty/themes/drivis. nvim kor
-- truecolor och arver alltsa INTE terminalens palett — andras en farg dar
-- maste den andras har ocksa.
local drivis = {
	bg0 = "#101216",
	bg = "#16181d",
	fg = "#c8cdd6",
	fg_bright = "#d2d7df",
	white = "#aeb4c0",
	gray = "#4a505c",
	selection = "#2b3342",

	red = "#e06c75",
	green = "#8fb8a0",
	yellow = "#d8a657",
	blue = "#6f9ad4",
	magenta = "#a893c9",
	cyan = "#7fc8ff",

	bright_red = "#ec8891",
	bright_green = "#a6cbb5",
	bright_yellow = "#e6bd7d",
	bright_blue = "#8fb4e4",
	bright_magenta = "#bfabdb",
	bright_cyan = "#a6dbff",

	-- De har finns inte i terminalen. Kommentarer behover ligga mellan
	-- gratt (8) och vitt (7): gratt ger kontrast 2.2 mot botten, for lite
	-- for text man faktiskt laser. 40 % mot vitt ger 4.0.
	comment = "#727884",
	-- Diff- och sokbakgrunder: rollfargen blandad in i botten.
	diff_add = "#293232",
	diff_delete = "#36252b",
	diff_change = "#222a37",
	diff_text = "#313f54",
	search = "#2d3f4f",
	cursorline = "#23262d",
	pmenu = "#1d222c",
}

return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
			-- Utan detta far statusraden och sidopanelerna en egen, matt
			-- botten som syns som en platta mot den genomskinliga resten.
			dimInactive = false,
			background = {
				dark = "wave",
			},
			colors = {
				-- Kanagawa star kvar for sin plugintackning, men dess roller fylls
				-- med Drivis efter samma logik som terminalen:
				--
				--   vit       text: variabler, parametrar, falt
				--   bla       struktur: nyckelord, import (typer i ljusare bla)
				--   cyan      accenten, fokusringens #7fc8ff: funktioner
				--   gron      varden: strangar (tal och konstanter i ljusare gron)
				--
				-- Rod och gul anvands bara for fel och varningar, precis som i
				-- terminalen. Kanagawa farger annars return, this och operatorer
				-- varmt; de ar flyttade till bla och vitt.
				theme = {
					all = {
						ui = {
							fg = drivis.fg,
							fg_dim = drivis.white,
							fg_reverse = drivis.bg0,

							bg_dim = drivis.bg0,
							bg_gutter = "none",

							bg_m3 = drivis.bg0,
							bg_m2 = drivis.bg0,
							bg_m1 = drivis.bg,
							bg = drivis.bg,
							bg_p1 = drivis.cursorline,
							bg_p2 = drivis.cursorline,

							special = drivis.blue,
							nontext = drivis.gray,
							whitespace = drivis.gray,

							bg_search = drivis.search,
							bg_visual = drivis.selection,

							pmenu = {
								fg = drivis.fg,
								fg_sel = "none",
								bg = drivis.pmenu,
								bg_sel = drivis.selection,
								bg_sbar = drivis.pmenu,
								bg_thumb = drivis.gray,
							},
							float = {
								fg = drivis.fg,
								bg = drivis.bg0,
								fg_border = drivis.gray,
								bg_border = drivis.bg0,
							},
						},
						syn = {
							string = drivis.green,
							variable = "none",
							number = drivis.bright_green,
							constant = drivis.bright_green,
							identifier = drivis.fg,
							parameter = drivis.fg,
							fun = drivis.cyan,
							statement = drivis.blue,
							keyword = drivis.blue,
							operator = drivis.white,
							preproc = drivis.blue,
							type = drivis.bright_blue,
							regex = drivis.bright_green,
							deprecated = drivis.gray,
							comment = drivis.comment,
							punct = drivis.white,
							special1 = drivis.cyan,
							special2 = drivis.blue,
							special3 = drivis.blue,
						},
						vcs = {
							added = drivis.green,
							removed = drivis.red,
							-- Blatt, inte kanagawas gula: en andrad rad ar ingen varning.
							changed = drivis.blue,
						},
						diff = {
							add = drivis.diff_add,
							delete = drivis.diff_delete,
							change = drivis.diff_change,
							text = drivis.diff_text,
						},
						diag = {
							ok = drivis.green,
							error = drivis.red,
							warning = drivis.yellow,
							info = drivis.blue,
							hint = drivis.bright_green,
						},
						-- :terminal och lazygit far exakt ghosttys palett.
						term = {
							drivis.bg0,
							drivis.red,
							drivis.green,
							drivis.yellow,
							drivis.blue,
							drivis.magenta,
							drivis.cyan,
							drivis.white,
							drivis.gray,
							drivis.bright_red,
							drivis.bright_green,
							drivis.bright_yellow,
							drivis.bright_blue,
							drivis.bright_magenta,
							drivis.bright_cyan,
							drivis.fg_bright,
							drivis.yellow,
							drivis.bright_red,
						},
					},
				},
			},
			-- Kanagawa lanar varningsgult till saker som inte ar varningar:
			-- radnumret vid markoren, matchande parentes, soktraffen och
			-- lagesmeddelandet. De tar accenten i stallet, sa gult pa skarmen
			-- alltid betyder att nagot ar fel.
			overrides = function()
				return {
					CursorLineNr = { fg = drivis.cyan, bold = true },
					MatchParen = { fg = drivis.cyan, bold = true },
					IncSearch = { fg = drivis.bg0, bg = drivis.cyan },
					CurSearch = { link = "IncSearch" },
					ModeMsg = { fg = drivis.cyan, bold = true },
					LspSignatureActiveParameter = { fg = drivis.cyan },
				}
			end,
		},
	},

	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = false,
		priority = 1000,
		-- Repot innehaller en rockspec, sa lazy satter automatiskt
		-- build = "rockspec" och forsoker kora luarocks — som inte finns
		-- installerat har. Bygget misslyckas och Lazy visar temat som
		-- "Failed" trots att det fungerar. Oxocarbon ar ren Lua utan
		-- beroenden och behover inget bygge alls.
		build = false,
		config = function()
			-- Oxocarbon har ingen transparensinstallning. Den hardkodar
			-- bg = #161616 pa Normal och ett tjugotal andra grupper, sa
			-- bakgrunderna maste nollas efter att temat laddats. Autocmden
			-- ligger kvar och gor det varje gang man byter tillbaka.
			-- Exakt de grupper kanagawa gor genomskinliga, sa de tva temana
			-- beter sig likadant. Notera vad som INTE star har: NormalFloat
			-- och FloatBorder behaller sin platta med flit. Popups ligger
			-- ovanpa kod och ska ha nagot att lasas mot — helt genomskinliga
			-- flyter de ihop med bade texten under och den suddiga tapeten.
			local groups = {
				"Normal",
				"NormalNC",
				"SignColumn",
				"LineNr",
				"CursorLineNr",
				"FoldColumn",
				"VertSplit",
				"WinSeparator",
				"EndOfBuffer",
				"MsgArea",
			}

			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "oxocarbon",
				group = vim.api.nvim_create_augroup("oxocarbon_transparent", { clear = true }),
				callback = function()
					for _, name in ipairs(groups) do
						local hl = vim.api.nvim_get_hl(0, { name = name })
						-- Lankade grupper arver fran sitt mal; nollar man dem
						-- har bryts lanken i onodan.
						if not hl.link then
							hl.bg = nil
							hl.ctermbg = nil
							vim.api.nvim_set_hl(0, name, hl)
						end
					end
				end,
			})
		end,
	},
}

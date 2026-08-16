-- Bada temana ar installerade och bada kor transparent bakgrund, sa ghosttys
-- background-opacity 0.90 och blur slar igenom i editorn precis som i skalet.
-- Byt i farten med :colorscheme oxocarbon respektive :colorscheme kanagawa-wave.
-- Det som startar ar det som star i colorscheme.lua.
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
				theme = {
					all = {
						ui = {
							bg_gutter = "none",
						},
					},
				},
			},
		},
	},

	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = false,
		priority = 1000,
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

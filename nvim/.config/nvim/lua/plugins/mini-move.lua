return { -- Collection of various small independent plugins/modules
	"nvim-mini/mini.move",
	-- You can customize mappings here or leave them as defaults
	mappings = {
		left = "<M-Left>",
		right = "<M-Right>",
		down = "<M-Down>",
		up = "<M-Up>",
		line_left = "<M-Left>",
		line_right = "<M-Right>",
		line_down = "<M-Down>",
		line_up = "<M-Up>",
	},
	options = {
		reindent_linewise = true, -- Reindents during vertical movement
	},
}

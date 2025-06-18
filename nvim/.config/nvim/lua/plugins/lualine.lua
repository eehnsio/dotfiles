return {
	"nvim-lualine/lualine.nvim",
	optional = true,
	event = "VeryLazy",
	config = function()
		require("lualine").setup({
			options = {
				component_separators = "",
				section_separators = "",
			},
			-- sections = {
			-- 	lualine_x = {
			-- 		{
			-- 			"mode",
			-- 			fmt = function(str)
			-- 				return str:sub(1, 1)
			-- 			end,
			-- 		},
			-- 	},
			-- 	lualine_b = { "branch" },
			-- },
		})
	end,
}

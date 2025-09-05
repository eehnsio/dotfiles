return {
	"numToStr/Comment.nvim",
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		-- First, disable the default autocmd in nvim-ts-context-commentstring
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})

		-- Then set up Comment.nvim with the pre-hook configuration
		require("Comment").setup({
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		})
	end,
}

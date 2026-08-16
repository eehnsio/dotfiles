return {
	{ "folke/noice.nvim", enabled = false },
	{ "nvim-neo-tree/neo-tree.nvim", enabled = false },
	{ "akinsho/bufferline.nvim", enabled = false },

	-- Kommentering är inbyggt i Neovim (gc/gcc) sedan 0.10, och LazyVims
	-- ts-comments.nvim gör det treesitter-medvetet (JSX får {/* */}).
	-- Comment.nvim + nvim-ts-context-commentstring är den gamla stacken.
	{ "numToStr/Comment.nvim", enabled = false },
	{ "JoosepAlviste/nvim-ts-context-commentstring", enabled = false },
}

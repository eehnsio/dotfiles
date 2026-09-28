return {
	-- lang.markdown drar in iamcco/markdown-preview.nvim, som står still och
	-- kräver Node. sammaji-forken har samma kommandon och en Rust-server som
	-- laddas ner färdigbyggd. Båda heter markdown-preview.nvim, så lazy ser dem
	-- som samma plugin: pekas url om här i stället för att stänga av originalet.
	{
		"iamcco/markdown-preview.nvim",
		url = "https://github.com/sammaji/markdown-preview.nvim",
		build = function()
			require("lazy").load({ plugins = { "markdown-preview.nvim" } })
			vim.fn["mkdp#util#install_sync"](true)
		end,
	},
}

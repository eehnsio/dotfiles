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
	-- Utan en .markdownlint-fil i repot kör markdownlint-cli2 alla
	-- standardregler. --config ger en bas som både lintern och
	-- --fix-formateringen läser.
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters = {
				["markdownlint-cli2"] = {
					prepend_args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint.yaml" },
				},
			},
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters = {
				["markdownlint-cli2"] = {
					prepend_args = { "--config", vim.fn.stdpath("config") .. "/.markdownlint.yaml" },
				},
			},
		},
	},
}

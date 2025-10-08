return {
	"sindrets/diffview.nvim",
	keys = {
		{ "<leader>gd", mode = { "n", "v" }, "<cmd>DiffviewOpen<cr>", desc = "Open git diff" },
		{ "<leader>gh", mode = { "n", "v" }, "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
		{ "<leader>gH", mode = { "n", "v" }, "<cmd>DiffviewFileHistory<CR>", desc = "Branch history" },
		{ "<leader>gq", mode = { "n", "v" }, "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
	},
	opts = {
		keymaps = {
			view = {
				["<C-n>"] = "select_next_entry", -- Next file
				["<C-p>"] = "select_prev_entry", -- Previous file
			},
			file_panel = {
				["j"] = "next_entry", -- Next file
				["k"] = "prev_entry", -- Previous file
				["<cr>"] = "select_entry",
				["q"] = "close",
			},
		},
	},
}

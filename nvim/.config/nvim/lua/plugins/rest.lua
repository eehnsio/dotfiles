return {
	"mistweaverco/kulala.nvim",
	ft = "http",
	keys = {
		{ "<leader>Rs", "<cmd>lua require('kulala').run()<cr>", desc = "Send request", ft = "http" },
		{ "<leader>Rr", "<cmd>lua require('kulala').replay()<cr>", desc = "Replay last request" },
		{ "<leader>Rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle headers/body", ft = "http" },
		{ "<leader>Rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Next request", ft = "http" },
		{ "<leader>Rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Previous request", ft = "http" },
		{ "<leader>Rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Copy as cURL", ft = "http" },
		{ "<leader>Re", "<cmd>lua require('kulala').set_selected_env()<cr>", desc = "Set environment", ft = "http" },
	},
	opts = {},
}

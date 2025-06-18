return {
	"vuki656/package-info.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		-- Setup the plugin
		require("package-info").setup({
			package_manager = "npm",
			hide_up_to_date = true,
		})

		-- Key bindings with descriptions
		local keymap = vim.keymap.set
		local opts = { silent = true, noremap = true }

		-- Show dependency versions
		keymap(
			"n",
			"<LEADER>ns",
			require("package-info").show,
			vim.tbl_extend("force", opts, { desc = "Show dependency versions" })
		)

		-- Hide dependency versions
		keymap(
			"n",
			"<LEADER>nc",
			require("package-info").hide,
			vim.tbl_extend("force", opts, { desc = "Hide dependency versions" })
		)

		-- Toggle dependency versions
		keymap(
			"n",
			"<LEADER>nt",
			require("package-info").toggle,
			vim.tbl_extend("force", opts, { desc = "Toggle dependency versions" })
		)

		-- Update dependency on the line
		keymap(
			"n",
			"<LEADER>nu",
			require("package-info").update,
			vim.tbl_extend("force", opts, { desc = "Update dependency on the line" })
		)

		-- Delete dependency on the line
		keymap(
			"n",
			"<LEADER>nd",
			require("package-info").delete,
			vim.tbl_extend("force", opts, { desc = "Delete dependency on the line" })
		)

		-- Install a new dependency
		keymap(
			"n",
			"<LEADER>ni",
			require("package-info").install,
			vim.tbl_extend("force", opts, { desc = "Install a new dependency" })
		)

		-- Install a different dependency version
		keymap(
			"n",
			"<LEADER>np",
			require("package-info").change_version,
			vim.tbl_extend("force", opts, { desc = "Change dependency version" })
		)
	end,
}

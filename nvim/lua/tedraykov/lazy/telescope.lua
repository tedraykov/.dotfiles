return {
	{
		"nvim-telescope/telescope.nvim",

		tag = "0.1.8",

		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-live-grep-args.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make", -- required to build the fzf C extension
			},
		},

		config = function()
			local builtin = require("telescope.builtin")
			local telescope = require("telescope")

			telescope.setup({
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			})

			-- Load the extensions
			telescope.load_extension("fzf")

			vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
			vim.keymap.set("n", "<C-p>", builtin.git_files, {})
			vim.keymap.set("n", "<leader>ps", builtin.live_grep, {})
		end,
	},
}

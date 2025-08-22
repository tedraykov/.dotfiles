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
			local lga_actions = require("telescope-live-grep-args.actions")

			telescope.setup({
				pickers = {
					find_files = {
						hidden = true,
					},
				},
				extensions = {
					live_grep_args = {
						auto_quoting = true, -- enable/disable auto-quoting
						-- define mappings, e.g.
						mappings = { -- extend mappings
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
							},
						},
						-- ... also accepts theme settings, for example:
						-- theme = "dropdown", -- use dropdown theme
						-- theme = { }, -- use own theme spec
						-- layout_config = { mirror=true }, -- mirror preview pane
					},
				},
			})

			-- Load the extensions
			telescope.load_extension("fzf")
			telescope.load_extension("live_grep_args")

			vim.keymap.set("n", "<leader>pf", builtin.find_files, {})
			vim.keymap.set("n", "<C-p>", builtin.git_files, {})
			vim.keymap.set("n", "<leader>ps", function()
				telescope.extensions.live_grep_args.live_grep_args()
			end, { desc = "Live grep (with args)" })
		end,
	},
}

return {
	"hedyhli/outline.nvim",
	keys = { -- Example mapping to toggle outline
		{ "<leader>e", "<cmd>Outline<CR>", desc = "Toggle outline" },
	},
	lazy = true,
	config = function()
		require("outline").setup({
			keymaps = {
				up_and_jump = "<C-l>",
				down_and_jump = "<C-k>",
				fold = "j",
				unfold = ";",
			},
		})
	end,
}

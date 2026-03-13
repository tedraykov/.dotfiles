return {
	"navarasu/onedark.nvim",
	config = function()
		require("onedark").setup({
			style = "warmer",
			transparent = true,
			term_colors = true,
		})
		require("onedark").load()
	end,
}

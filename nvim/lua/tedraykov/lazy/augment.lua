return {
	"augmentcode/augment.vim",
	init = function()
		vim.g.augment_workspace_folders = {
			"~/dev/redis/Redis-Enterprise",
			"~/dev/personal/dotfiles",
		}

		-- If Tab conflicts with another plugin, enable this:
		-- vim.g.augment_disable_tab_mapping = true
		-- vim.keymap.set("i", "<C-y>", "<cmd>call augment#Accept()<CR>", { silent = true })
	end,
}

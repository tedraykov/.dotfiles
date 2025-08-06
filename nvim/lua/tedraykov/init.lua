require("tedraykov.remap")
require("tedraykov.set")
require("tedraykov.lazy_init")

local augroup = vim.api.nvim_create_augroup
local tedGroup = augroup("tedraykov", {})

local autocmd = vim.api.nvim_create_autocmd

function R(name)
	require("plenary.reload").reload_module(name)
end

vim.filetype.add({
	extension = {
		templ = "templ",
	},
})

autocmd({ "BufWritePre" }, {
	group = tedGroup,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

vim.g.mapleader = " "

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- paste the system clipboard when pressing <leader>xp
vim.keymap.set("n", "<leader>xp", '"+p')

-- This is going to get me cancelled
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>ch", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>") -- exit terminal mode

--- Remap navigation keys
vim.keymap.set("n", "h", ";")
vim.keymap.set("n", ";", "l")
vim.keymap.set("n", "l", "k")
vim.keymap.set("n", "k", "j")
vim.keymap.set("n", "j", "h")
vim.keymap.set("v", ";", "l")
vim.keymap.set("v", "l", "k")
vim.keymap.set("v", "k", "j")
vim.keymap.set("v", "j", "h")
vim.api.nvim_set_keymap("n", "$", "^", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "^", "$", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "$", "^", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "^", "$", { noremap = true, silent = true })

-- Remap windows split navigation keys
vim.keymap.set("n", "<C-w>;", "<C-w>l")
vim.keymap.set("n", "<C-w>l", "<C-w>k")
vim.keymap.set("n", "<C-w>k", "<C-w>j")
vim.keymap.set("n", "<C-w>j", "<C-w>h")

function OpenInFinder()
	local file_path = vim.fn.expand("%:p")
	os.execute("open -R " .. file_path)
end

vim.api.nvim_create_user_command("OpenFinder", OpenInFinder, {})

vim.keymap.set("n", "<leader>of", ":OpenFinder<CR>")

local function copy_path(path)
	vim.fn.setreg("+", path)
	print("Copied: " .. path)
end

vim.keymap.set("n", "<leader>cp", function()
	local path = vim.fn.expand("%:p")
	local session_path

	if vim.env.TMUX then
		local result = vim.system({ "tmux", "display-message", "-p", "-F", "#{session_path}" }, { text = true }):wait()
		if result.code == 0 then
			session_path = vim.trim(result.stdout)
		end
	end

	local relative_path = vim.fs.relpath(session_path or vim.fn.getcwd(), path)
	copy_path(relative_path or path)
end, { desc = "Copy path relative to tmux session to clipboard" })

vim.keymap.set("n", "<leader>cP", function()
	local path = vim.fn.expand("%:p")
	copy_path(path)
end, { desc = "Copy full path to clipboard" })

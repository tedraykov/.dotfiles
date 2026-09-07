-- The appearance is explicit: it follows ~/.config/appearance, written by the
-- `appearance` script, never the macOS system appearance.
local function read_appearance()
	local ok, lines = pcall(vim.fn.readfile, vim.fn.expand("~/.config/appearance"))
	local value = ok and lines[1] and vim.trim(lines[1]) or nil

	return value == "light" and "light" or "dark"
end

return {
	"navarasu/onedark.nvim",
	config = function()
		local onedark = require("onedark")

		local function apply()
			local appearance = read_appearance()

			onedark.setup({
				style = appearance == "light" and "light" or "warmer",
				transparent = true,
				term_colors = true,
			})
			vim.o.background = appearance
			onedark.load()
		end

		apply()

		-- `appearance` sends SIGUSR1 so running instances repaint on a switch.
		vim.api.nvim_create_autocmd("Signal", {
			pattern = "SIGUSR1",
			callback = apply,
		})
	end,
}

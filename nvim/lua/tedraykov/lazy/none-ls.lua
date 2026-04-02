return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
		"nvim-lua/plenary.nvim",
		"ThePrimeagen/refactoring.nvim",
	},
	config = function()
		local null_ls = require("null-ls")
		local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

		-- Add a global flag (default = true)
		local format_on_save = true

		-- Add a command to toggle formatting
		vim.api.nvim_create_user_command("ToggleFormatOnSave", function()
			format_on_save = not format_on_save
			print("Format on save: " .. tostring(format_on_save))
		end, {})

		local prettier_config_filenames = {
			".prettierrc",
			".prettierrc.json",
			".prettierrc.yml",
			".prettierrc.yaml",
			".prettierrc.json5",
			".prettierrc.js",
			".prettierrc.cjs",
			".prettierrc.mjs",
			".prettierrc.toml",
			"prettier.config.js",
			"prettier.config.cjs",
			"prettier.config.mjs",
			".graphqlrc.yml",
			".graphqlrc.yaml",
		}

		local eslint_config_filenames = {
			".eslintrc",
			".eslintrc.js",
			".eslintrc.cjs",
			".eslintrc.yaml",
			".eslintrc.yml",
			".eslintrc.json",
		}

		null_ls.setup({
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
					vim.api.nvim_create_autocmd("BufWritePre", {
						group = augroup,
						buffer = bufnr,
						callback = function()
							if not format_on_save then
								return
							end

							vim.lsp.buf.format({
								async = false,
								timeout_ms = 2000,
							})
						end,
					})
				end
			end,
			sources = {
				-- Python
				null_ls.builtins.diagnostics.mypy,
				-- null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.black.with({
					extra_args = { "--line-length", "120" },
					timeout = 5000,
				}),
				-- JavaScript
				require("none-ls.diagnostics.eslint_d").with({
					condition = function(utils)
						return utils.root_has_file(eslint_config_filenames)
					end,
				}),
				require("none-ls.code_actions.eslint_d").with({
					condition = function(utils)
						return utils.root_has_file(eslint_config_filenames)
					end,
				}),
				require("none-ls.formatting.eslint_d").with({
					condition = function(utils)
						return utils.root_has_file(eslint_config_filenames)
					end,
				}),
				null_ls.builtins.formatting.prettierd.with({
					condition = function(utils)
						return utils.root_has_file(prettier_config_filenames)
					end,
				}),
				-- Go
				null_ls.builtins.diagnostics.golangci_lint,
				null_ls.builtins.formatting.goimports,
				null_ls.builtins.formatting.gofmt,
				-- JSON
				require("none-ls.formatting.jq"),
				-- General
				null_ls.builtins.code_actions.refactoring,
				null_ls.builtins.formatting.stylua,
			},
			should_attach = function(bufnr)
				local name = vim.api.nvim_buf_get_name(bufnr) or ""
				if name:match("^fugitive://") then
					return false
				end
				return true
			end,
		})
	end,
}

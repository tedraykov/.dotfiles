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
							vim.lsp.buf.format({ async = false })
						end,
					})
				end
			end,
			sources = {
				-- Python
				null_ls.builtins.diagnostics.mypy,
				-- null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.black,
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
				-- JSON
				require("none-ls.formatting.jq"),
				-- General
				null_ls.builtins.code_actions.refactoring,
				null_ls.builtins.formatting.stylua,
			},
		})
	end,
}

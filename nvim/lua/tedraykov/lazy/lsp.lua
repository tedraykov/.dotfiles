return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"j-hui/fidget.nvim",
	},
	config = function()
		require("fidget").setup({})
		local lspconfig = require("lspconfig")

		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				local keymap = vim.keymap

				opts.desc = "Show LSP references"
				keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ga", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>gr", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

				opts.desc = "Show line diagnostics"
				keymap.set("n", "gl", vim.diagnostic.open_float, opts) -- show diagnostics for line

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		local capabilities = cmp_nvim_lsp.default_capabilities()

		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"svelte",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"pyright",
				"bashls",
				"cmake",
				"docker_compose_language_service",
				"dockerls",
				"gopls",
				"helm_ls",
				"terraformls",
				"yamlls",
			},
			handlers = {
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,

				["ts_ls"] = function()
					local util = require("lspconfig.util")

					lspconfig.ts_ls.setup({
						handlers = {
							["textDocument/publishDiagnostics"] = function(_, result, ctx)
								if not result.diagnostics then
									return
								end

								-- ignore some ts_ls diagnostics
								local idx = 1
								while idx <= #result.diagnostics do
									local entry = result.diagnostics[idx]

									local formatter = require("format-ts-errors")[entry.code]
									entry.message = formatter and formatter(entry.message) or entry.message

									-- codes: https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
									if entry.code == 80001 then
										-- { message = "File is a CommonJS module; it may be converted to an ES module.", }
										table.remove(result.diagnostics, idx)
									else
										idx = idx + 1
									end
								end

								vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx)
							end,
						},
						capabilities = capabilities,
						settings = {
							completions = {
								completeFunctionCalls = true,
							},
						},
						root_dir = function(fname)
							-- Prevent ts_ls from attaching to Deno projects
							if util.root_pattern("deno.json", "deno.jsonc")(fname) then
								return nil
							end
							return util.root_pattern("package.json")(fname)
						end,
						single_file_support = false,
					})
				end,

				["svelte"] = function()
					lspconfig.svelte.setup({
						capabilities = capabilities,
					})
				end,

				-- ["denols"] = function()
				-- 	local util = require("lspconfig.util")
				--
				-- 	lspconfig.denols.setup({
				-- 		capabilities = capabilities,
				-- 		root_dir = util.root_pattern("deno.json", "deno.jsonc"),
				-- 	})
				-- end,

				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								runtime = { version = "Lua 5.1" },
								diagnostics = {
									globals = { "vim", "it", "describe", "before_each", "after_each" },
								},
							},
						},
					})
				end,

				-- ["yamlls"] = function()
				-- 	lspconfig.yamlls.setup({
				-- 		filetypes = { "yaml" },
				-- 		on_attach = function(client, bufnr)
				-- 			local filename = vim.api.nvim_buf_get_name(bufnr)
				-- 			if filename:match("/templates/") or filename:match("Chart%.yaml$") then
				-- 				print("Detaching yamlls for file:", filename)
				-- 				if vim.lsp.buf_is_attached(bufnr, client.id) then
				-- 					local clients = vim.lsp.get_active_clients({ buffer = bufnr })
				-- 					print("Active clients:", vim.inspect(clients))
				-- 					vim.lsp.buf_detach_client(0, client.id)
				-- 				else
				-- 					print("yamlls was not attached to buffer:", bufnr)
				-- 				end
				-- 			end
				-- 		end,
				-- 		capabilities = capabilities,
				-- 	})
				-- end,
				--
				["helm_ls"] = function()
					lspconfig.helm_ls.setup({
						capabilities = capabilities,
						settings = {
							["helm-ls"] = {
								yamlls = {
									path = "yaml-language-server",
								},
							},
						},
					})
				end,
			},
		})

		lspconfig.dartls.setup({
			capabilities = capabilities,
			cmd = { "dart", "language-server", "--protocol=lsp" },
			filetypes = { "dart" },
			init_options = {
				closingLabels = true,
				onlyAnalyzeProjectsWithOpenFiles = true,
				suggestFromUnimportedLibraries = true,
			},
		})

		lspconfig.graphql.setup({
			capabilities = capabilities,
			filetypes = { "graphql", "graphqls", "typescriptreact", "javascriptreact" },
			root_dir = lspconfig.util.root_pattern("package.json", ".git"),
		})

		require("mason-tool-installer").setup({
			ensure_installed = {
				"prettierd",
				"stylua",
				"isort",
				"pylint",
				"eslint_d",
				"flake8",
			},
		})

		vim.diagnostic.config({
			virtual_text = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})
	end,
}

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"mfussenegger/nvim-dap-python",
			"leoluz/nvim-dap-go",
			"theHamsta/nvim-dap-virtual-text",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local dap_python = require("dap-python")
			local dap_go = require("dap-go")

			-- Enable verbose logging for debugging
			dap.set_log_level("INFO") -- Change to 'TRACE' for more details

			-- ============================================================
			-- UI SETUP
			-- ============================================================
			require("dapui").setup({
				layouts = {
					{
						-- Left panel (typical)
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						size = 40,
						position = "left",
					},
					{
						position = "bottom",
						size = 20,
						elements = {
							{ id = "console", size = 1 },
						},
					},
				},
				controls = {
					enabled = true,
					element = "console",
				},
			})
			require("nvim-dap-virtual-text").setup({
				commented = true, -- Show virtual text alongside comment
			})

			-- ============================================================
			-- HELPER FUNCTIONS
			-- ============================================================
			-- Helper: prefer git root as local project root when available
			local function project_root()
				local git = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
				if git and #git > 0 and vim.v.shell_error == 0 then
					return git
				end
				return vim.fn.getcwd()
			end

			local function poetry_python()
				-- falls back to "python" if Poetry not available
				local ok, venv_path = pcall(function()
					return vim.fn.systemlist("poetry env info -p")[1]
				end)
				if ok and venv_path and #venv_path > 0 then
					local sep = package.config:sub(1, 1) == "\\" and "\\" or "/"
					return venv_path .. sep .. "bin" .. sep .. "python"
				end
				return "python"
			end

			-- ============================================================
			-- CONFIGURATION MAP
			-- ============================================================
			local dap_configs = {
				python = {
					attach_container = {
						type = "python",
						request = "attach",
						name = "Python Attach: container (debugpy)",
						connect = function()
							local port_string = vim.fn.input("Port [5678]: ")
							local port = port_string ~= "" and tonumber(port_string) or 5678
							return { host = "127.0.0.1", port = port }
						end,
						justMyCode = false,
						pathMappings = function()
							local remote_path = vim.fn.input("Remote path [/workspace]: ")
							local path = remote_path ~= "" and remote_path or "/workspace"
							return {
								{
									localRoot = project_root(),
									remoteRoot = path,
								},
							}
						end,
					},
				},
				go = {
					debug_file = {
						type = "go",
						name = "Debug current file (local)",
						request = "launch",
						program = "${file}",
					},
					debug_package = {
						type = "go",
						name = "Debug current package (local)",
						request = "launch",
						program = "${fileDirname}",
					},
					debug_with_args = {
						type = "go",
						name = "Debug with arguments (local)",
						request = "launch",
						program = "${fileDirname}",
						args = function()
							local args_string = vim.fn.input("Arguments: ")
							return vim.split(args_string, " +")
						end,
					},
					attach_remote = {
						type = "go",
						name = "Go Attach: container (delve)",
						mode = "remote",
						request = "attach",
						host = "127.0.0.1",
						port = function()
							local port_string = vim.fn.input("Port [2345]: ")
							local port = port_string ~= "" and tonumber(port_string) or 2345
							return port
						end,
						substitutePath = function()
							local remote_path = vim.fn.input("Remote path [/workspace]: ")
							local path = remote_path ~= "" and remote_path or "/workspace"
							return {
								{
									from = project_root(),
									to = path,
								},
							}
						end,
					},
				},
			}

			-- ============================================================
			-- PYTHON SETUP
			-- ============================================================
			dap_python.setup(poetry_python())
			table.insert(require("dap").configurations.python, {
				justMyCode = false,
			})
			table.insert(require("dap").configurations.python, dap_configs.python.attach_container)

			dap_python.test_runner = "pytest"

			-- ============================================================
			-- GO SETUP
			-- ============================================================
			-- Adapter for REMOTE Delve (connects to existing DAP server in container)
			-- This does NOT launch a local dlv - it connects directly to the port
			dap.adapters.go = function(callback, config)
				if config.mode == "remote" then
					callback({
						type = "server",
						host = config.host or "127.0.0.1",
						port = config.port,
					})
				else
					-- For local debugging, use the default delve adapter
					local handle
					local pid_or_err
					local port = 38697
					local opts = {
						args = { "dap", "-l", "127.0.0.1:" .. port },
						detached = true,
					}
					handle, pid_or_err = vim.loop.spawn("dlv", opts, function(code)
						handle:close()
					end)
					if not handle then
						vim.notify("Error launching delve: " .. tostring(pid_or_err), vim.log.levels.ERROR)
						return
					end
					vim.defer_fn(function()
						callback({ type = "server", host = "127.0.0.1", port = port })
					end, 100)
				end
			end

			dap_go.setup({
				-- Additional dap configurations can be added.
				dap_configurations = {
					dap_configs.go.debug_file,
					dap_configs.go.debug_package,
					dap_configs.go.debug_with_args,
					dap_configs.go.attach_remote,
				},
				-- delve configurations for LOCAL debugging
				delve = {
					path = "dlv",
					initialize_timeout_sec = 20,
					port = "${port}",
					args = {},
					build_flags = "",
				},
			})

			-- ============================================================
			-- DAP UI AUTO OPEN/CLOSE
			-- ============================================================
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

			-- ============================================================
			-- BREAKPOINT SIGNS
			-- ============================================================
			local sign = vim.fn.sign_define
			sign("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
			sign("DapBreakpointCondition", { text = "●", texthl = "DiagnosticWarn" })
			sign("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
			sign("DapStopped", { text = "", texthl = "DiagnosticOk" })

			-- ============================================================
			-- HELPER FUNCTIONS
			-- ============================================================
			local function get_filetype()
				return vim.bo.filetype
			end

			-- ============================================================
			-- KEYMAPS
			-- ============================================================
			local opts = { noremap = true, silent = true }
			-- Toggle breakpoint
			vim.keymap.set("n", "<leader>db", function()
				dap.toggle_breakpoint()
			end, opts)
			-- Continue / Start
			vim.keymap.set("n", "<leader>dc", function()
				dapui.open()
				dap.continue()
			end, opts)
			-- Step Over
			vim.keymap.set("n", "<leader>do", function()
				dap.step_over()
			end, opts)
			-- Step Into
			vim.keymap.set("n", "<leader>di", function()
				dap.step_into()
			end, opts)
			-- Step Out
			vim.keymap.set("n", "<leader>dO", function()
				dap.step_out()
			end, opts)
			-- Terminate debugging
			vim.keymap.set("n", "<leader>dq", function()
				require("dap").terminate()
			end, opts)
			-- Toggle DAP UI
			vim.keymap.set("n", "<leader>du", function()
				dapui.toggle()
			end, opts)

			-- ============================================================
			-- TEST DEBUGGING (language-aware)
			-- ============================================================
			-- Debug test under cursor
			vim.keymap.set("n", "<leader>dt", function()
				local ft = get_filetype()
				dapui.open()
				dapui.float_element("console", { enter = true })
				if ft == "python" then
					require("dap-python").test_method()
				elseif ft == "go" then
					require("dap-go").debug_test()
				else
					vim.notify("No test debugging support for filetype: " .. ft, vim.log.levels.WARN)
				end
			end, opts)
			-- Debug test class/file
			vim.keymap.set("n", "<leader>df", function()
				local ft = get_filetype()
				dapui.open()
				dapui.float_element("console", { enter = true })
				if ft == "python" then
					require("dap-python").test_class()
				elseif ft == "go" then
					require("dap-go").debug_test()
				else
					vim.notify("No test debugging support for filetype: " .. ft, vim.log.levels.WARN)
				end
			end, opts)
			-- Debug last test
			vim.keymap.set("n", "<leader>dl", function()
				local ft = get_filetype()
				dapui.open()
				dapui.float_element("console", { enter = true })
				if ft == "python" then
					require("dap-python").test_method()
				elseif ft == "go" then
					require("dap-go").debug_last_test()
				else
					vim.notify("No test debugging support for filetype: " .. ft, vim.log.levels.WARN)
				end
			end, opts)
			vim.keymap.set("n", "<leader>da", function()
				local ft = get_filetype()
				dapui.open()
				if ft == "python" then
					dap.run(dap_configs.python.attach_container)
				elseif ft == "go" then
					dap.run(dap_configs.go.attach_remote)
				else
					vim.notify("No attach support for filetype: " .. ft, vim.log.levels.WARN)
				end
			end, opts)
		end,
	},
}

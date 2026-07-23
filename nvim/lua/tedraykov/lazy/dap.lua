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
			-- Find the Python project for the current buffer.  The Git root is not
			-- sufficient here because this repository is a monorepo and contains both
			-- Poetry projects and legacy setup.py/pytest.ini projects.
			local function project_root()
				local file = vim.api.nvim_buf_get_name(0)
				local dir = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
				local current = vim.fs.normalize(dir)

				while current and current ~= "" do
					if
						vim.uv.fs_stat(current .. "/pyproject.toml")
						or vim.uv.fs_stat(current .. "/setup.py")
						or vim.uv.fs_stat(current .. "/pytest.ini")
					then
						return current
					end

					local parent = vim.fs.dirname(current)
					if parent == current then
						break
					end
					current = parent
				end

				return vim.fn.getcwd()
			end

			local function poetry_python()
				local root = project_root()
				local sep = package.config:sub(1, 1) == "\\" and "\\" or "/"
				local local_python = root .. sep .. ".venv" .. sep .. "bin" .. sep .. "python"
				if vim.uv.fs_stat(local_python) then
					return local_python
				end

				local venv_path = vim.fn.systemlist({ "poetry", "-C", root, "env", "info", "-p" })[1]
				if vim.v.shell_error == 0 and venv_path and #venv_path > 0 then
					return venv_path .. sep .. "bin" .. sep .. "python"
				end
				return "python"
			end

			local function python_test_config()
				local root = project_root()
				return {
					cwd = root,
					pythonPath = poetry_python(),
				}
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
							local port_string = vim.fn.input("Port [5678]: ")
							local port = port_string ~= "" and tonumber(port_string) or 5678
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
			-- Keep the DAP adapter separate from the project interpreter.  This project
			-- contains the obsolete `typing` backport, which shadows Python 3.11's
			-- stdlib typing module when debugpy is launched from the Poetry venv.
			-- The test process itself still uses the project interpreter below.
			dap_python.resolve_python = poetry_python
			dap_python.setup("debugpy-adapter")
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
					require("dap-python").test_method({ config = python_test_config() })
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
					require("dap-python").test_class({ config = python_test_config() })
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
					require("dap-python").test_method({ config = python_test_config() })
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

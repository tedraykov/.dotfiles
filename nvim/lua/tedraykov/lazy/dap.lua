return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"rcarriga/nvim-dap-ui",
			"mfussenegger/nvim-dap-python",
			"theHamsta/nvim-dap-virtual-text",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			local dap_python = require("dap-python")

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

			-- helper: prefer git root as local project root when available
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

			dap_python.setup(poetry_python())
			table.insert(require("dap").configurations.python, {
				justMyCode = false,
			})

			dap_python.test_runner = "pytest"

      local sign = vim.fn.sign_define

      sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = ""})
      sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = ""})
      sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = ""})
      sign('DapStopped', { text='', texthl='DapStopped', linehl='DapStopped', numhl= 'DapStopped' })

			table.insert(dap.configurations.python, {
				type = "python",
				request = "attach",
				name = "Attach: container (debugpy)",
				connect = { host = "127.0.0.1", port = 5678 }, -- forwarded from container
				justMyCode = false,
				pathMappings = {
					{
						localRoot = project_root(), -- your local repo root
						remoteRoot = "/workspace",
					},
				},
			})

			-- Automatically open/close DAP UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end

			local opts = { noremap = true, silent = true }

			-- Toggle breakpoint
			vim.keymap.set("n", "<leader>db", function()
				dap.toggle_breakpoint()
			end, opts)

			-- Continue / Start
			vim.keymap.set("n", "<leader>dc", function()
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

			-- Keymap to terminate debugging
			vim.keymap.set("n", "<leader>dq", function()
				require("dap").terminate()
			end, opts)

			-- Toggle DAP UI
			vim.keymap.set("n", "<leader>du", function()
				dapui.toggle()
			end, opts)

			-- Pytest file
			vim.keymap.set("n", "<leader>dm", function()
				require("dap-python").test_method()
			end, opts)

			-- Run tests in current file
			vim.keymap.set("n", "<leader>df", function()
				require("dap-python").test_file()
			end, opts)

			vim.keymap.set("n", "<leader>da", function()
				dap.run({
					type = "python",
					request = "attach",
					name = "Attach: container (debugpy)",
					connect = { host = "127.0.0.1", port = 5678 },
					justMyCode = false,
					pathMappings = {
						{ localRoot = project_root(), remoteRoot = "/workspace" },
					},
				})
			end, opts)
		end,
	},
}

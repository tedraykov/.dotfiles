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

      require("dapui").setup({})
      require("nvim-dap-virtual-text").setup({
        commented = true, -- Show virtual text alongside comment
      })

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
      dap_python.test_runner = "pytest"
      dap.configurations.python = dap.configurations.python or {}

      vim.fn.sign_define("DapBreakpoint", {
        text = "",
        texthl = "DiagnosticSignError",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapBreakpointRejected", {
        text = "", -- or "❌"
        texthl = "DiagnosticSignError",
        linehl = "",
        numhl = "",
      })

      vim.fn.sign_define("DapStopped", {
        text = "", -- or "→"
        texthl = "DiagnosticSignWarn",
        linehl = "Visual",
        numhl = "DiagnosticSignWarn",
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
      vim.keymap.set("n", "<leader>dt", function()
        dap.run({
          type = "python",
          request = "launch",
          name = "Pytest: current file",
          module = "pytest",
          args = { vim.fn.expand("%") },
          justMyCode = false,
          console = "integratedTerminal",
        })
      end, opts)
    end,
  },
}

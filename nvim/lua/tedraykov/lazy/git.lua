return {
  {
    "tpope/vim-fugitive",
    config = function()
      local function focus_worktree_diff_window()
        vim.schedule(function()
          local target_win = nil

          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            local name = vim.api.nvim_buf_get_name(buf)

            if
              vim.api.nvim_win_get_option(win, "diff")
              and vim.bo[buf].buftype == ""
              and not name:match("^fugitive://")
            then
              target_win = win
              break
            end
          end

          if target_win and vim.api.nvim_win_is_valid(target_win) then
            vim.api.nvim_set_current_win(target_win)
          end
        end)
      end

      vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
      vim.keymap.set("n", "gf", "<cmd>diffget //2<cr>")
      vim.keymap.set("n", "gj", "<cmd>diffget //3<cr>")
      vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>")
      vim.keymap.set("n", "<leader>gl", "<cmd>Git pull --rebase<cr>")
      vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>")

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TedFugitiveWorktreeDiff", { clear = true }),
        pattern = "fugitive",
        callback = function(event)
          vim.keymap.set("n", "dd", function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>fugitive:dd", true, false, true), "mx", false)
            focus_worktree_diff_window()
          end, { buffer = event.buf, desc = "Diff file and focus worktree" })

          vim.keymap.set("n", "dv", function()
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>fugitive:dv", true, false, true), "mx", false)
            focus_worktree_diff_window()
          end, { buffer = event.buf, desc = "Vertical diff file and focus worktree" })
        end,
      })
    end,
  },
  {
    "airblade/vim-gitgutter",
  },
}

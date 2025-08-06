return {
  {
    "tpope/vim-fugitive",
    config = function()
      vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
      vim.keymap.set("n", "gf", "<cmd>diffget //2<cr>")
      vim.keymap.set("n", "gj", "<cmd>diffget //3<cr>")
      vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>")
      vim.keymap.set("n", "<leader>gl", "<cmd>Git pull --rebase<cr>")
      vim.keymap.set("n", "<leader>gb", "<cmd>Git blame<cr>")
    end,
  },
  {
    "airblade/vim-gitgutter",
  },
}

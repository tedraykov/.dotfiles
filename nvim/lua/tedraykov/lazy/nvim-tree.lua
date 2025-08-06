return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- set termguicolors to enable highlight groups
    vim.opt.termguicolors = true

    local function my_on_attach(bufnr)
      local api = require("nvim-tree.api")

      -- default mappings
      api.config.mappings.default_on_attach(bufnr)

      local function find_file_toggle()
        api.tree.toggle({ find_file = true }) -- replace with actual arguments
      end

      -- custom mappings
      vim.keymap.set("n", "<leader>t", find_file_toggle)
    end

    -- OR setup with some options
    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      on_attach = my_on_attach,
      view = {
        width = 40,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false,
      },
    })
  end,
}

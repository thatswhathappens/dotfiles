-- Portable hand-written re-implementation of system/nvim.nix (which used the
-- Nix-only `nvf` framework). nvf has no non-Nix equivalent, so this is a
-- best-effort translation to plain lazy.nvim -- expect to tweak keymaps and
-- defaults, since nvf silently supplies a lot of opinionated wiring that
-- isn't reproduced here.
--
-- Requires: neovim, git, a C compiler (for treesitter), and for full
-- LSP support: clangd (languages.clang) and texlab (languages.tex).

vim.g.mapleader = " "
vim.opt.showmode = false          -- settings.vim.options.showmode = false
vim.opt.number = true             -- lineNumberMode = "number"
vim.opt.relativenumber = false

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- languages.clang.enable / languages.tex.enable -> lsp.enable
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.clangd.setup({})   -- languages.clang
      lspconfig.texlab.setup({})   -- languages.tex
    end,
  },

  -- languages.html.enable + languages.nix.enable, both with treesitter.enable
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "html", "nix" },
        highlight = { enable = true },
      })
    end,
  },

  -- tabline.nvimBufferline.enable
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("bufferline").setup({}) end,
  },

  -- statusline.lualine.enable
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("lualine").setup({}) end,
  },

  -- autopairs.nvim-autopairs.enable
  {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup({}) end,
  },

  -- visuals.indent-blankline.enable
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function() require("ibl").setup({}) end,
  },

  -- autocomplete.blink-cmp.enable
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {},
  },

  -- ui.noice.enable
  {
    "folke/noice.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    config = function() require("noice").setup({}) end,
  },

  -- presence.cord-nvim.enable, setupOpts = { idle.enabled = false }
  {
    "vyfor/cord.nvim",
    build = ":Cord update",
    opts = {
      idle = { enabled = false },
    },
  },
})

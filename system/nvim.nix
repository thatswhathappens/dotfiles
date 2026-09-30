{ ... }:
{
  programs.nvf = {
    enable = true;

    settings.vim = {
      options = { showmode = false; };
      lineNumberMode = "number";

      lsp.enable = true;

      languages.clang.enable = true;
      languages.tex.enable=true;

      languages.html.enable = true;
      languages.html.treesitter.enable = true;

      languages.nix.enable = true;
      languages.nix.treesitter.enable = true;

      tabline.nvimBufferline.enable = true;
      statusline.lualine.enable = true;
      autopairs.nvim-autopairs.enable = true;
      visuals.indent-blankline.enable = true;
      autocomplete.blink-cmp.enable = true;
      ui.noice.enable = true;

      presence.cord-nvim.enable = true;
      presence.cord-nvim.setupOpts = { idle.enabled = false; };
    };
  };
}

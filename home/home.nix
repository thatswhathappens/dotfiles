{ config, pkgs, inputs, ... }:

{
  imports = [
    ./noctalia.nix
    ./kitty.nix
    ./mango.nix
   #./doom-emacs.nix
  ];

  home.username = "ethan";
  home.homeDirectory = "/home/ethan";
  home.stateVersion = "26.11";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # CLI / terminal
    asciinema
    alacritty
    btop
    claude-code
    eza
    fastfetch
    fzf
    gh
    htop
    kitty
    nnn
    pfetch
    tex-fmt
    texlivePackages.chktex 


    # Development
    bun
    libclang
    nil
    nodejs
    superhtml
    texliveMedium
    vscode

    # Media & creative
    kdePackages.kolourpaint
    krita
    mpv
    obs-studio
    vlc

    # Gaming
    archipelago
    cataclysm-dda
    ckan
    dolphin-emu
    mgba
    openttd
    prismlauncher
    uzdoom
    vintagestory
    dolphin-emu
    wheelwizard

    # Communication
    vesktop
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 2";
    flake = "/etc/nixos";
  };

  programs.starship = {
    enable = true;
    presets = [
      "nerd-font-symbols"
      "no-runtime-versions"
    ];
  };

  programs.lazygit.enable = true;

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --color=auto --icons=always";
      cd = "z";
      rebuild = "nh os switch --update /etc/nixos";
      cleanup = "nh clean all";
      q = "exit";
    };
  };
}

{ config, pkgs, inputs, attrs, ... }:
{
  # --- User account ---
  users.users."ethan" = {
    isNormalUser = true;
    description = "Ethan";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
  };

  # --- Desktop / session ---
  programs.mango.enable = true;
  zramSwap.enable = true;
  zramSwap.algorithm = "lz4";

  xdg = {
    portal = {
      enable = true;
      wlr = {
        enable = true;
        settings = {
          screencast = {
            chooser_type = "simple";
            chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
          };
        };
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.iosevka
    nerd-fonts.caskaydia-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.bigblue-terminal
    nerd-fonts.departure-mono
    envypn-font
    ibm-plex
    open-sans
  ];


  boot = {
    plymouth = {
      enable = true;
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];

    #loader.timeout = 0;
   };
  

  # --- Package management ---
  services.flatpak.enable = true;
  programs.nix-index-database.comma.enable = true;
  virtualisation.podman.enable = true;
  environment.systemPackages = with pkgs; [ distrobox ];

  # --- Gaming ---
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };
}

{ inputs, ... }:

{
  imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

  programs.doom-emacs = {
    enable = true;
    doomDir = ../forth/doom.d;
  };
}

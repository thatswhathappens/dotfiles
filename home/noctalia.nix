{ config, pkgs, ...}:

{
 programs.noctalia = {
  enable = true;
  settings = ../forth/noctalia.toml;
 };
}

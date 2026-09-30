# Portable export of this NixOS config

Generated so this setup can be rebuilt on a non-NixOS distro. Everything here
is a plain, native config file or a plain-text package list -- nothing
depends on Nix.

## What's already native (just copy into place)

These were only ever thin Nix wrappers around real config files, so the
files here are byte-identical to what's live on disk today:

| File here | Copy to |
|---|---|
| `config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `config/kitty/kitty_dd.conf` | `~/.config/kitty/kitty_dd.conf` |
| `config/mango/config.conf` | `~/.config/mango/config.conf` |
| `config/noctalia/config.toml` | `~/.config/noctalia/config.toml` |
| `config/starship.toml` | `~/.config/starship.toml` |

## What had to be rewritten

- `shell/bashrc` -> `~/.bashrc` -- Home Manager generated this from
  `programs.bash`/`programs.starship`/`programs.zoxide` in `home/home.nix`,
  substituting in `/nix/store/...` binary paths. Rewritten here to call
  `starship`/`zoxide`/`lazygit` by plain name, so they just need to be on
  `$PATH`.
- `shell/bash_profile` -> `~/.bash_profile` -- trivial, no Nix-specific bits.
- `config/nvim/init.lua` -> `~/.config/nvim/init.lua` -- `system/nvim.nix`
  used `nvf`, a Nix-only neovim framework with no non-Nix equivalent. This is
  a hand-written `lazy.nvim` config aiming to cover the same plugins
  (clangd/texlab LSP, treesitter for html/nix, bufferline, lualine,
  autopairs, indent-blankline, blink.cmp, noice.nvim, cord.nvim). Treat it as
  a starting point, not a guaranteed match -- nvf fills in a lot of default
  wiring and keymaps that aren't reproduced here.

## Not exported

- Doom Emacs (`home/doom-emacs.nix`) -- currently commented out/inactive in
  both `home/home.nix` and `flake.nix`, so there was nothing live to export.
- System-level settings (firewall ports, bluetooth tuning, NVIDIA env vars,
  zram, boot/plymouth, xdg-portal config, locale/timezone, user groups,
  etc.) from `configuration.nix`, `system/nvidia.nix`, and `system/user.nix`
  -- skipped per request. Re-check that file when you rebuild if you want
  those tuned the same way again.

## Packages

- `packages/arch-pacman.txt` -- everything with a confident official Arch
  repo match.
- `packages/aur-or-manual.txt` -- niche/gaming/font packages that likely need
  AUR or a manual build; names are starting search terms, not guarantees.
- `packages/drop-nix-only.txt` -- Nix/NixOS-only tooling (home-manager, nvf,
  nh, comma, colmena, etc.) with nothing to reproduce once you're off Nix.

These lists were derived from `configuration.nix`, `system/user.nix`, and
`home/home.nix` and assume an Arch-based target; swap in Debian/Fedora
package names where you actually land.

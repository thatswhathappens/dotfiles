# Rebuilding Ethan's desktop on CachyOS

This file is a brief for a Claude running on a **fresh CachyOS install**. Your
job is to turn that install into something Ethan would recognise as the NixOS
desktop this repo describes: same compositor, shell, login screen, terminal,
keybinds, fonts, colours, apps, and system tuning.

It was written on 2026-10-01 from the NixOS machine itself, shortly before the
switch. Facts marked **(observed)** were read off the running system. Package
names marked **(verify)** are best guesses; check them with `pacman -Si` /
`paru -Si` before installing, because you can query the real repos and the
author of this file could not.

## How to use this file

1. Ethan clones this repo on the new install (anywhere; `~/dotfiles` is assumed
   below and called `$REPO`).
2. Work through the phases in order. Each phase ends with a check. Do not move
   on while a check fails.
3. Things only Ethan can decide are collected in
   [Questions for Ethan](#questions-for-ethan). Ask them up front in one batch,
   then carry on with everything that does not depend on the answers.

The Nix files (`configuration.nix`, `system/*.nix`, `home/*.nix`) are the
source of truth for *what the system was*. `portable/` holds the plain,
Nix-free files you actually copy into place. `forth/` is the Nix-side copy of
the same dotfiles and is byte-identical to `portable/config/`; ignore it.

## The machine being reproduced (observed)

| | |
|---|---|
| Hostname | `happyhomedesigner` |
| User | `ethan` (uid 1000), description "Ethan"; admin, libvirt access |
| CPU / RAM | AMD Ryzen 5 5500, 16 GB |
| GPU | NVIDIA GeForce GTX 1660, open kernel modules, driver 595.x |
| Disk | one 512 GB NVMe: 1 GB FAT32 `/boot` (ESP) + XFS `/`. No separate `/home` |
| Monitors | `DP-1` and `HDMI-A-1`, both 1920x1080; `DP-1` is at 0,0 |
| Boot | systemd-boot, UEFI, Plymouth `bgrt` theme, quiet boot |
| Kernel | linux-zen |
| Swap | zram only, lz4, half of RAM (7.8 GB) |
| Login | greetd running `noctalia-greeter-session` as user `greeter` (noctalia-greeter 1.6.0) |
| Sessions offered | **Mango** (Wayland, the daily driver), Plasma 6 (Wayland), Plasma (X11), dwm (X11) |
| Shell UI | Noctalia 5.2.0 (the v5 C++ rewrite: TOML config, `noctalia msg ...` IPC) |
| Compositor | mango 0.17.3 (`mangowm`) |
| Terminal | kitty 0.49 (primary), alacritty (secondary) |
| Login shell | bash with starship + zoxide |
| Editor | neovim 0.12 (built with nvf), vim, VS Code |
| Audio | PipeWire + WirePlumber, pulse and ALSA (incl. 32-bit) shims, rtkit |
| Locale / TZ | `en_US.UTF-8` everywhere, `America/New_York` |
| Keyboard | `us`, no variant |

## Ground rules

- **The username must be `ethan`.** `config/noctalia/config.toml` contains
  absolute `/home/ethan/...` wallpaper paths.
- **Verify package names before installing.** Run `pacman -Si <name>` first,
  then `paru -Si <name>`. If neither finds it, search (`pacman -Ss`, `paru -Ss`)
  rather than guessing a second time. The lists in `portable/packages/` were
  written without access to Arch repos and contain errors; the corrections
  below override them.
- **Prefer repo packages over AUR, and AUR over hand builds.** CachyOS ships
  its own repos on top of Arch's; many things that are AUR-only on Arch are
  prebuilt there.
- **Do not overwrite a config that already exists without looking at it.**
  CachyOS ships its own defaults for several things (shell, zram, firewall,
  kernel cmdline). Read, then merge or replace deliberately.
- **Keep a way back in when changing the display manager.** Before disabling
  the installer's display manager, confirm you can reach a TTY
  (`Ctrl+Alt+F3`) and that `ethan` can log in there.
- **Do not reproduce Nix tooling.** Everything in
  `portable/packages/drop-nix-only.txt` is deliberately dropped.
- Privileged steps need `sudo`. If you cannot run it yourself, hand Ethan the
  exact command to run with the `!` prefix.

## Phase 0: find out what the installer already did

CachyOS's installer makes choices that overlap with this setup. Record the
answers before changing anything; several later phases branch on them.

```bash
cat /etc/os-release; uname -r
bootctl status 2>/dev/null | head -20        # systemd-boot, or something else?
findmnt -no FSTYPE /                         # xfs on the old machine
getent passwd ethan                          # login shell: CachyOS defaults to fish
systemctl status display-manager --no-pager  # sddm? ly? greetd?
ls /usr/share/wayland-sessions /usr/share/xsessions
command -v paru yay                          # AUR helper
systemctl is-active ufw firewalld
zramctl; cat /etc/systemd/zram-generator.conf /usr/lib/systemd/zram-generator.conf 2>/dev/null
pacman -Q | grep -Ei 'nvidia|plymouth|pipewire|plasma-desktop'
cat /proc/cmdline
```

Ideal installer choices, if Ethan has not installed yet: **systemd-boot**,
**XFS**, hostname `happyhomedesigner`, user `ethan`, and the **KDE Plasma**
desktop. Plasma is part of the old setup anyway, and choosing it brings in
working audio, Bluetooth, NetworkManager, portals, and the NVIDIA driver, which
leaves only Mango, Noctalia and the greeter to add.

## Phase 1: packages

### 1a. Official repos

Start from `portable/packages/arch-pacman.txt` (strip the `#` comments), then
apply these corrections. Everything here is **(verify)** unless noted.

| In the list | Use instead | Why |
|---|---|---|
| `linux-zen`, `linux-zen-headers` | skip; keep the CachyOS kernel | See [Intentional differences](#intentional-differences) |
| `ibm-plex-fonts` | `ttf-ibm-plex` | Arch's name. Noctalia's UI font is "IBM Plex Sans" |
| `otf-open-sans` | `ttf-opensans` | Arch's name |
| `ttf-firacode-nerd` | `otf-firamono-nerd` | The old system had Fira **Mono**; alacritty's config asks for "FiraMono Nerd Font" |
| `ttf-cascadia-code-nerd` | `ttf-cascadia-mono-nerd` | The old system had Caskaydia **Mono** |
| `wine` "needs multilib" | `wine` | Still correct name; CachyOS enables multilib already |

The list also **omits** things the old system had. Add:

| Package | Source in the Nix config |
|---|---|
| `firefox` | `programs.firefox.enable` |
| `neovim` | `system/nvim.nix` |
| `clang` | `libclang` in `home.nix`; also provides `clangd` for neovim |
| `texlab` | LaTeX LSP that nvf's `languages.tex` pulled in |
| `texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra texlive-fontsrecommended texlive-binextra texlive-mathscience texlive-pictures` | `texliveMedium` + `chktex` (chktex ships in `texlive-binextra`) |
| `bash-completion` | required by `portable/shell/bashrc` |
| `libva-nvidia-driver` | provides `nvidia_drv_video.so`, which `LIBVA_DRIVER_NAME=nvidia` needs |
| `greetd` | the login manager |
| `noctalia` | Noctalia v5 is in Arch `[extra]` under this name. The old `noctalia-shell` packages are v4 (Quickshell, JSON config) and will **not** read this repo's TOML config |
| `mangowm` | Mango is packaged as `mangowm` in Arch and CachyOS repos; the binary and session are named `mango` |
| `ttf-bigblueterminal-nerd` | Noctalia bar glyphs use "BigBlueTerm437 Nerd Font" |
| `plasma-x11-session`, `xorg-server`, `xorg-xinit` | only if Ethan wants the X11 sessions back (see questions) |
| `power-profiles-daemon`, `upower`, `accountsservice` | were running on the old system; Noctalia and the greeter use them |

`pfetch`, `tex-fmt`, `bun`, `vesktop`, `cataclysm-dda` and the DepartureMono
nerd font are listed as AUR-only in `aur-or-manual.txt`, but several have since
landed in `[extra]` or the CachyOS repos. Check the repos first for each.

### 1b. AUR or manual

Go through `portable/packages/aur-or-manual.txt`, with these notes:

- `noctalia-greeter` is on the AUR (`paru -S noctalia-greeter`). Do not use
  the `-git` variant unless the stable one fails to build.
- `mango` and `noctalia-shell` entries in that file are superseded by the repo
  packages above.
- `claude-code`: already installed if you are reading this. Ignore.
- `dwm`: the old system ran **stock** dwm 6.8 from nixpkgs, no patches.
  Ethan's patched tree in `~/src/dwm` was never what the session ran.
- `wheelwizard`: check Flathub before the AUR.
- `nil` (Nix language server) is in `home.nix` but pointless without Nix. Skip.
- `superhtml`, `uzdoom`, `archipelago`, `ckan`, `vintagestory`, `envypn-font`:
  search the AUR by name. If one is missing, report it instead of building from
  source unprompted.

### 1c. Flatpak, containers

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.DolphinEmu.dolphin-emu org.vinegarhq.Sober
```

Both were **system** installs from Flathub (observed). The old machine also had
one distrobox container, `fedora` from `docker.io/library/fedora:latest`;
recreate it with `distrobox create -n fedora -i fedora:latest` only if Ethan
asks, since its contents were not backed up.

**Check:** `for c in mango noctalia noctalia-greeter-session kitty alacritty nvim starship zoxide eza lazygit fzf gh btop nnn tmux mpv slurp distrobox podman virt-manager steam; do command -v $c >/dev/null || echo MISSING $c; done` prints nothing.

## Phase 2: shell

CachyOS makes **fish** the login shell and ships its own bash/fish config. The
old system used **bash**.

```bash
chsh -s /bin/bash ethan
cp ~/.bashrc ~/.bashrc.cachyos-orig 2>/dev/null
cp "$REPO/portable/shell/bashrc"       ~/.bashrc
cp "$REPO/portable/shell/bash_profile" ~/.bash_profile
cp "$REPO/portable/config/starship.toml" ~/.config/starship.toml
mkdir -p ~/.lazygit      # the lg() wrapper writes its "new dir" file here
```

Then edit `~/.bashrc`: the `rebuild` and `cleanup` aliases call `nh`, which is
Nix-only. Replace them per Ethan's answer in the questions section; the
suggested mapping keeps the muscle memory:

```bash
alias -- rebuild='paru -Syu'
alias -- cleanup='paru -Sc && paru -c'
```

The other aliases stay as they are: `ls` is `eza --color=auto --icons=always`,
`cd` is `z` (zoxide), `q` is `exit`. `lg` is a function wrapping lazygit that
`cd`s to the repo lazygit exits in. History: `HISTSIZE=10000`,
`HISTFILESIZE=100000`, `histappend`.

The old system also had comma (`,`, run a program without installing it).
There is no equivalent; do not try to fake one.

**Check:** a new terminal shows the starship prompt with Nerd Font glyphs (not
boxes), `type cd` reports an alias to `z`, and `ls` shows icons.

## Phase 3: dotfiles

Copy these verbatim. All are plain files with no Nix paths in them.

| From `$REPO/portable/` | To | Notes |
|---|---|---|
| `config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | JetBrains Mono NF 16, 0.8 opacity, blur 20 |
| `config/kitty/kitty_dd.conf` | `~/.config/kitty/kitty_dd.conf` | drop-down terminal profile (`Super+grave`) |
| `config/mango/config.conf` | `~/.config/mango/config.conf` | keybinds below |
| `config/noctalia/config.toml` | `~/.config/noctalia/config.toml` | bar, widgets, theme, wallpaper |
| `config/noctalia/palettes/test-mc.json` | `~/.config/noctalia/palettes/test-mc.json` | **required**: `config.toml` sets `theme.source = "custom"`, `custom_palette = "test-mc"` |
| `config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | FiraMono Nerd Font 16, same colours as kitty |
| `config/vim/vimrc` | `~/.vimrc` | needs vim-plug, see below |
| `config/nvim/init.lua` | `~/.config/nvim/init.lua` | see Phase 9 |
| `walls/*` | `~/Documents/walls/` | Noctalia's wallpaper directory; current wallpaper is `test.jpg` |
| `midis/*` | `~/Documents/midis/` | |

vim: `~/.vimrc` uses vim-plug with one plugin (lightline). Install plug.vim to
`~/.vim/autoload/plug.vim` from <https://github.com/junegunn/vim-plug>, then
run `vim +PlugInstall +qall`.

Saves (both archives unpack to a single top-level directory):

```bash
mkdir -p ~/Documents/dregs/elona
tar --zstd -xf "$REPO/portable/saves/animalcrossingsave.tar.zst" -C ~/Documents          # -> ~/Documents/animalcrossingsave/
tar --zstd -xf "$REPO/portable/saves/elona-save.tar.zst"         -C ~/Documents/dregs/elona  # -> .../elona/save/
```

On NixOS the Noctalia `config.toml` was a read-only symlink, so anything
changed in Noctalia's settings UI went to `~/.local/state/noctalia/settings.toml`
instead. On CachyOS the file is writable. That is fine; just know that the
copied `config.toml` is the intended state and nothing from the old
`settings.toml` needs restoring.

**Check:** `fc-match "JetBrainsMono NF"`, `fc-match "IBM Plex Sans"`,
`fc-match "BigBlueTerm437 Nerd Font"` and `fc-match "FiraMono Nerd Font"` each
return the named family rather than a fallback. If kitty falls back to another
font, note that `kitty.conf` spells it `JetBrains Mono NF` (with spaces); that
is how it was on the old system, so report it to Ethan instead of changing it.

## Phase 4: Mango session, Noctalia, portals

### What the Mango config expects

`config.conf` starts Noctalia itself (`exec-once=noctalia`) and then starts the
portal with `systemctl --user start xdg-desktop-portal.service --ignore-dependencies`.
Nothing else needs autostarting. It pins `DP-1` to 0,0 with
`monitorrule=name:^DP-1$,x:0,y:0` and lets `HDMI-A-1` place itself. Run
`wlr-randr` inside the session (or read `/sys/class/drm/*/status`) to confirm
the connector names match; if the
new install names them differently, fix the `monitorrule` line and the
`output = "..."` / `[wallpaper.monitors.*]` entries in Noctalia's `config.toml`.

Keybinds, for testing (all from `config.conf`):

| Keys | Action |
|---|---|
| `Super+Return` | kitty |
| `Super+grave` | drop-down kitty (`kitten quick-access-terminal -c ~/.config/kitty/kitty_dd.conf`) |
| `Super+p` | Noctalia launcher (`noctalia msg panel-open launcher`) |
| `Super+Shift+s` | region screenshot (`noctalia msg screenshot-region`) |
| `Super+q` | close window |
| `Super+f` / `Super+Shift+f` | fullscreen / fake fullscreen |
| `Alt+a` | maximise |
| `Super+space` | toggle floating |
| `Super+o` | overview |
| `Super+1..9` / `Super+Shift+1..9` | view tag / move window to tag |
| `Alt+Shift+Left/Right` | focus other monitor |
| `Super+Shift+Left/Right` | move window to other monitor |
| `Super+Alt+Shift+d` | cycle layout (tile, dwindle); every tag defaults to dwindle |
| `Super+r` | reload config |
| `Super+Shift+m` | quit Mango |
| `Super` + mouse side buttons | previous / next tag |
| `Super` + left / right drag | move / resize |

### Session file

`mangowm` should install `/usr/share/wayland-sessions/mango.desktop`. The old
one was (observed):

```ini
[Desktop Entry]
Encoding=UTF-8
Name=Mango
DesktopNames=mango;wlroots
Comment=mango WM
Exec=mango
Icon=mango
Type=Application
```

`DesktopNames=mango;wlroots` matters: it sets `XDG_CURRENT_DESKTOP=mango`,
which is how the portal picks `mango-portals.conf`.

### Portals

Install `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `xdg-desktop-portal-gtk`
and `slurp`. Two files reproduce the old behaviour.

`/etc/xdg/xdg-desktop-portal/mango-portals.conf` (skip if `mangowm` already
ships an equivalent under `/usr/share/xdg-desktop-portal/`; the old effective
file was):

```ini
[preferred]
default=gtk
org.freedesktop.impl.portal.Inhibit=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.ScreenShot=wlr
org.freedesktop.impl.portal.Secret=gnome-keyring
```

`~/.config/xdg-desktop-portal-wlr/config` (screen-share picker: click a monitor
with slurp):

```ini
[screencast]
chooser_type=simple
chooser_cmd=slurp -f 'Monitor: %o' -or
```

**Check:** log into the Mango session. The Noctalia bar appears at the top
with: workspaces, `|`, window title on the left; media, CPU, Mem, clock
(`Thu Oct 01 - 20:59` format) on the right. The theme is the olive/green
`test-mc` palette in dark mode, not Gruvbox or a default. The wallpaper is
`test.jpg` on both monitors. Every keybind in the table works. Screen sharing
in Firefox or OBS shows the slurp monitor picker.

## Phase 5: login screen (greetd + noctalia-greeter)

Do this **after** the Mango session is proven to work from a TTY or the
installer's display manager.

`/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
```

Confirm the path with `command -v noctalia-greeter-session`. greetd must launch
the `-session` wrapper, not `noctalia-greeter` itself. The `greeter` user
should be created by the `greetd` package; check with `id greeter`.

```bash
sudo systemctl disable sddm      # or whatever Phase 0 found; do not use --now yet
sudo systemctl enable greetd
```

Reboot rather than switching live. If the greeter does not come up, recover
from a TTY with `sudo systemctl disable greetd && sudo systemctl enable sddm`.

Optional and only if Ethan wants it: the greeter can copy Noctalia's wallpaper,
palette and monitor layout via Noctalia's Settings -> Security -> Noctalia
Greeter -> Sync Now. That writes `/var/lib/noctalia-greeter/sync.toml` through
polkit. Whether the old machine had synced is unknown (the directory was not
readable), so ask before assuming.

**Check:** after reboot the Noctalia greeter appears on both monitors, lists
Mango and Plasma as sessions, and logging in as `ethan` lands in Mango.

## Phase 6: NVIDIA and Firefox video decoding

CachyOS's hardware detection normally installs the right driver. Confirm it is
the **open** kernel module flavour (`nvidia-open` / `nvidia-open-dkms`), which
is what the old system used (`hardware.nvidia.open = true`) and which supports
the GTX 1660. `nvidia-smi` should list the card; `cat /sys/module/nvidia_drm/parameters/modeset`
should print `Y`.

System-wide environment, from `system/nvidia.nix`. Put these in
`/etc/environment`:

```
LIBVA_DRIVER_NAME=nvidia
MOZ_DISABLE_RDD_SANDBOX=1
```

Firefox preferences. On NixOS these were locked policies; this is the exact
set that was live (observed in `/etc/firefox/policies/policies.json`). Write
the same file at `/etc/firefox/policies/policies.json`:

```json
{
  "policies": {
    "Preferences": {
      "gfx.x11-egl.force-enabled":                     { "Status": "locked", "Value": true },
      "widget.dmabuf.force-enabled":                   { "Status": "locked", "Value": true },
      "media.hardware-video-decoding.force-enabled":   { "Status": "locked", "Value": true },
      "media.ffmpeg.vaapi.enabled":                    { "Status": "locked", "Value": false },
      "media.rdd-ffmpeg.enabled":                      { "Status": "locked", "Value": false },
      "media.av1.enabled":                             { "Status": "locked", "Value": false }
    }
  }
}
```

The old file also had `"DisableAppUpdate": true`, which only exists because
Nix manages Firefox; leave it out.

**Check:** `vainfo` lists NVDEC profiles without errors. `about:support` in
Firefox shows hardware video decoding as available.

## Phase 7: system tuning

Each item maps to a line in `configuration.nix` or `system/user.nix`.

**Identity.** `hostnamectl set-hostname happyhomedesigner`;
`timedatectl set-timezone America/New_York`; `localectl set-locale LANG=en_US.UTF-8`
(make sure `en_US.UTF-8 UTF-8` is uncommented in `/etc/locale.gen` and run
`locale-gen`). No `LC_*` overrides are needed; they were all `en_US.UTF-8`.

**Groups.** The NixOS groups were `wheel`, `networkmanager`, `libvirtd`. On
Arch that is `wheel` and `libvirt` (no `networkmanager` group is needed):
`sudo usermod -aG wheel,libvirt ethan`.

**zram.** Old: lz4, half of RAM, no disk swap. CachyOS ships its own
zram-generator default, which Phase 0 printed (usually zstd and the full RAM
size). To match the old machine, write `/etc/systemd/zram-generator.conf`:

```ini
[zram0]
compression-algorithm = lz4
zram-size = ram / 2
```

This is a deliberate downgrade from CachyOS's tuned default purely for parity;
it is on the questions list.

**Bluetooth.** In `/etc/bluetooth/main.conf` set `Experimental = true` and
`FastConnectable = true` under `[General]`, and `AutoEnable = true` under
`[Policy]`. Then `sudo systemctl enable --now bluetooth`. `Experimental` is
what makes battery levels of connected devices show up.

**Services.** Enable: `NetworkManager`, `sshd`, `cups` (printing),
`bluetooth`, `libvirtd`, `greetd`, `power-profiles-daemon`. PipeWire,
WirePlumber and `pipewire-pulse` run as user services and should already be on;
confirm with `systemctl --user is-active pipewire wireplumber pipewire-pulse`.
Install `lib32-pipewire` for 32-bit game audio (`alsa.support32Bit`).

**Firewall.** The old firewall was on, with these open. Use whichever of `ufw`
or `firewalld` Phase 0 found active; do not install a second one.

| Port | Proto | Why |
|---|---|---|
| 22 | TCP | sshd |
| 25565 | TCP + UDP | Minecraft server |
| 27015 | TCP + UDP | Source dedicated server (also Steam `dedicatedServer.openFirewall`) |
| 27036 | TCP | Steam Remote Play |
| 27031-27036 | UDP | Steam Remote Play |
| 27040 | TCP | Steam local network game transfers |

**Boot.** The old kernel command line added `quiet splash rd.udev.log_level=3
rd.systemd.show_status=auto loglevel=3`, with Plymouth on its default `bgrt`
theme (the motherboard logo with a spinner). CachyOS usually ships Plymouth and
a quiet cmdline already; compare `cat /proc/cmdline` and
`plymouth-set-default-theme` against that and change only what differs. With
systemd-boot on CachyOS, kernel options live in `/etc/sdboot-manage.conf`
(`LINUX_OPTIONS=`) and are applied with `sudo sdboot-manage gen`; do not
hand-edit files under `/boot/loader/entries/`. Changing the Plymouth theme
needs `sudo plymouth-set-default-theme -R bgrt`.

**Virtualisation.** `qemu-full`, `libvirt`, `virt-manager`, `dnsmasq` (for the
default NAT network), then `sudo virsh net-autostart default`. The old machine
had no VMs defined, so there is nothing to migrate. `podman` + `distrobox` are
just packages.

**Check:** `hostnamectl`, `timedatectl`, `zramctl`, `id ethan`,
`systemctl is-enabled NetworkManager sshd cups bluetooth libvirtd greetd`, and
the firewall's status output all match the above.

## Phase 8: gaming

- Steam from the repos (`steam`, plus `lib32-nvidia-utils`). The firewall
  ports are covered in Phase 7.
- From `home.nix`: `prismlauncher`, `dolphin-emu`, `mgba-qt`, `openttd`,
  `cataclysm-dda`, plus the AUR/manual set (`archipelago`, `ckan`, `uzdoom`,
  `vintagestory`, `wheelwizard`).
- Flatpaks: Dolphin and Sober (Phase 1c). Dolphin was installed twice on the
  old system, once natively and once as a Flatpak; the Flatpak held 391 MB of
  data against under 2 MB for the native one, so the Flatpak is probably the
  copy Ethan actually used.
- Communication: `vesktop`. The old system registered it for `discord://`
  links: `xdg-mime default vesktop.desktop x-scheme-handler/discord`.

## Phase 9: neovim

`portable/config/nvim/init.lua` is a hand-written lazy.nvim approximation of
the nvf config in `system/nvim.nix`. It has never been run. Expect to fix it.
Known problems to look for on Neovim 0.12:

- It calls `require("lspconfig").clangd.setup({})`. On 0.11+ the supported form
  is `vim.lsp.enable({ "clangd", "texlab" })`.
- It calls `require("nvim-treesitter.configs").setup(...)`, which the current
  `main` branch of nvim-treesitter removed.
- nvf's `languages.nix` and `languages.html` also enabled LSPs (`nil`,
  `superhtml`); the port only enables treesitter for them.

What it must end up providing, per `system/nvim.nix`: line numbers,
`showmode` off, LSP for C/C++ (clangd) and LaTeX (texlab), treesitter for HTML
and Nix, bufferline, lualine, autopairs, indent-blankline, blink.cmp, noice,
and cord.nvim (Discord presence) with idle disabled.

**Check:** `nvim --headless "+Lazy! sync" +qa` exits cleanly, and opening a
`.c` file shows clangd attached in `:checkhealth vim.lsp`.

## Final verification

Run through this as one pass and report the result line by line.

- [ ] Boots quietly through Plymouth to the Noctalia greeter on both monitors
- [ ] Logging in as `ethan` starts Mango with the Noctalia bar, `test-mc` palette, `test.jpg` wallpaper
- [ ] Every keybind in the Phase 4 table works, including drop-down kitty and region screenshot
- [ ] kitty is translucent with blur, JetBrains Mono, the dark `#101010` colour scheme
- [ ] bash prompt is starship with icons; `ls`, `cd`, `q`, `lg` behave as described
- [ ] Audio plays; Bluetooth pairs and shows device battery
- [ ] `nvidia-smi` works; Firefox plays video with hardware decode
- [ ] Screen sharing offers the slurp monitor picker
- [ ] Steam launches and a game starts
- [ ] Plasma session is selectable at the greeter and starts
- [ ] `virt-manager` connects to `qemu:///system` without a password prompt
- [ ] Firewall is active with exactly the Phase 7 ports open

## Intentional differences

These are not oversights. Say so if Ethan asks why something differs.

| Old | New | Reason |
|---|---|---|
| linux-zen | CachyOS's default kernel | It is the point of the distro, and the NVIDIA modules are prebuilt for it |
| Lix / flakes / home-manager / nh / comma / nix-ld | nothing | Nix-only tooling |
| nvf-built neovim | lazy.nvim config | nvf has no non-Nix form |
| `rebuild` / `cleanup` aliases call `nh` | remapped to paru, or removed | Nix-only commands |
| `nil` language server | dropped | only useful for editing Nix |
| Firefox `DisableAppUpdate` policy | dropped | only needed when Nix owns Firefox |
| Doom Emacs | not installed | already commented out in `home.nix` and `flake.nix` |

## Not in this repo

The repo covers configuration, wallpapers, MIDIs and two game saves. The old
disk had a single root partition with `/home` on it, so anything below that
Ethan did not copy off separately is gone. If Ethan asks where something is,
this is the list of what existed and was **not** backed up here:

- `~/Documents/midis/FluidR3_GM_GS.sf2` (145 MB soundfont; too big for GitHub)
- `~/Videos/` (207 MB), including the PS2 menu ambience video used as an mpvpaper video wallpaper
- `~/src/` (14 GB of projects, including a patched `dwm` tree and `dwms.diff`)
- `~/arch/` (Archipelago / SNES files), `~/Downloads/` (19 GB)
- Game data: Steam library (149 GB, re-downloadable), PrismLauncher instances (4.5 GB: `1.21.1`, `1.21.8`, `26.1`, `26.1.1`, `Random Item Skyblock`, `SkyFactory 4`, `testing 1.0.0`), `~/.factorio` (1.5 GB), `~/.barony`, `~/.cataclysm-dda`, `~/.ringracers`, `~/.srb2`, `~/.wine` (931 MB), Vintage Story data, Sober and Dolphin Flatpak data, mGBA / RetroArch / OpenTTD / UZDoom configs
- App profiles: Firefox (`~/.config/mozilla`), Vesktop, VS Code (`~/.config/Code`, `~/.vscode`), OBS scenes, Krita resources
- Small app configs: btop, htop, fastfetch
- KDE/GTK appearance for the Plasma session (Breeze, `breeze_cursors` 24px, Papirus-Dark icons, Open Sans 10). Re-set these in Plasma's System Settings if Ethan wants the Plasma session to look the same
- `~/.claude/` and `~/.claude.json` (Claude Code settings, plugins, memory)
- Credentials: there were no SSH keys. GitHub auth was `gh`'s credential helper, so run `gh auth login` and `gh auth setup-git`. Git identity: `git config --global user.name Ethan`, and ask Ethan for the email rather than assuming

## Questions for Ethan

Ask these together at the start.

1. **X11 sessions.** The old greeter offered dwm (stock 6.8) and Plasma X11
   alongside Mango and Plasma Wayland. Reinstall those, or Wayland only?
2. **`rebuild` and `cleanup` aliases.** Remap to `paru -Syu` and
   `paru -Sc && paru -c`, or remove?
3. **zram.** Match the old machine (lz4, half of RAM) or keep CachyOS's default?
4. **Greeter appearance sync.** Sync Noctalia's theme and wallpaper to the
   login screen?
5. **Fedora distrobox.** Recreate an empty one?
6. **Git email** for `git config --global user.email`.

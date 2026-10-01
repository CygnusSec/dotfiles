# Dotfiles for macOS and Arch Linux

One repository for shared shell/editor configuration and OS-specific setup.
Secrets, private keys, tokens, and machine-local overrides are intentionally
excluded.

## Layout

```text
common/   shared Zsh, Git, tmux, VS Code, Neovim, and scripts
arch/     Hyprland, Waybar, Kitty, and an explicit package list
macos/    Homebrew bundle and optional macOS defaults
```

## Bootstrap a machine

```bash
git clone git@github.com:CygnusSec/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
./install.sh --dry-run
./install.sh
```

The default run only creates symlinks and installs VS Code extensions already
listed in `common/vscode/extensions.txt`. Existing destinations are renamed to
timestamped `*.backup.YYYYmmddHHMMSS` files first.

Package installation and macOS preference changes are explicit:

```bash
./install.sh --packages          # Homebrew on macOS, pacman on Arch
./install.sh --defaults          # apply Finder defaults on macOS
./install.sh --packages --defaults
```

The installer detects `Darwin` or `Linux`. It can be run repeatedly; links that
already point to this checkout are left untouched. The checkout does not have
to be at `~/dotfiles`, though the convenience aliases assume that location.

## Update and backup

Pull and relink:

```bash
./update.sh
```

Refresh OS-owned inventories:

```bash
./backup.sh
git diff
```

On macOS, `backup.sh` refreshes the Brewfile. On Arch, it copies Hyprland,
Waybar, and Kitty only when their live directories are not already symlinks into
this repository. If the `code` command is installed, the extension list is also
refreshed.

## Machine-local configuration

- Put Git overrides such as a personal identity in `~/.gitconfig.local`.
- Put shell-only overrides in `~/.zshrc.local`.
- Put private environment variables in `~/.config/private/env` and restrict it
  with `chmod 600`. None of these files belongs in this repository.
- Each machine must have its own SSH private key. Only a non-secret SSH config
  may be added to dotfiles.

## Daily workflow

```bash
git pull --rebase
# edit configuration through the linked files
git status
git add .
git commit -m "Update dotfiles"
git push
```

## Current bootstrap snapshot

- Zsh, Git identity, and VS Code settings were imported from the current macOS
  machine and reviewed for obvious secret patterns.
- The Brewfile reflects the currently installed top-level formulae and casks.
- tmux was not installed and no existing tmux config was available, so a small
  portable default was created.
- VS Code CLI and keybindings were not available; `extensions.txt` is therefore
  intentionally empty until `code` is installed and `./backup.sh` is run.
- Arch GUI configuration directories are placeholders until backed up on the
  Arch machine.

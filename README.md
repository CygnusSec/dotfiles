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
./install.sh list
./install.sh --dry-run zsh nvim vscode
./install.sh zsh nvim vscode
```

Running without item names opens an interactive selection. Existing destinations
are renamed to timestamped `*.backup.YYYYmmddHHMMSS` files before linking.
VS Code extensions already installed are skipped. Extensions unavailable in the
current editor marketplace or incompatible with the current OS are reported at
the end without stopping the remaining installation.

Package installation and macOS preference changes are explicit:

```bash
./install.sh brew                # Homebrew bundle on macOS
./install.sh defaults            # Finder defaults on macOS
./install.sh packages            # pacman package list on Arch
./install.sh hypr waybar kitty   # selected Arch desktop configuration
./install.sh all                 # every item available on this OS
```

The installer detects `Darwin` or `Linux`. It can be run repeatedly; links that
already point to this checkout are left untouched. The checkout does not have
to be at `~/dotfiles`, though the convenience aliases assume that location.

## Update and backup

Pull and relink:

```bash
./update.sh
```

Choose exactly what to copy from the current machine into the repository:

```bash
./backup.sh                  # interactive selection
./backup.sh zsh nvim vscode  # selected common configuration
./backup.sh brew             # Homebrew only on macOS
./backup.sh hypr waybar      # selected desktop config on Arch
./backup.sh all              # every item available on this OS
git diff
```

`backup.sh` never pulls, commits, or pushes. Files that already symlink into the
repository are skipped because they are already current. The `vscode` selection
includes settings, optional keybindings, and the extension list when the `code`
command is available. Review Git config and every diff for secrets before
committing. Directory backups such as Neovim exclude nested `.git` metadata.

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

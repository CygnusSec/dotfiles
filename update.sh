#!/usr/bin/env bash
set -euo pipefail

DOTFILES=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
git -C "$DOTFILES" pull --rebase
"$DOTFILES/install.sh" "$@"

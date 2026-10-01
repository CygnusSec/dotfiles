#!/usr/bin/env bash
set -euo pipefail

defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
killall Finder >/dev/null 2>&1 || true

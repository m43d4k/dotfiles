#!/bin/sh

echo "リンクを作成します..."

# Zsh の設定
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/zsh/.zprofile ~/.zprofile
ln -sf ~/dotfiles/zsh/.zsh_plugins.txt ~/.zsh_plugins.txt
# Claude Code のローカル設定ファイル
mkdir -p ~/.config/zsh
ln -sf ~/dotfiles/zsh/claude/template.settings.local.json ~/.config/zsh/template.settings.local.json

# Git の設定
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/git/.gitmessage ~/.gitmessage

# Neovim の設定とカラースキーム
mkdir -p ~/.config/nvim/colors
ln -sf ~/dotfiles/nvim/init.lua ~/.config/nvim/init.lua
for colorscheme in ~/dotfiles/nvim/colors/*.vim; do
  ln -sf "$colorscheme" ~/.config/nvim/colors/
done

# Starship プロンプトの設定
ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml

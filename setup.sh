#!/bin/sh

echo "リンクを作成します..."

# Zsh の設定
ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/dotfiles/zsh/.zprofile ~/.zprofile
ln -sf ~/dotfiles/zsh/.zsh_plugins.txt ~/.zsh_plugins.txt
# Claude Code のローカル設定ファイル
mkdir -p ~/.config/zsh
ln -sf ~/dotfiles/zsh/claude/template.settings.local.json ~/.config/zsh/template.settings.local.json
ln -sf ~/dotfiles/zsh/claude/template.CLAUDE.local.md ~/.config/zsh/template.CLAUDE.local.md

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

# Ghostty の設定
mkdir -p ~/.config/ghostty
ln -sf ~/dotfiles/ghostty/config ~/.config/ghostty/config

#Claude の設定
chmod +x ~/dotfiles/claude/hooks/enforce-uv.sh
mkdir -p ~/.claude/hooks
ln -sf ~/dotfiles/claude/hooks/enforce-uv.sh ~/.claude/hooks/enforce-uv.sh

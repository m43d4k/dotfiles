# dotfiles

macOS 用の zsh / Neovim / Git などの CLI 環境を再現するための設定。

## 🎛 初回セットアップ手順

### 1. Homebrew をインストール

公式サイト: [https://brew.sh/](https://brew.sh/)

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. このリポジトリを HTTPS 経由で clone

```sh
git clone https://github.com/m43d4k/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. 必要なツールをインストール（Brewfile）

```sh
brew bundle --file=Brewfile.minimal
```

### 4. 設定ファイルを所定の場所にリンク（~/.zshrc や ~/.config/nvim など）

```sh
chmod +x setup.sh
./setup.sh
```

### 5. SSH 証明書の移行（後からでOK）

- `.ssh` ディレクトリを新しいMacにコピー
- `.ssh` ディレクトリと秘密鍵のパーミッションを変更：

```sh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519   # 他の秘密鍵も同様に
```

#### 💡 補足：必要であれば、リモートURLを SSH に切り替え

```sh
git remote set-url origin git@github.com:m43d4k/dotfiles.git
```
---

## 📐 含まれる主な構成ファイル

- **zsh**: `.zshrc`, `.zprofile`（補完・プロンプト・mise 連携）
- **git**: `.gitconfig`, `.gitmessage`（エイリアスとコミットテンプレート）
- **neovim**: `init.lua`, `colors/`（最小限の Lua 設定とカラースキーム）
- **starship**: `starship.toml`（プロンプトの表示設定）

## 🧭 運用ポリシー（補足）

- **zsh** は、macOS 標準の `/bin/zsh` を使用。（Homebrew で追加インストールしない）
- **Python や Node.js** は、グローバルでは macOS 標準の `/usr/bin/python3`, `/usr/bin/node` を使用。  
  開発プロジェクトごとに `mise` にてバージョンを管理。
- **VSCode** をメインエディタとし、Neovim はターミナルでの軽量編集用途。

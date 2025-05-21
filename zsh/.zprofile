eval "$(/opt/homebrew/bin/brew shellenv)"

# 共通エディタ
export EDITOR=nvim
export VISUAL=nvim

mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh" # ヒストリ保存用ディレクトリを作成

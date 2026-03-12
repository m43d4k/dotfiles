#========================================
# 基本環境設定
#========================================
umask 022

export LANG=ja_JP.UTF-8
export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"

limit coredumpsize 0  # コアダンプを吐かない

autoload -U colors && colors # プロンプトやプラグインの色表示に必要

# 入力キーバインド設定
bindkey -e   # Emacs風キーバインドを設定

#========================================
# Zshの動作オプション
#========================================

# ビープ音を消す
setopt no_beep
setopt no_hist_beep
setopt no_list_beep
setopt correct

# フローコントロールを無効にする
setopt no_flow_control

#========================================
# ヒストリ設定
#========================================

HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"  # 履歴ファイルの保存先
HISTSIZE=1000                                           # メモリ上の履歴数
SAVEHIST=1000                                           # ファイルに保存する履歴数

# 履歴の重複制御
setopt hist_ignore_dups         # 直前と同じコマンドは記録しない
setopt share_history            # 同時に起動している zsh 間で履歴を共有
setopt extended_history         # 実行時間・時刻付きでヒストリを記録

#========================================
# 補完機能の初期化と設定
#========================================

# 補完システムの有効化
autoload -Uz compinit
compinit -C

# 補完候補の表示整形
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'
zstyle ':completion:*' group-name ''

# 自動候補表示と選択モード
setopt auto_list
zstyle ':completion:*:default' menu select=2

# 大文字小文字を区別せず補完
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' verbose yes

# 補完候補のタイプ別設定
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?~' '*\#'
zstyle ':completion:*' use-cache true
zstyle ':completion:*:cd:*' ignore-parents parent pwd

#========================================
# mise（言語バージョン管理）の初期化
#========================================

eval "$(mise activate zsh)"

#========================================
# starship（プロンプト表示）の初期化
#========================================

eval "$(starship init zsh)"

#========================================
# zoxide（高機能な cd コマンド）
#========================================
eval "$(zoxide init zsh)"

#========================================
# ページャの設定（色つき表示を有効に）
#========================================
export LESS='-R'

#========================================
# fzf の初期化
#========================================

# 対話シェル時のみ fzf の補完とキーバインドを有効化
if [[ $- == *i* ]]; then
  [ -f /opt/homebrew/opt/fzf/shell/completion.zsh ] && source /opt/homebrew/opt/fzf/shell/completion.zsh
  [ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
fi

# 表示スタイルのカスタマイズ（オプション）
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

# ripgrep を fzf のデフォルトファイル検索に使用
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

#========================================
# エイリアス（コマンド短縮）
#========================================
alias ls='ls --color=auto'  # ls を色付きに
alias ll='ls -alF'          # 詳細なファイル一覧（隠しファイル含む）
alias la='ls -A'            # 隠しファイルを含むが . / .. は除外
alias l='ls -CF'            # 軽量で高速なファイル一覧
alias ..='cd ..'            # 親ディレクトリへ移動
alias gs='git status'       # Git の作業状況確認
alias gc='git commit'       # Git のコミット

#========================================
# Claude Code 用ユーティリティ
#========================================
claude_init() {
  local target_dir=".claude"
  local target_local_settings_json="$target_dir/settings.local.json"
  local target_local_claude_md="$target_dir/CLAUDE.local.md"

  local template_local_settings_json="$HOME/.config/zsh/template.settings.local.json"
  local template_local_claude_md="$HOME/.config/zsh/template.CLAUDE.local.md"

  if [[ -f "$target_local_settings_json" ]]; then
    echo "Error: settings.local.json already exists at $target_local_settings_json" >&2
    return 1
  fi

  if [[ -f "$target_local_claude_md" ]]; then
    echo "Error: CLAUDE.local.md already exists at $target_local_claude_md" >&2
    return 1
  fi

  if [[ ! -f "$template_local_settings_json" ]]; then
    echo "Error: Template file not found at $template_local_settings_json" >&2
    return 1
  fi

  if [[ ! -f "$template_local_claude_md" ]]; then
    echo "Error: Template file not found at $template_local_claude_md" >&2
    return 1
  fi

  if ! mkdir -p "$target_dir"; then
    echo "Error: Failed to create .claude directory" >&2
    return 1
  fi

  if ! cp "$template_local_settings_json" "$target_local_settings_json"; then
    echo "Error: Failed to copy template file to $target_local_settings_json" >&2
    return 1
  fi

  if ! cp "$template_local_claude_md" "$target_local_claude_md"; then
    echo "Error: Failed to copy template file to $target_local_claude_md" >&2
    return 1
  fi

  echo "✓ Successfully created $target_local_settings_json"
  echo "✓ Successfully created $target_local_claude_md"
}

#========================================
# fgc: fzfでGitブランチを選んでcheckout
#========================================
fgc() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

#========================================
# fzf + ripgrep: ソース内全文検索
#========================================
fzf_rg() {
  local file_line
  file_line=$(rg --no-heading --line-number --color=always "$1" \
    | fzf --ansi \
          --preview='echo {} | cut -d: -f1 | xargs bat --style=numbers --color=always --line-range :500' \
          --preview-window=right:60%)

  if [[ -n "$file_line" ]]; then
    local file=$(echo "$file_line" | cut -d: -f1)
    local line=$(echo "$file_line" | cut -d: -f2)
    nvim +"$line" "$file"
  fi
}

#========================================
# Antidote（プラグイン管理）
#========================================
source /opt/homebrew/share/antidote/antidote.zsh
antidote load < ~/.zsh_plugins.txt

#  起動時にバージョンを表示
printf "\n${fg_bold[cyan]}ZSH ${ZSH_VERSION}${reset_color}\n"

#========================================
# ZLE関数（カーソル制御付きコマンド展開）
#========================================

rgcopy() {
  BUFFER='rg -l "" | fzf | tee >(pbcopy)'
  CURSOR=9
  zle reset-prompt
}
zle -N rgcopy

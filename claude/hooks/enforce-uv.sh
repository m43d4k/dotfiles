#!/bin/bash
# enforce-uv.sh
# Bash tool command guard: require uv-managed Python usage.
# Allow:
#   - uv run python ...
#   - uv pip ...
#   - uv add/remove/sync/venv/tree/lock/export/tool ...
#   - source ...activate  (activation alone is allowed)
# Block:
#   - direct python / pip invocations
#   - absolute-path python / pip invocations
#   - nested shell / eval / command-substitution routes that invoke python / pip

input=$(cat)

approve() {
  echo '{"decision":"approve"}'
  exit 0
}

block_json() {
  local reason="$1"
  jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
  exit 0
}

trim() {
  local s="$1"
  s="${s#${s%%[![:space:]]*}}"
  s="${s%${s##*[![:space:]]}}"
  printf '%s' "$s"
}

extract_after_python() {
  local s="$1"
  printf '%s' "$s" | sed -E 's#^(/opt/homebrew/bin/python[0-9.]*|/usr/bin/python[0-9.]*|/usr/local/bin/python[0-9.]*|([^[:space:]]*/)?\.venv/bin/python[0-9.]*|([^[:space:]]*/)?venv/bin/python[0-9.]*|python([0-9]+(\.[0-9]+)?)?)([[:space:]]+|$)##'
}

extract_after_pip() {
  local s="$1"
  printf '%s' "$s" | sed -E 's#^(/opt/homebrew/bin/pip[0-9.]*|/usr/bin/pip[0-9.]*|/usr/local/bin/pip[0-9.]*|([^[:space:]]*/)?\.venv/bin/pip[0-9.]*|([^[:space:]]*/)?venv/bin/pip[0-9.]*|pip([0-9]+(\.[0-9]+)?)?)([[:space:]]+|$)##'
}

python_reason() {
  local seg="$1"
  local args
  args=$(extract_after_python "$seg")

  if [[ "$seg" =~ ^(/opt/homebrew/bin/python|/usr/bin/python|/usr/local/bin/python|([^[:space:]]*/)?\.venv/bin/python|([^[:space:]]*/)?venv/bin/python)[0-9.]*([[:space:]]|$) ]]; then
    block_json "🚫 Pythonを直接実行しています:\n\n代わりに:\nuv run python ${args}\n\n✅ 仮想環境のアクティベーションは不要です！"
  fi

  if [[ "$args" =~ ^-m[[:space:]]+pip([[:space:]]|$) ]]; then
    local pip_cmd
    local packages
    local req_file
    local editable_path

    pip_cmd=$(printf '%s' "$args" | sed -E 's/^-m[[:space:]]+pip[[:space:]]*//')

    if [[ "$pip_cmd" =~ ^install([[:space:]]|$) ]]; then
      packages=$(printf '%s' "$pip_cmd" | sed 's/^install *//' | sed 's/ -[^ ]*//g' | xargs)
      if [[ "$pip_cmd" =~ -r[[:space:]] ]]; then
        req_file=$(printf '%s' "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
        block_json "📋 requirements fileからインストール:\n\nuv pip install -r ${req_file}\n\n💡 pyproject.tomlに移行して管理したい場合:\nuv add -r ${req_file}"
      elif [[ "$pip_cmd" =~ (^|[[:space:]])-e([[:space:]]|$) ]]; then
        editable_path=$(printf '%s' "$pip_cmd" | sed -n 's/.*-e \([^ ]*\).*/\1/p')
        editable_path="${editable_path:-.}"
        block_json "🔧 編集可能インストール:\n\nuv add -e ${editable_path}\n\nローカルパッケージを編集可能モードでインストールします"
      else
        block_json "📦 パッケージをインストール:\n\n• プロジェクト依存として管理したい場合:\n  uv add ${packages}\n\n• 一時的/requirements.txt運用の場合:\n  uv pip install ${packages}"
      fi
    elif [[ "$pip_cmd" =~ ^uninstall([[:space:]]|$) ]]; then
      packages=$(printf '%s' "$pip_cmd" | sed 's/^uninstall *//' | sed 's/ -[^ ]*//g' | xargs)
      block_json "🗑️ パッケージを削除:\n\n• プロジェクト依存として管理している場合:\n  uv remove ${packages}\n\n• pip互換運用の場合:\n  uv pip uninstall ${packages}"
    elif [[ "$pip_cmd" =~ ^list([[:space:]]|$) ]]; then
      block_json "📊 パッケージ一覧を確認:\n\nuv pip list\n\n💡 依存関係ツリーを確認したい場合:\nuv tree"
    elif [[ "$pip_cmd" =~ ^freeze([[:space:]]|$) ]]; then
      block_json "📋 インストール済みパッケージを出力:\n\nuv pip freeze\n\n💡 requirements.txtに書き出す場合:\nuv pip freeze > requirements.txt"
    else
      block_json "🔀 pipコマンドをuvで実行:\n\nuv pip ${pip_cmd}\n\n💡 パッケージ管理には 'uv add/remove' を使用してください"
    fi
  fi

  if [[ "$args" =~ ^-m[[:space:]]+ ]]; then
    local module
    module=$(printf '%s' "$args" | sed -E 's/^-m[[:space:]]+//')
    block_json "uvでモジュールを実行:\n\nuv run python -m ${module}\n\n🔄 uvは自動的に環境を同期してから実行します。"
  fi

  block_json "uvでPythonを実行:\n\nuv run python ${args}\n\n✅ 仮想環境のアクティベーションは不要です！"
}

pip_reason() {
  local seg="$1"
  local pip_cmd
  local packages
  local req_file
  local editable_path

  pip_cmd=$(extract_after_pip "$seg")

  if [[ "$seg" =~ ^(/opt/homebrew/bin/pip|/usr/bin/pip|/usr/local/bin/pip|([^[:space:]]*/)?\.venv/bin/pip|([^[:space:]]*/)?venv/bin/pip)[0-9.]*([[:space:]]|$) ]]; then
    block_json "🚫 pipを直接実行しています:\n\n${seg}\n\n代わりに:\n• uv add <package>\n• uv pip install <package>"
  fi

  case "$pip_cmd" in
    install|install\ *)
      packages=$(printf '%s' "$pip_cmd" | sed 's/^install *//' | sed 's/ -[^ ]*//g' | xargs)
      if [[ "$pip_cmd" =~ -r[[:space:]] ]]; then
        req_file=$(printf '%s' "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
        block_json "📋 requirements fileからインストール:\n\nuv pip install -r ${req_file}\n\n💡 pyproject.tomlに移行して管理したい場合:\nuv add -r ${req_file}"
      elif [[ "$pip_cmd" =~ (^|[[:space:]])-e([[:space:]]|$) ]]; then
        editable_path=$(printf '%s' "$pip_cmd" | sed -n 's/.*-e \([^ ]*\).*/\1/p')
        editable_path="${editable_path:-.}"
        block_json "🔧 編集可能インストール:\n\nuv add -e ${editable_path}\n\nローカルパッケージを編集可能モードでインストールします"
      else
        block_json "📦 パッケージをインストール:\n\n• プロジェクト依存として管理したい場合:\n  uv add ${packages}\n\n• 一時的/requirements.txt運用の場合:\n  uv pip install ${packages}"
      fi
      ;;
    uninstall|uninstall\ *)
      packages=$(printf '%s' "$pip_cmd" | sed 's/^uninstall *//' | sed 's/ -[^ ]*//g' | xargs)
      block_json "🗑️ パッケージを削除:\n\n• プロジェクト依存として管理している場合:\n  uv remove ${packages}\n\n• pip互換運用の場合:\n  uv pip uninstall ${packages}"
      ;;
    list*)
      block_json "📊 パッケージ一覧を確認:\n\nuv pip list\n\n💡 依存関係ツリーを確認したい場合:\nuv tree"
      ;;
    freeze*)
      block_json "📋 インストール済みパッケージを出力:\n\nuv pip freeze\n\n💡 requirements.txtに書き出す場合:\nuv pip freeze > requirements.txt"
      ;;
    *)
      block_json "🔀 pipコマンドをuvで実行:\n\nuv pip ${pip_cmd}\n\n💡 パッケージのインストール/削除には 'uv add/remove' を使用してください"
      ;;
  esac
}

split_top_level_segments() {
  local s="$1"
  local i ch next quote="" escaped=0 seg=""
  local len=${#s}

  for ((i=0; i<len; i++)); do
    ch="${s:i:1}"
    next=""
    if (( i + 1 < len )); then
      next="${s:i+1:1}"
    fi

    if (( escaped )); then
      seg+="$ch"
      escaped=0
      continue
    fi

    if [[ "$quote" == '"' ]]; then
      seg+="$ch"
      if [[ "$ch" == '\\' ]]; then
        escaped=1
      elif [[ "$ch" == '"' ]]; then
        quote=""
      fi
      continue
    fi

    if [[ "$quote" == "'" ]]; then
      seg+="$ch"
      if [[ "$ch" == "'" ]]; then
        quote=""
      fi
      continue
    fi

    if [[ "$ch" == '\\' ]]; then
      seg+="$ch"
      escaped=1
      continue
    fi

    if [[ "$ch" == '"' || "$ch" == "'" ]]; then
      quote="$ch"
      seg+="$ch"
      continue
    fi

    if [[ "$ch" == '&' && "$next" == '&' ]]; then
      printf '%s\n' "$seg"
      seg=""
      ((i++))
      continue
    fi

    if [[ "$ch" == '|' && "$next" == '|' ]]; then
      printf '%s\n' "$seg"
      seg=""
      ((i++))
      continue
    fi

    if [[ "$ch" == ';' || "$ch" == '|' || "$ch" == $'\n' ]]; then
      printf '%s\n' "$seg"
      seg=""
      continue
    fi

    seg+="$ch"
  done

  printf '%s\n' "$seg"
}

normalize_segment() {
  local seg="$1"
  local prev=""

  while [[ "$seg" != "$prev" ]]; do
    prev="$seg"
    seg=$(trim "$seg")

    while [[ "$seg" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+([[:space:]]|$) ]]; do
      seg=$(printf '%s' "$seg" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]*//')
      seg=$(trim "$seg")
    done

    if [[ "$seg" =~ ^env([[:space:]]+-[^[:space:]]+)*[[:space:]]+ ]]; then
      seg=$(printf '%s' "$seg" | sed -E 's/^env([[:space:]]+-[^[:space:]]+)*[[:space:]]+//')
      seg=$(trim "$seg")
      continue
    fi

    if [[ "$seg" =~ ^(command|builtin|nice|nohup|time|sudo)([[:space:]]+-[^[:space:]]+)*[[:space:]]+ ]]; then
      seg=$(printf '%s' "$seg" | sed -E 's/^(command|builtin|nice|nohup|time|sudo)([[:space:]]+-[^[:space:]]+)*[[:space:]]+//')
      seg=$(trim "$seg")
      continue
    fi
  done

  printf '%s' "$seg"
}

is_allowed_segment() {
  local seg="$1"
  seg=$(trim "$seg")

  [[ -z "$seg" ]] && return 0

  if [[ "$seg" =~ ^uv[[:space:]]+run[[:space:]]+python([0-9]+(\.[0-9]+)?)?([[:space:]]|$) ]]; then
    return 0
  fi

  if [[ "$seg" =~ ^uv[[:space:]]+pip([[:space:]]|$) ]]; then
    return 0
  fi

  if [[ "$seg" =~ ^uv[[:space:]]+(add|remove|sync|venv|tree|lock|export|tool)([[:space:]]|$) ]]; then
    return 0
  fi

  if [[ "$seg" =~ ^source[[:space:]]+[^[:space:]]*activate([[:space:]]|$) ]]; then
    return 0
  fi

  return 1
}



split_unquoted_words() {
  local s="$1"
  local i ch quote="" escaped=0 word=""
  local len=${#s}

  for ((i=0; i<len; i++)); do
    ch="${s:i:1}"

    if (( escaped )); then
      if [[ -z "$quote" ]]; then
        word+="$ch"
      fi
      escaped=0
      continue
    fi

    if [[ "$ch" == '\' ]]; then
      escaped=1
      continue
    fi

    if [[ -n "$quote" ]]; then
      if [[ "$ch" == "$quote" ]]; then
        quote=""
      fi
      continue
    fi

    if [[ "$ch" == '"' || "$ch" == "'" ]]; then
      quote="$ch"
      continue
    fi

    if [[ "$ch" =~ [[:space:]] ]]; then
      if [[ -n "$word" ]]; then
        printf '%s
' "$word"
        word=""
      fi
      continue
    fi

    word+="$ch"
  done

  if [[ -n "$word" ]]; then
    printf '%s
' "$word"
  fi
}



segment_is_harmless_python_mention() {
  local seg="$1"
  local first second
  first=$(split_unquoted_words "$seg" | sed -n '1p')
  second=$(split_unquoted_words "$seg" | sed -n '2p')

  if [[ "$first" =~ ^(echo|printf|grep|rg|which|type)$ ]]; then
    return 0
  fi

  if [[ "$first" == "command" && "$second" =~ ^-(v|V)$ ]]; then
    return 0
  fi

  return 1
}

token_is_pythonish() {
  local tok="$1"
  [[ "$tok" =~ ^(python([0-9]+(\.[0-9]+)?)?|pip([0-9]+(\.[0-9]+)?)?|/opt/homebrew/bin/python[0-9.]*|/usr/bin/python[0-9.]*|/usr/local/bin/python[0-9.]*|/opt/homebrew/bin/pip[0-9.]*|/usr/bin/pip[0-9.]*|/usr/local/bin/pip[0-9.]*|([^[:space:]]*/)?\.venv/bin/python[0-9.]*|([^[:space:]]*/)?venv/bin/python[0-9.]*|([^[:space:]]*/)?\.venv/bin/pip[0-9.]*|([^[:space:]]*/)?venv/bin/pip[0-9.]*)$ ]]
}

segment_has_disallowed_python_token() {
  local seg="$1"
  local tok
  while IFS= read -r tok; do
    [[ -z "$tok" ]] && continue
    if token_is_pythonish "$tok"; then
      return 0
    fi
  done < <(split_unquoted_words "$seg")
  return 1
}

contains_pythonish_token() {
  local s="$1"
  [[ "$s" =~ (^|[^[:alnum:]_./-])(python([0-9]+(\.[0-9]+)?)?|pip([0-9]+(\.[0-9]+)?)?|/opt/homebrew/bin/python[0-9.]*|/usr/bin/python[0-9.]*|/usr/local/bin/python[0-9.]*|/opt/homebrew/bin/pip[0-9.]*|/usr/bin/pip[0-9.]*|/usr/local/bin/pip[0-9.]*|([^[:space:]]*/)?\.venv/bin/python[0-9.]*|([^[:space:]]*/)?venv/bin/python[0-9.]*|([^[:space:]]*/)?\.venv/bin/pip[0-9.]*|([^[:space:]]*/)?venv/bin/pip[0-9.]*)($|[^[:alnum:]_./-]) ]]
}

check_nested_routes() {
  local original_seg="$1"
  local seg="$2"

  if [[ "$seg" =~ ^(bash|sh|zsh|dash|fish)[[:space:]]+.*-(c|lc|ic)([[:space:]]|$) ]]; then
    if contains_pythonish_token "$seg"; then
      block_json "🚫 シェル経由で Python / pip を実行しようとしています:\n\n${original_seg}\n\n代わりに、次を直接実行してください:\n• uv run python ...\n• uv pip ...\n• uv add ..."
    fi
  fi

  if [[ "$seg" =~ (^|[[:space:]])eval([[:space:]]|$) ]]; then
    if contains_pythonish_token "$seg"; then
      block_json "🚫 eval 経由で Python / pip を実行しようとしています:\n\n${original_seg}\n\n代わりに、次を直接実行してください:\n• uv run python ...\n• uv pip ..."
    fi
  fi

  if [[ "$seg" == *'$('* || "$seg" == *'`'* ]]; then
    if contains_pythonish_token "$seg"; then
      block_json "🚫 コマンド置換経由で Python / pip を実行しようとしています:\n\n${original_seg}\n\n代わりに、次を直接実行してください:\n• uv run python ...\n• uv pip ..."
    fi
  fi
}

check_segment() {
  local original_seg="$1"
  local seg

  if segment_is_harmless_python_mention "$original_seg"; then
    return 0
  fi

  seg=$(normalize_segment "$original_seg")
  seg=$(trim "$seg")
  [[ -z "$seg" ]] && return 0

  if is_allowed_segment "$seg"; then
    return 0
  fi

  check_nested_routes "$original_seg" "$seg"

  if segment_has_disallowed_python_token "$seg"; then
    if [[ "$seg" =~ ^(/opt/homebrew/bin/python[0-9.]*|/usr/bin/python[0-9.]*|/usr/local/bin/python[0-9.]*|([^[:space:]]*/)?\.venv/bin/python[0-9.]*|([^[:space:]]*/)?venv/bin/python[0-9.]*|python([0-9]+(\.[0-9]+)?)?)([[:space:]]|$) ]]; then
      python_reason "$seg"
    fi

    if [[ "$seg" =~ ^(/opt/homebrew/bin/pip[0-9.]*|/usr/bin/pip[0-9.]*|/usr/local/bin/pip[0-9.]*|([^[:space:]]*/)?\.venv/bin/pip[0-9.]*|([^[:space:]]*/)?venv/bin/pip[0-9.]*|pip([0-9]+(\.[0-9]+)?)?)([[:space:]]|$) ]]; then
      pip_reason "$seg"
    fi

    block_json "🚫 このコマンド内で Python / pip を直接参照しています:

${original_seg}

代わりに、次を使ってください:
• uv run python ...
• uv pip ...
• uv add ..."
  fi

  if [[ "$seg" =~ ^(/opt/homebrew/bin/python[0-9.]*|/usr/bin/python[0-9.]*|/usr/local/bin/python[0-9.]*|([^[:space:]]*/)?\.venv/bin/python[0-9.]*|([^[:space:]]*/)?venv/bin/python[0-9.]*|python([0-9]+(\.[0-9]+)?)?)([[:space:]]|$) ]]; then
    python_reason "$seg"
  fi

  if [[ "$seg" =~ ^(/opt/homebrew/bin/pip[0-9.]*|/usr/bin/pip[0-9.]*|/usr/local/bin/pip[0-9.]*|([^[:space:]]*/)?\.venv/bin/pip[0-9.]*|([^[:space:]]*/)?venv/bin/pip[0-9.]*|pip([0-9]+(\.[0-9]+)?)?)([[:space:]]|$) ]]; then
    pip_reason "$seg"
  fi

  return 0
}

if [[ -z "$input" ]]; then
  approve
fi

tool_name=$(echo "$input" | jq -r '.tool_name' 2>/dev/null || echo "")
cmd=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

if [[ "$tool_name" != "Bash" ]]; then
  approve
fi

if [[ -z "$cmd" ]]; then
  approve
fi

while IFS= read -r seg; do
  check_segment "$seg"
done < <(split_top_level_segments "$cmd")

approve

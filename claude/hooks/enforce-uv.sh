#!/bin/bash
# enforce-uv.sh
# uvを使用するように強制するフック

input=$(cat)

# Validate input
if [ -z "$input" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Extract fields with error handling
tool_name=$(echo "$input" | jq -r '.tool_name' 2>/dev/null || echo "")
cmd=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

if [[ "$tool_name" != "Bash" ]]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# ===== pip関連コマンド =====
if [[ "$cmd" =~ ^(pip3?)([[:space:]]|$) ]]; then
  pip_cmd=$(echo "$cmd" | sed -E 's/^pip3?[[:space:]]*//')

  case "$pip_cmd" in
    install\ *)
      packages=$(echo "$pip_cmd" | sed 's/^install *//' | sed 's/ -[^ ]*//g' | xargs)

      if [[ "$pip_cmd" =~ -r[[:space:]] ]]; then
        req_file=$(echo "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
        reason="📋 requirements fileからインストール:\n\nuv pip install -r ${req_file}\n\n💡 pyproject.tomlに移行して管理したい場合:\nuv add -r ${req_file}"
      elif [[ "$pip_cmd" =~ (^|[[:space:]])-e([[:space:]]|$) ]]; then
        editable_path=$(echo "$pip_cmd" | sed -n 's/.*-e \([^ ]*\).*/\1/p')
        editable_path="${editable_path:-.}"
        reason="🔧 編集可能インストール:\n\nuv add -e ${editable_path}\n\nローカルパッケージを編集可能モードでインストールします"
      else
        reason="📦 パッケージをインストール:\n\n• プロジェクト依存として管理したい場合:\n  uv add ${packages}\n\n• 一時的/requirements.txt運用の場合:\n  uv pip install ${packages}"
      fi
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0
      ;;

    uninstall\ *)
      packages=$(echo "$pip_cmd" | sed 's/^uninstall *//' | sed 's/ -[^ ]*//g' | xargs)
      reason="🗑️ パッケージを削除:\n\n• プロジェクト依存として管理している場合:\n  uv remove ${packages}\n\n• pip互換運用の場合:\n  uv pip uninstall ${packages}"
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0
      ;;

    list*)
      reason="📊 パッケージ一覧を確認:\n\nuv pip list\n\n💡 依存関係ツリーを確認したい場合:\nuv tree"
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0
      ;;

    freeze*)
      reason="📋 インストール済みパッケージを出力:\n\nuv pip freeze\n\n💡 requirements.txtに書き出す場合:\nuv pip freeze > requirements.txt"
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0
      ;;

    *)
      reason="🔀 pipコマンドをuvで実行:\n\nuv pip ${pip_cmd}\n\n💡 パッケージのインストール/削除には 'uv add/remove' を使用してください"
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0
      ;;
  esac

# ===== 絶対パス pip =====
elif [[ "$cmd" =~ ^(/opt/homebrew/bin/pip|/usr/bin/pip|/usr/local/bin/pip|(\./)?\.?venv/bin/pip)[0-9.]*([[:space:]]|$) ]]; then
  reason="🚫 pipを直接実行しています:\n\n${cmd}\n\n代わりに:\n• uv add <package>\n• uv pip install <package>"
  jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
  exit 0

# ===== 絶対パス python =====
elif [[ "$cmd" =~ ^(/opt/homebrew/bin/python|/usr/bin/python|/usr/local/bin/python|(\./)?\.?venv/bin/python)[0-9.]*([[:space:]]|$) ]]; then
  abs_args=$(echo "$cmd" | sed -E 's|^[^ ]+[[:space:]]*||')
  reason="🚫 Pythonを直接実行しています:\n\n代わりに:\nuv run python ${abs_args}\n\n✅ 仮想環境のアクティベーションは不要です！"
  jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
  exit 0

# ===== 直接的なPython実行の処理 =====
elif [[ "$cmd" =~ ^python([0-9]+(\.[0-9]+)?)?([[:space:]]|$) ]]; then
  args=$(echo "$cmd" | sed -E 's/^python[0-9.]* *//')

  if [[ "$args" =~ ^-m[[:space:]] ]]; then
    module=$(echo "$args" | sed 's/^-m[[:space:]]*//')

    if [[ "$module" =~ ^pip[[:space:]] ]]; then
      pip_cmd=$(echo "$module" | sed 's/^pip[[:space:]]*//')

      if [[ "$pip_cmd" =~ ^install ]]; then
        packages=$(echo "$pip_cmd" | sed 's/^install *//' | sed 's/ -[^ ]*//g' | xargs)
        if [[ "$pip_cmd" =~ -r[[:space:]] ]]; then
          req_file=$(echo "$pip_cmd" | sed -n 's/.*-r \([^ ]*\).*/\1/p')
          reason="📋 requirements fileからインストール:\n\nuv pip install -r ${req_file}\n\n💡 pyproject.tomlに移行して管理したい場合:\nuv add -r ${req_file}"
        elif [[ "$pip_cmd" =~ (^|[[:space:]])-e([[:space:]]|$) ]]; then
          editable_path=$(echo "$pip_cmd" | sed -n 's/.*-e \([^ ]*\).*/\1/p')
          editable_path="${editable_path:-.}"
          reason="🔧 編集可能インストール:\n\nuv add -e ${editable_path}\n\nローカルパッケージを編集可能モードでインストールします"
        else
          reason="📦 パッケージをインストール:\n\n• プロジェクト依存として管理したい場合:\n  uv add ${packages}\n\n• 一時的/requirements.txt運用の場合:\n  uv pip install ${packages}"
        fi
      elif [[ "$pip_cmd" =~ ^uninstall ]]; then
        packages=$(echo "$pip_cmd" | sed 's/^uninstall *//' | sed 's/ -[^ ]*//g' | xargs)
        reason="🗑️ パッケージを削除:\n\n• プロジェクト依存として管理している場合:\n  uv remove ${packages}\n\n• pip互換運用の場合:\n  uv pip uninstall ${packages}"
      elif [[ "$pip_cmd" =~ ^list ]]; then
        reason="📊 パッケージ一覧を確認:\n\nuv pip list\n\n💡 依存関係ツリーを確認したい場合:\nuv tree"
      elif [[ "$pip_cmd" =~ ^freeze ]]; then
        reason="📋 インストール済みパッケージを出力:\n\nuv pip freeze\n\n💡 requirements.txtに書き出す場合:\nuv pip freeze > requirements.txt"
      else
        reason="🔀 pipコマンドをuvで実行:\n\nuv pip ${pip_cmd}\n\n💡 パッケージ管理には 'uv add/remove' を使用してください"
      fi
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0

    else
      reason="uvでモジュールを実行:\n\nuv run python -m ${module}\n\n🔄 uvは自動的に環境を同期してから実行します。"
      jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
      exit 0
    fi
  fi

  reason="uvでPythonを実行:\n\nuv run python ${args}\n\n✅ 仮想環境のアクティベーションは不要です！"
  jq -n --arg reason "$reason" '{"decision":"block","reason":$reason}'
  exit 0
fi

# デフォルトは承認
echo '{"decision": "approve"}'

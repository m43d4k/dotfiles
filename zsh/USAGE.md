## Usage

この `.zshrc` を導入すると、以下の機能が有効になります。

---

### 入力補助

- **過去のコマンド履歴から自動補完**（`zsh-autosuggestions`）
  - → 入力中に右端にグレーのサジェストが表示
  - → `→` キーや `Ctrl+E` で補完確定
- **構文の色分けハイライト**（`zsh-syntax-highlighting`）
  - → 存在するコマンドやパスは緑、存在しないものは赤など、色で状態を示します。

---

### よく使うコマンド（エイリアス）

| コマンド | 内容 |
|---------|------|
| `ll`    | `ls -alF`（詳細なファイル一覧） |
| `la`    | `ls -A`（隠しファイル含む） |
| `l`     | `ls -CF`（軽量表示） |
| `gs`    | `git status` |
| `gc`    | `git commit` |
| `..`    | `cd ..`（親ディレクトリに移動） |

---

### ディレクトリ移動を高速化：`zoxide`

- `z foo` → アクセス履歴があり、"foo" を含むディレクトリの中から、もっともよく使われた場所にジャンプ（使用頻度とアクセス時刻でスコアリング）
- `z` 単体 → もっとも頻繁に訪れたディレクトリにジャンプ (使用頻度とアクセス時刻でスコアリング)

---

### ファジー検索：`fzf`

- `Ctrl + R` → コマンド履歴を検索し、再実行
- `Ctrl + T` → カレントディレクトリ以下のファイルを検索し、カーソル位置にパスを挿入

---

### ripgrep連携：全文検索ツール `fzf_rg`

```sh
fzf_rg キーワード
```

- `ripgrep (rg)` でカレントディレクトリ以下を全文検索
- 結果を `fzf` で選ぶと、対応する行が `nvim` で開かれます
- `bat` によるプレビュー付き（`bat` のインストールが必要）

---

### Git 補助関数

#### `fgc`：Gitブランチ選択 → チェックアウト

```sh
fgc
```
- `fzf` でブランチを選択し、`git checkout` を実行

---

### 実行環境のバージョン管理：`mise`

```sh
mise use python@3.12
```
- プロジェクトフォルダごとに `python`, `node` などのバージョンを切り替え可能

#### ラッパー関数：`mvenv`

```sh
# mise で Python バージョンを指定して .venv を作成

mvenv 3.12
```

- `mise use "python@<version>"` を実行
- その後、`mise` が選んだ Python を使って `uv venv` で仮想環境を作成
- 例: `mvenv 3.12`

---

### Claude Code 用ローカルテンプレートのコピー

```sh
# .claude/ に settings.local.json と CLAUDE.local.md をコピー

claude_init
```

- `.claude` ディレクトリを作成
- `~/.config/zsh/template.settings.local.json` を `.claude/settings.local.json` にコピー
- `~/.config/zsh/template.CLAUDE.local.md` を `.claude/CLAUDE.local.md` にコピー
- 既に対象ファイルが存在する場合は上書きせず終了

---

### その他

- `git log` や `bat` の色が `less` 上でも表示されるように `LESS='-R'` を設定しています

---

## 前提ツール（最低限入れておく必要があるもの）

```sh
brew install zoxide fzf starship mise uv ripgrep bat jq
```

---

## 補足

- `.zsh_plugins.txt` に列挙したプラグインが Antidote によって読み込まれます
- `~/.cache/zsh/history` に履歴ファイルが保存され、セッション間で共有されます
- `FZF_DEFAULT_COMMAND` は `ripgrep` により高速化されています

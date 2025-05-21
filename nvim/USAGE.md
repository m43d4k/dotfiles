# Neovim Usage (macOS最小構成)

この `init.lua` では、最小限ながら実用的なNeovim環境が有効になります。特に macOS での使用を想定し、クリップボード連携や視認性の向上を重視しています。

---

## 基本設定

- 行番号と相対行番号を表示（`number` / `relativenumber`）
- 検索時に大文字小文字を自動判別（`ignorecase` / `smartcase`）
- カーソル行のハイライトやマッチペア表示など、視認性を改善
- ラップ行での移動を `gj` / `gk` に統一（`j` / `k` の再マッピング）

---

## インデント & 表示

- タブ幅は2スペースに統一（`tabstop` / `shiftwidth` / `expandtab`）
- 半角全角混在時の文字幅を正しく処理（`ambiwidth=double`）
- カラースキームは `tokyonight`（`termguicolors` 有効）

---

## 応答性 & Undo

- 入力応答時間を短縮（`ttimeoutlen=50`）
- 永続Undoを有効化（`.local/state/nvim/undo` に保存）

---

## キーマッピング

- `jj` → ノーマルモードに戻る（インサート中）
- `<Esc><Esc>` → 検索ハイライト解除
- `v i e`, `d i e`, `y i e` → 全体選択に対応
- 折り返された行でも上下に自然に移動できるよう、`j` / `k` を画面上の行単位に変更。
- 改行単位での移動には `gj` / `gk` を使用
- `gh` → 行頭（先頭の非空白文字）へ移動  
- `gl` → 行末（空白含む）へ移動  

---

## macOSクリップボード連携

- `ビジュアルモード + <space>y` → 選択範囲を macOS のクリップボードにコピー
- `ノーマルモード + <space>p` → macOSのクリップボードから貼り付け

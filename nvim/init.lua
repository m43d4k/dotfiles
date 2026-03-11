-- -*- coding:utf-8 -*-
-- Neovim configuration: minimal, macOS clipboard-friendly

--========================================
-- エンコーディング設定（デフォルトだが明示）
vim.o.encoding = 'utf-8'        -- Neovimは内部的にUTF-8。お作法として明示
vim.o.fileencoding = 'utf-8'    -- ファイル保存時の文字コード

--========================================
-- 基本設定
--========================================
vim.g.mapleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.hidden = true
vim.opt.cursorline = true
vim.opt.wrap = true
vim.opt.scrolloff = 5

-- 表示補助
vim.opt.ambiwidth = 'double'
vim.opt.visualbell = true
vim.opt.showmatch = true
vim.opt.matchtime = 1

-- インデント設定
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- 入力応答タイミング
vim.o.ttimeout = true
vim.o.ttimeoutlen = 50

-- 永続Undo
vim.o.undofile = true
vim.o.undodir = vim.fn.stdpath('cache') .. '/undo'
vim.fn.mkdir(vim.o.undodir, 'p')

vim.cmd("syntax on")
vim.opt.termguicolors = true
vim.cmd("colorscheme tokyonight")

--========================================
-- キーマッピング
--========================================

-- jj でノーマルモード
vim.keymap.set("i", "jj", "<Esc>", { noremap = true })

-- ESC ESC で検索ハイライト解除
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { noremap = true, silent = true })

-- 全体選択: v i e / d i e / y i e を有効にする
vim.keymap.set("o", "ie", ":<C-u>normal! ggVG<CR>", { noremap = true })
vim.keymap.set("x", "ie", ":<C-u>normal! ggVG<CR>", { noremap = true })

-- macOS クリップボード連携
vim.keymap.set("v", "<space>y", ":w !pbcopy<CR><CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<space>p", ":r !pbpaste<CR>", { noremap = true, silent = true })

-- j/k を wrap 対応に置き換え
vim.api.nvim_set_keymap('n', 'j', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', 'k', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', '<Down>', 'gj', { noremap = true })
vim.api.nvim_set_keymap('n', '<Up>', 'gk', { noremap = true })
vim.api.nvim_set_keymap('n', 'gj', 'j', { noremap = true })
vim.api.nvim_set_keymap('n', 'gk', 'k', { noremap = true })

-- gh で行頭、gl で行末に移動
vim.keymap.set("n", "gh", "^", { noremap = true })
vim.keymap.set("n", "gl", "g_", { noremap = true })


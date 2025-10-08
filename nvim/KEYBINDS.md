# Neovim Keybinds Cheatsheet

## File Navigation

### Finding Files (fzf-lua)
- `<leader>ff` or `<space>ff` - Find files
- `<leader>sg` or `<space>sg` - Search text in files (grep)
- `<leader><space>` - Find recent files
- `<leader>fb` - Find buffers

### Harpoon (Quick file jumping)
- `<leader>a` - Add current file to harpoon
- `<leader>h` - Toggle harpoon menu
- `<leader>1` - Jump to harpoon file 1
- `<leader>2` - Jump to harpoon file 2
- `<leader>3` - Jump to harpoon file 3
- `<leader>4` - Jump to harpoon file 4
- `<C-e>` - Next harpoon file
- `<C-q>` - Previous harpoon file

**Workflow:** Open your page component, press `<leader>a`. Open your component file, press `<leader>a`. Now use `<leader>1` and `<leader>2` to jump between them instantly!

## Git & Diffs

### Diffview
- `<leader>gd` - Open git diff
- `<leader>gh` - Current file history
- `<leader>gH` - Branch history
- `<leader>gq` - Close diffview
- `<C-n>` / `<C-p>` - Next/previous change (in diff view)
- `j` / `k` - Navigate files in file panel
- `q` - Close

### Lazygit
- `<leader>gg` - Open lazygit

## Diagnostics & Errors

### Viewing Errors (Trouble.nvim)
- `<leader>xx` - Toggle diagnostics list
- `<leader>xd` - Show document diagnostics
- `<leader>xw` - Show workspace diagnostics
- `<C-n>` / `<C-p>` - Jump to next/previous diagnostic
- `<leader>j` / `<leader>k` - Jump to next/previous diagnostic (alternative)
- `K` - Show hover info (shows full error details)
- `<leader>ca` - Code actions (fix errors)

### LSP
- `gd` - Go to definition
- `gr` - Go to references
- `gi` - Go to implementation
- `K` - Show hover documentation
- `<leader>rn` - Rename symbol

## Text Objects (mini.ai)

### Selection
- `vaf` / `vif` - Around/Inside function
- `vac` / `vic` - Around/Inside class
- `vao` / `vio` - Around/Inside code block
- `vat` / `vit` - Around/Inside HTML tag
- `va)` / `vi)` - Around/Inside parentheses (works with any bracket)
- `vag` / `vig` - Around/Inside whole buffer

### Operations
- `yinq` - Yank inside next quote
- `cinf` - Change inside next function
- `daf` - Delete around function
- Works with: `y` (yank), `d` (delete), `c` (change), `v` (visual)

## Surround (mini.surround)
- `csa"` - Add quotes around selection (visual) or word (normal)
- `csr"'` - Replace " with '
- `csd"` - Delete surrounding quotes
- `csf"` - Find next "

## Moving Code (mini.move)
- `<M-Up>` / `<M-Down>` - Move line or block up/down (Option+Arrow on Mac)
- `<M-Left>` / `<M-Right>` - Move left/right

## General
- `<leader>e` - Toggle file explorer
- `/` - Search in file
- `n` / `N` - Next/previous search result
- `<leader>w` - Save file
- `<leader>q` - Quit

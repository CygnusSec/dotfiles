-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.mouse = "a"
vim.cmd("colorscheme default") -- minimalist theme

-- KEY MAPPINGS like brew's flow
vim.keymap.set("n", "<C-s>", ":w<CR>")      -- Save
vim.keymap.set("n", "<C-q>", ":q<CR>")      -- Quit
vim.keymap.set("n", "<C-c>", ":noh<CR>")    -- Clear highlights

-- NO plugins for UI — lean setup

vim.opt.termguicolors = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.showbreak = "↪ "
vim.opt.textwidth = 80

vim.opt.splitright = true
vim.opt.splitbelow = false

vim.opt.number = true
vim.opt.relativenumber = false

vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

vim.opt.mouse = "a"
vim.opt.confirm = true

vim.opt.tabstop = 4 -- ancho de un tab en espacios
vim.opt.softtabstop = 4 -- cuanto mueve el cursor en insert
vim.opt.expandtab = true -- usar espacios en lugar de tabs
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·" }
vim.opt.virtualedit = "block" -- para selección de bloques respetando tabs
vim.opt.clipboard = "unnamedplus"
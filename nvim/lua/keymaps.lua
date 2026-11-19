vim.g.mapleader = " "

-- File search with Ctrl+f (like VSCode)
vim.api.nvim_create_user_command("Find", "Telescope find_files", {})

vim.keymap.set("n", "<C-f>", ":Find<CR>", { noremap = true, silent = true, desc = "Search files" })
vim.keymap.set("i", "<C-f>", "<Esc>:Find<CR>", { noremap = true, silent = true, desc = "Search files" })

-- Search in current directory with :FindHere or Ctrl+Shift+f
vim.api.nvim_create_user_command("FindHere", function()
	local search_dir = vim.fn.expand("%:p:h")
	-- Show notification with the search directory
	vim.schedule(function()
		vim.notify("🔍 " .. search_dir, vim.log.levels.INFO, {
			title = "Searching in:",
			timeout = 2000, -- Show for 2 seconds
			render = "minimal",
		})
	end)
	require("telescope.builtin").find_files({
		cwd = search_dir,
		prompt_title = "Searching: " .. vim.fn.fnamemodify(search_dir, ":t"),
	})
end, {})

vim.keymap.set("v", "<C-a>", "<Esc>ggVG", { desc = "Seleccionar todo" })

vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { desc = "Seleccionar todo" })

vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Seleccionar todo" })

vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>:lua vim.lsp.buf.format()<CR>")
vim.keymap.set("n", "<C-s>", ":w<CR>:lua vim.lsp.buf.format()<CR>")
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>:lua vim.lsp.buf.format()<CR>gv")

vim.keymap.set("n", " e", ":NvimTreeToggle<CR>", { noremap = true, silent = true, desc = "Toggle NvimTree" })

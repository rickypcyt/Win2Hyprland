local function is_executable(cmd)
	if vim.fn.executable(cmd[1]) == 1 then
		return true
	end
	vim.notify("Command not found: " .. cmd[1], vim.log.levels.WARN)
	return false
end

local function setup_lsp()
	local tsserver = { "typescript-language-server", "--stdio" }
	local clangd = { "clangd", "--background-index" }

	if tssserver and is_executable(tsserver) then
		vim.lsp.start({
			name = "tsserver",
			cmd = tsserver,
			filetypes = { "javascript", "typescript", "typescriptreact", "typescript.tsx" },
			root_dir = vim.fs.dirname(vim.fs.find({ "tsconfig.json", "package.json" }, { upward = true })[1])
				or vim.fn.getcwd(),
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end

	if is_executable(clangd) then
		vim.lsp.start({
			name = "clangd",
			cmd = clangd,
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
			root_dir = vim.fs.dirname(
				vim.fs.find({ "compile_commands.json", "compile_flags.txt", ".git" }, { upward = true })[1]
			) or vim.fn.getcwd(),
			on_attach = on_attach,
			capabilities = capabilities,
		})
	end
end

setup_lsp()

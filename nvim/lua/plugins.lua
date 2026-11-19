-- Instalar lazy.nvim si no está (en Windows: %LOCALAPPDATA%\nvim-data\lazy\lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local out = vim.fn.system({
		"git", "clone", "--filter=blob:none", "--branch=stable",
		"https://github.com/folke/lazy.nvim.git", lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("Error clonando lazy.nvim:\n" .. out)
	end
end
vim.opt.rtp:prepend(lazypath)

local lazy = require("lazy")

lazy.setup({
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
	},

	-- Harpoon: Navegación rápida entre archivos
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("harpoon").setup()
		end,
	},

	-- Git
	{ "chrisbra/csv.vim", ft = "csv" },
	{
		"tpope/vim-fugitive",
		cmd = { "G", "Git", "Gstatus", "Gdiff", "Gcommit" },
	},

	-- Snippets
	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Surround
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup()
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- Autotag
	{
		"windwp/nvim-ts-autotag",
		ft = { "html", "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "xml" },
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},

	-- Telescope
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
			"nvim-telescope/telescope-project.nvim",
		},
		config = function()
			local actions = require("telescope.actions")
			local fb_actions = require("telescope").extensions.file_browser.actions

			require("telescope").setup({
				defaults = {
					mappings = {
						n = {
							["q"] = actions.close,
						},
					},
				},
				extensions = {
					file_browser = {
						theme = "dropdown",
						-- disables netrw and use telescope-file-browser in its place
						hijack_netrw = true,
						mappings = {
							["i"] = {
								["<C-n>"] = fb_actions.create,
								["<C-r>"] = fb_actions.rename,
								["<C-d>"] = fb_actions.remove,
								["<C-h>"] = fb_actions.toggle_hidden,
								["<C-x>"] = fb_actions.move,
								["<C-c>"] = fb_actions.copy,
								["<C-p>"] = fb_actions.goto_parent_dir,
							},
							["n"] = {
								["n"] = fb_actions.create,
								["r"] = fb_actions.rename,
								["d"] = fb_actions.remove,
								["h"] = fb_actions.goto_parent_dir,
								["l"] = actions.select_default,
								["/"] = function()
									vim.cmd("startinsert")
								end,
							},
						},
					},
					project = {
						-- Windows: C:/coding. Arch (WSL): la misma carpeta vista desde Linux
						base_dirs = vim.fn.has("win32") == 1 and { "C:/coding" } or { "/mnt/c/coding" },
						hidden_files = true,
						theme = "dropdown",
					},
				},
			})

			-- Cargar extensiones
			require("telescope").load_extension("file_browser")
			pcall(require("telescope").load_extension, "project") -- Cargar solo si está disponible

			-- Atajos de teclado
			local builtin = require("telescope.builtin")
			local fb = require("telescope").extensions.file_browser

			-- Comandos personalizados
			vim.api.nvim_create_user_command("Find", function()
				builtin.find_files()
			end, {})

			vim.api.nvim_create_user_command("FindHere", function()
				fb.file_browser({
					path = vim.fn.expand("%:p:h"),
					select_buffer = true,
					hidden = true,
					respect_gitignore = true,
					grouped = true,
					initial_mode = "normal",
					layout_config = {
						height = 0.8,
						width = 0.8,
					},
				})
			end, {})

			vim.api.nvim_create_user_command("FindParent", function()
				local current_file = vim.fn.expand("%:p")
				local parent_dir = vim.fn.fnamemodify(current_file, ":h:h")
				fb.file_browser({
					path = parent_dir,
					select_buffer = true,
					hidden = true,
					respect_gitignore = true,
					grouped = true,
					initial_mode = "normal",
					layout_config = {
						height = 0.8,
						width = 0.8,
					},
				})
			end, {})

			-- Atajos de teclado
			vim.keymap.set("n", "<leader>ff", ":Find<CR>", { noremap = true, desc = "Buscar archivos" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Buscar en archivos" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Ver buffers abiertos" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Ayuda" })
			vim.keymap.set("n", "<leader>fe", ":FindHere<CR>", { noremap = true, desc = "Explorar desde aquí" })
			vim.keymap.set("n", "<leader>fp", ":FindParent<CR>", { noremap = true, desc = "Explorar directorio padre" })

			-- Crear nuevo buffer con Ctrl+T
			vim.keymap.set("n", "<C-t>", ":enew<CR>", { noremap = true, desc = "Nuevo buffer" })

			-- NvimTree toggle
			vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
		end,
	},

	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		config = function()
			require("lsp_lines").setup()
		end,
	},
	{ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

	-- Nvim-tree
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				sort = { sorter = "case_sensitive" },
				view = { width = 30 },
				renderer = { group_empty = true },
				filters = { dotfiles = true },
			})
		end,
	},

	-- Notify
	{
		"rcarriga/nvim-notify",
		config = function()
			require("notify").setup({
				stages = "fade_in_slide_out",
				timeout = 3000,
				render = "wrapped-compact",
			})
			vim.notify = require("notify")
		end,
	},

	-- Alpha dashboard
	{
		"goolord/alpha-nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VimEnter",
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")

			-- Set header
			dashboard.section.header.val = { [[Hola]] }

			-- Set up dashboard buttons
			dashboard.section.buttons.val = {
				dashboard.button("e", "  New file", "<cmd>ene <CR>"),
				dashboard.button("f", "  Find file", "<cmd>Telescope find_files<CR>"),
				dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<CR>"),
				dashboard.button("q", "  Quit", "<cmd>qa<CR>"),
			}

			dashboard.section.buttons.val = {
				dashboard.button("f", "🔍  Find File", ":Telescope find_files<CR>"),
				dashboard.button("r", "🕘  Recent Files", ":Telescope oldfiles<CR>"),
				dashboard.button("p", "📁  Find Project", ":Telescope projects<CR>"),
				dashboard.button("n", "📄  New File", ":ene <BAR> startinsert <CR>"),
				dashboard.button("q", "❌  Quit NVIM", ":qa<CR>"),
			}

			dashboard.section.footer.val = "Happy hacking 💻"

			local function get_recent_folders(limit)
				local folders = {}
				local seen = {}
				for _, file in ipairs(vim.v.oldfiles) do
					local dir = vim.fn.fnamemodify(file, ":h")
					if vim.fn.isdirectory(dir) == 1 and not seen[dir] then
						seen[dir] = true
						table.insert(folders, dir)
					end
					if #folders >= limit then
						break
					end
				end
				return folders
			end

			local function recent_folders_section()
				local folders = get_recent_folders(5)
				local buttons = {}
				table.insert(
					buttons,
					{ type = "text", val = "Recent Folders:", opts = { position = "center", hl = "Type" } }
				)
				if #folders == 0 then
					table.insert(buttons, {
						type = "text",
						val = "No recent folders found",
						opts = { position = "center", hl = "Comment" },
					})
				else
					for i, folder in ipairs(folders) do
						table.insert(
							buttons,
							dashboard.button(
								tostring(i),
								folder,
								string.format(":cd %s | Telescope find_files<CR>", vim.fn.fnameescape(folder))
							)
						)
					end
				end
				return { type = "group", val = buttons, opts = { spacing = 1 } }
			end

			dashboard.section.recent_folders = recent_folders_section()

			dashboard.config.layout = {
				dashboard.section.header,
				dashboard.section.buttons,
				dashboard.section.recent_folders,
				dashboard.section.footer,
			}

			dashboard.opts.opts.noautocmd = true
			alpha.setup(dashboard.config)
		end,
	},

	-- Lualine
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local colors = {
				blue = "#80a0ff",
				cyan = "#79dac8",
				black = "#080808",
				white = "#c6c6c6",
				red = "#ff5189",
				violet = "#d183e8",
				grey = "#303030",
			}
			local bubbles_theme = {
				normal = {
					a = { fg = colors.black, bg = colors.violet },
					b = { fg = colors.white, bg = colors.grey },
					c = { fg = colors.white },
				},
				insert = { a = { fg = colors.black, bg = colors.blue } },
				visual = { a = { fg = colors.black, bg = colors.cyan } },
				replace = { a = { fg = colors.black, bg = colors.red } },
				inactive = {
					a = { fg = colors.white, bg = colors.black },
					b = { fg = colors.white, bg = colors.black },
					c = { fg = colors.white },
				},
			}
			require("lualine").setup({
				options = {
					theme = bubbles_theme,
					component_separators = "",
					section_separators = { left = "", right = "" },
				},
				sections = {
					lualine_a = { { "mode", separator = { left = "" }, right_padding = 2 } },
					lualine_b = { "filename", "branch" },
					lualine_c = { "%=" },
					lualine_x = {},
					lualine_y = { "filetype", "progress" },
					lualine_z = { { "location", separator = { right = "" }, left_padding = 2 } },
				},
				inactive_sections = {
					lualine_a = { "filename" },
					lualine_b = {},
					lualine_c = {},
					lualine_x = {},
					lualine_y = {},
					lualine_z = { "location" },
				},
				tabline = {},
				extensions = {},
			})
		end,
	},

	-- Hop
	{
		"smoka7/hop.nvim", -- phaazon/hop.nvim fue borrado de GitHub; este es el fork mantenido
		config = function()
			require("hop").setup()
		end,
	},

	-- Bufferline
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			require("bufferline").setup({
				options = {
					numbers = "none",
					close_command = "bdelete! %d",
					right_mouse_command = "bdelete! %d",
					show_buffer_icons = true,
					show_close_icon = true,
					show_tab_indicators = true,
					persist_buffer_sort = true,
					separator_style = "slant",
					enforce_regular_tabs = true,
					-- Enable mouse wheel scrolling
					offsets = {
						{
							filetype = "NvimTree",
							text = "File Explorer",
							highlight = "Directory",
							separator = true,
						},
					},
					-- Enable mouse support
					hover = {
						enabled = true,
						delay = 200,
						reveal = { "close" },
					},
				},
			})
		end,
	},

	-- Conform
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
			formatters_by_ft = { lua = { "stylua" } },
		},
	},

	-- Null-ls
	{
		"nvimtools/none-ls.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = { null_ls.builtins.formatting.prettier, null_ls.builtins.formatting.stylua },
				on_attach = function(client, bufnr)
					if client.supports_method("textDocument/formatting") then
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							callback = function()
								vim.lsp.buf.format({ bufnr = bufnr })
							end,
						})
					end
				end,
			})
		end,
	},

	-- LSP Config
	-- TypeScript Tools
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		config = function()
			require("typescript-tools").setup({
				on_attach = function(client, bufnr)
					-- You can add custom keymaps or other on_attach functionality here
				end,
				handlers = {},
				settings = {
					separate_diagnostic_server = true,
					publish_diagnostic_on = "insert_leave",
					expose_as_code_action = {},
					tsserver_path = nil,
					tsserver_plugins = {},
					tsserver_max_memory = "auto",
					tsserver_format_options = {},
					tsserver_file_preferences = {},
					tsserver_locale = "en",
					complete_function_calls = false,
					include_completions_with_insert_text = true,
					code_lens = "off",
					disable_member_code_lens = true,
					jsx_close_tag = {
						enable = false,
						filetypes = { "javascriptreact", "typescriptreact" },
					},
				},
			})
		end,
	},

	-- LSP Config
	{
		"neovim/nvim-lspconfig",
		config = function()
			-- Common on_attach function for all LSP clients
			local on_attach = function(client, bufnr)
				local bufopts = { noremap = true, silent = true, buffer = bufnr }
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
				vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
			end

			-- Setup default capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- Check if we're using Neovim 0.11+ with the new API
			local use_new_api = vim.fn.has("nvim-0.11") == 1

			if use_new_api then
				-- New API (Neovim 0.11+)
				-- Configure lua_ls
				vim.lsp.config.lua_ls = {
					cmd = { "lua-language-server" },
					root_markers = {
						".luarc.json",
						".luarc.jsonc",
						".luacheckrc",
						".stylua.toml",
						"stylua.toml",
						"selene.toml",
						"selene.yml",
						".git",
					},
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = { library = vim.api.nvim_get_runtime_file("", true) },
							telemetry = { enable = false },
						},
					},
					capabilities = capabilities,
					on_attach = on_attach,
				}

				-- Configure other servers with new API
				local servers = {
					{ name = "pyright", cmd = { "pyright-langserver", "--stdio" } },
					{ name = "html", cmd = { "vscode-html-language-server", "--stdio" } },
					{ name = "cssls", cmd = { "vscode-css-language-server", "--stdio" } },
					{ name = "clangd", cmd = { "clangd" } },
				}

				for _, server in ipairs(servers) do
					vim.lsp.config[server.name] = {
						cmd = server.cmd,
						root_markers = { ".git" },
						capabilities = capabilities,
						on_attach = on_attach,
					}
				end

				-- Enable LSP servers
				vim.lsp.enable({ "lua_ls", "pyright", "html", "cssls", "clangd" })
			else
				-- Old API (Neovim < 0.11)
				local lspconfig = require("lspconfig")

				-- Lua LSP configuration
				lspconfig.lua_ls.setup({
					on_attach = on_attach,
					capabilities = capabilities,
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = { library = vim.api.nvim_get_runtime_file("", true) },
							telemetry = { enable = false },
						},
					},
				})

				-- Other language servers
				local servers = { "pyright", "html", "cssls", "clangd" }
				for _, server in ipairs(servers) do
					lspconfig[server].setup({
						on_attach = on_attach,
						capabilities = capabilities,
					})
				end
			end
		end,
	},
})

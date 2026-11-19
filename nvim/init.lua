-- La misma config se usa en Windows y en Arch (WSL): ~/.config/nvim enlaza aquí.
local IS_WIN = vim.fn.has("win32") == 1
local WSL_DOMAIN = "WSL:archlinux"

-- Abrir una terminal (WezTerm, en Linux era kitty) en la carpeta del archivo actual.
-- :Kitty se mantiene por costumbre; :Term hace lo mismo.
-- Windows: PowerShell en esa carpeta. Arch: zsh en esa carpeta.
local function open_terminal()
        local path = vim.fn.expand("%:p:h")
        if IS_WIN then
                vim.fn.jobstart({ "wezterm-gui", "start", "--domain", "local", "--cwd", path }, { detach = true })
        else
                vim.fn.jobstart({ "wezterm.exe", "start", "--domain", WSL_DOMAIN, "--cwd", path }, { detach = true })
        end
end
vim.api.nvim_create_user_command("Kitty", open_terminal, { desc = "Terminal en la carpeta del archivo" })
vim.api.nvim_create_user_command("Term", open_terminal, { desc = "Terminal en la carpeta del archivo" })

-- GCC: compilar el .c actual y ejecutarlo en una ventana de WezTerm que se queda abierta
-- Windows: gcc de MSYS2 UCRT64 (genera nombre.exe). Arch: gcc de Linux (genera ./nombre).
vim.api.nvim_create_user_command("GCC", function()
        local dir = vim.fn.expand("%:p:h")
        local name = vim.fn.expand("%:t:r")
        local exe = dir .. "/" .. name .. (IS_WIN and ".exe" or "")
        local out = vim.fn.system({ "gcc", vim.fn.expand("%:p"), "-o", exe })
        if vim.v.shell_error ~= 0 then
                vim.notify(out, vim.log.levels.ERROR, { title = "gcc" })
                return
        end
        if IS_WIN then
                vim.fn.jobstart({ "wezterm-gui", "start", "--domain", "local", "--cwd", dir, "--", "cmd", "/k", name .. ".exe" }, { detach = true })
        else
                vim.fn.jobstart({ "wezterm.exe", "start", "--domain", WSL_DOMAIN, "--cwd", dir, "--",
                        "zsh", "-c", "./" .. name .. "; exec zsh" }, { detach = true })
        end
end, { desc = "Compilar y ejecutar el archivo C en WezTerm" })

-- Restaurar cursor al abrir archivos
vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function()
                local mark = vim.api.nvim_buf_get_mark(0, '"')
                local lcount = vim.api.nvim_buf_line_count(0)
                if mark[1] > 0 and mark[1] <= lcount then
                        vim.api.nvim_win_set_cursor(0, mark)
                end
        end,
})

local config_modules = {
        "options",
        "keymaps",
        "plugins",
        "lsp.formatting",
}

for _, module in ipairs(config_modules) do
        require(module)
end

vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
})

vim.cmd.colorscheme("cyberdream")
vim.cmd([[
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NormalNC guibg=NONE ctermbg=NONE
    highlight EndOfBuffer guibg=NONE ctermbg=NONE
]])
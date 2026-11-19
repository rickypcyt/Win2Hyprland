-- La misma config se usa en Windows y en Arch (WSL): ~/.config/nvim enlaza aquí.
local IS_WIN = vim.fn.has("win32") == 1
-- Terminal: Alacritty (en Linux era kitty). Desde Arch se llama a su .exe de Windows.
local TERM = IS_WIN and "alacritty" or "alacritty.exe"
-- Abrir zsh de Arch en una carpeta (wsl --cd acepta rutas de Windows y de Linux)
local function arch_shell(dir, ...)
        return vim.list_extend({ TERM, "-e", "wsl.exe", "-d", "archlinux", "-u", "ricky", "--cd", dir }, { ... })
end

-- Abrir una terminal en la carpeta del archivo actual: zsh de Arch, desde
-- Windows o desde Arch (wsl --cd acepta rutas de los dos).
-- :Kitty se mantiene por costumbre; :Term hace lo mismo.
local function open_terminal()
        vim.fn.jobstart(arch_shell(vim.fn.expand("%:p:h")), { detach = true })
end
vim.api.nvim_create_user_command("Kitty", open_terminal, { desc = "Terminal en la carpeta del archivo" })
vim.api.nvim_create_user_command("Term", open_terminal, { desc = "Terminal en la carpeta del archivo" })

-- GCC: compilar el .c actual y ejecutarlo en una ventana de Alacritty que se queda abierta
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
                vim.fn.jobstart({ TERM, "--working-directory", dir, "-e", "cmd", "/k", name .. ".exe" }, { detach = true })
        else
                vim.fn.jobstart(arch_shell(dir, "--", "zsh", "-c", "./" .. name .. "; exec zsh"), { detach = true })
        end
end, { desc = "Compilar y ejecutar el archivo C en Alacritty" })

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
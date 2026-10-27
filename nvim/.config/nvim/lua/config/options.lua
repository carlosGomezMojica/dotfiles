-- Opciones; se cargan antes de lazy.nvim. Las de LazyVim por defecto:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Portapapeles compartido con el sistema (wl-copy/wl-paste de wl-clipboard): y/p usan el de
-- Wayland, así que lo copiado en nvim pasa también por cliphist (SUPER + SHIFT + V).
-- LazyVim lo desactiva por SSH; aquí va siempre
vim.opt.clipboard = "unnamedplus"

-- Ortografía en español e inglés (se activa con <leader>us)
vim.opt.spelllang = { "es", "en" }

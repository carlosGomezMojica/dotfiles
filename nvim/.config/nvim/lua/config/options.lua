-- Opciones; se cargan antes de lazy.nvim. Las de LazyVim por defecto:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Portapapeles compartido con el sistema (wl-copy/wl-paste de wl-clipboard): y/p usan el de
-- Wayland, así que lo copiado en nvim pasa también por cliphist (SUPER + SHIFT + V).
-- LazyVim lo desactiva por SSH; aquí va siempre
vim.opt.clipboard = "unnamedplus"

-- Ortografía en español e inglés. LazyVim la activa sola en markdown, texto y commits
-- (<leader>us la alterna); el diccionario de español lo descarga nvim la primera vez.
-- `zg` añade una palabra a spell/es.utf-8.add (en el repo) y `zw` la marca como incorrecta
vim.opt.spelllang = { "es", "en" }
vim.opt.spellfile = vim.fn.stdpath("config") .. "/spell/es.utf-8.add"
-- Palabras compuestas en camelCase se revisan por partes
vim.opt.spelloptions:append("camel")

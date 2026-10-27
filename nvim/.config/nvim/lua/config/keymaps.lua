-- Atajos; se cargan en el evento VeryLazy. Los de LazyVim por defecto:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Moverse entre splits como el foco de Hyprland en Dvorak: H/S/N/T = izq/der/arriba/abajo.
-- Se mantienen también los <C-h/j/k/l> de LazyVim. En modo normal <C-s> deja de guardar
-- (sigue guardando en insert/visual) y <C-t> deja de volver de un tag (usar <C-o>).
pcall(vim.keymap.del, "n", "<C-s>")
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Ir al split de la izquierda", remap = true })
vim.keymap.set("n", "<C-s>", "<C-w>l", { desc = "Ir al split de la derecha", remap = true })
vim.keymap.set("n", "<C-n>", "<C-w>k", { desc = "Ir al split de arriba", remap = true })
vim.keymap.set("n", "<C-t>", "<C-w>j", { desc = "Ir al split de abajo", remap = true })

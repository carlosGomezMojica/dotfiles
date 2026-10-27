-- Colorschemes de los temas del sistema; cuál se usa lo decide config/theme.lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = { flavour = "mocha" },
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    -- Fondo "hard" (#1d2021), como el bg de la paleta gruvbox-dark
    opts = { contrast = "hard" },
  },
  -- Respaldo para temas sin colorscheme propio: se genera con la paleta
  { "nvim-mini/mini.base16", lazy = true },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local theme = require("config.theme")
        theme.apply()
        theme.watch()
      end,
    },
  },
}

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
    -- Contraste "hard": #1d2021 en oscuro y #f9f5d7 en claro, como el bg de gruvbox-dark/-light
    opts = { contrast = "hard" },
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    -- Variante "wave" (#1f1f28), como el bg de la paleta kanagawa
    opts = { theme = "wave" },
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

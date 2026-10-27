-- oil.nvim: edita directorios como un buffer (renombrar, mover o borrar = editar líneas y :w)
return {
  {
    "stevearc/oil.nvim",
    lazy = false, -- para abrir directorios (`nvim .`) desde el arranque
    dependencies = { "nvim-mini/mini.icons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Abrir el directorio del archivo (oil)" },
    },
    opts = {
      default_file_explorer = true,
      -- Muestra los ocultos (punto) por defecto; `g.` los alterna
      view_options = { show_hidden = true },
    },
  },
  -- Los directorios los abre oil; el explorador lateral de snacks (<leader>e) sigue igual
  {
    "folke/snacks.nvim",
    opts = { explorer = { replace_netrw = false } },
  },
}

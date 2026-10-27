-- Markdown: render-markdown y markdown-preview vienen del extra lang.markdown de LazyVim.
-- Aquí: imágenes en el buffer (snacks.image, kitty) y pegar imágenes del portapapeles (img-clip)
local vault = vim.fn.expand("~/Documentos/notas")

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- Sin LaTeX instalado: las fórmulas se dejan como texto
      latex = { enabled = false },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      -- Pinta en el buffer las imágenes de ![](...) y ![[...]] con el protocolo gráfico de kitty;
      -- jpg, webp, gif… se convierten a png con imagemagick
      image = {
        enabled = true,
        doc = { inline = true, float = true, max_width = 80, max_height = 30 },
      },
    },
  },
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>ip", "<cmd>PasteImage<cr>", desc = "Pegar imagen del portapapeles" },
    },
    opts = {
      default = {
        -- Fuera del vault: assets/ junto al archivo, con enlace markdown normal
        dir_path = "assets",
        relative_to_current_file = true,
        file_name = "%Y-%m-%d_%H-%M-%S",
        prompt_for_file_name = false,
        -- También al soltar un archivo de imagen arrastrado sobre la terminal
        drag_and_drop = { enabled = true, insert_mode = true },
      },
      dirs = {
        -- En el vault: todas en <vault>/assets y enlace de Obsidian
        [vault] = {
          dir_path = vault .. "/assets",
          relative_to_current_file = false,
          template = "![[$FILE_NAME]]",
        },
      },
    },
  },
}

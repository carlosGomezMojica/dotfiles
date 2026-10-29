-- Markdown: render-markdown y markdown-preview vienen del extra lang.markdown de LazyVim.
-- Aquí: imágenes en el buffer (snacks.image, kitty) y pegar imágenes del portapapeles (img-clip)
local vault = vim.fn.expand("~/Documentos/notas")
-- Reglas de markdownlint compartidas por el linter y el formateo al guardar
local mdlint_config = vim.fn.stdpath("config") .. "/.markdownlint.yaml"

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = { args = { "--config", mdlint_config, "-" } },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdownlint-cli2"] = { prepend_args = { "--config", mdlint_config } },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- Sin LaTeX instalado: las fórmulas se dejan como texto
      latex = { enabled = false },
    },
  },
  {
    "folke/snacks.nvim",
    init = function()
      -- snacks.image arranca con BufReadPre, que no salta al abrir un archivo nuevo (`nvim nota.md`
      -- sin existir, o `:e` de uno nuevo): sin esto esa sesión no pinta imágenes.
      -- Va en init, y no en autocmds.lua (VeryLazy), para llegar a tiempo al archivo de la línea de órdenes
      vim.api.nvim_create_autocmd("BufNewFile", {
        group = vim.api.nvim_create_augroup("snacks_image_newfile", { clear = true }),
        callback = function(e)
          if not Snacks.config.image.enabled then
            return
          end
          Snacks.image.setup()
          -- El FileType de este buffer ya pasó, así que lo enganchamos a mano
          vim.schedule(function()
            local lang = vim.treesitter.language.get_lang(vim.bo[e.buf].filetype)
            if vim.api.nvim_buf_is_valid(e.buf) and vim.tbl_contains(Snacks.image.langs(), lang) then
              Snacks.image.doc.attach(e.buf)
            end
          end)
        end,
      })
    end,
    opts = {
      -- Pinta en el buffer las imágenes de ![](...) y ![[...]] con el protocolo gráfico de kitty;
      -- jpg, webp, gif… se convierten a png con imagemagick
      image = {
        enabled = true,
        doc = { inline = true, float = true, max_width = 80, max_height = 30 },
        -- Bloques ```mermaid con mmdc (mermaid-cli) y los colores de la paleta activa.
        -- La imagen se cachea por contenido: tras cambiar de tema, solo se recolorea al editar el bloque
        convert = {
          mermaid = function()
            return {
              "-i", "{src}", "-o", "{file}", "-b", "transparent", "-s", "{scale}",
              "-c", require("config.theme").mermaid_config(),
            }
          end,
        },
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

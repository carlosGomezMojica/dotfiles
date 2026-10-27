-- Web: TS/JS (extra lang.typescript), ESLint, Prettier y Tailwind vienen de extras en config/lazy.lua.
-- Aquí: LSP de HTML, CSS y Emmet, y prettier en las notas sin repartir párrafos
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        -- CSS, SCSS y Less (también avisa de propiedades desconocidas o reglas vacías)
        cssls = {},
        -- Abreviaturas (div.card>ul>li*3): se escriben y se aceptan en el menú de completado
        emmet_language_server = {
          filetypes = { "html", "css", "scss", "less", "javascriptreact", "typescriptreact", "vue", "svelte" },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "html", "css", "scss", "javascript", "typescript", "tsx" } },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        -- En markdown, prettier deja los párrafos como están (markdownlint va detrás con su --fix)
        prettier = {
          prepend_args = function(_, ctx)
            if vim.bo[ctx.buf].filetype == "markdown" then
              return { "--prose-wrap", "preserve" }
            end
            return {}
          end,
        },
      },
    },
  },
}

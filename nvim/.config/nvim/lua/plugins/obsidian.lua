-- obsidian.nvim: notas del vault ~/Documentos/notas (enlaces [[...]], diario, etiquetas, backlinks)
local vault = vim.fn.expand("~/Documentos/notas")

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cmd = "Obsidian",
    keys = {
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Nueva nota" },
      { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Buscar nota" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Buscar en las notas" },
      { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Nota de hoy" },
      { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Nota de ayer" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Enlaces de la nota" },
      { "<leader>og", "<cmd>Obsidian tags<cr>", desc = "Etiquetas" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Renombrar nota" },
      { "<leader>oc", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Alternar casilla" },
    },
    opts = {
      legacy_commands = false, -- solo `:Obsidian <subcomando>`
      workspaces = { { name = "notas", path = vault } },
      -- Nombre del archivo = título legible (no el id aleatorio por defecto)
      note_id_func = function(title)
        return require("obsidian.builtin").title_id(title)
      end,
      new_notes_location = "notes_subdir",
      picker = { name = "snacks.picker" },
      daily_notes = { folder = "diario", date_format = "YYYY-MM-DD", workdays_only = false, default_tags = { "diario" } },
      -- Las imágenes las pega img-clip en la misma carpeta; esto solo afecta a `:Obsidian paste_img`
      attachments = { folder = "assets" },
      -- La interfaz (casillas, enlaces, títulos) la pinta render-markdown
      ui = { enable = false },
    },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>o", group = "obsidian", icon = "󰠮" } } },
  },
}

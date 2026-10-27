-- Dashboard de inicio: cabecera NEOVIM con cada letra en un color del tema (config/theme.lua)

-- ASCII "NEOVIM" de snacks y ancho en columnas de cada letra
local art = {
  "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
  "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
  "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
  "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
  "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
  "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
}
local widths = { 10, 8, 9, 9, 3, 11 }

-- Trozos {texto, hl} línea a línea; snacks empieza línea nueva con cada "\n"
local function header()
  local chunks = {}
  for l, line in ipairs(art) do
    local col = 0
    for i, w in ipairs(widths) do
      local piece = vim.fn.strcharpart(line, col, w)
      if l > 1 and i == 1 then
        piece = "\n" .. piece
      end
      table.insert(chunks, { piece, hl = "DashboardLetter" .. i })
      col = col + w
    end
  end
  return { text = chunks, align = "center", padding = 2 }
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          header,
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}

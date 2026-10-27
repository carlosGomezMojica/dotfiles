-- Sigue el tema del sistema (~/.config/theme/current, lo escribe el script `theme`)
local M = {}

local dir = vim.fn.expand("~/.config/theme")

-- Tema del sistema → colorscheme de nvim. Los que no estén aquí usan mini.base16 con la paleta
M.schemes = {
  ["catppuccin-mocha"] = "catppuccin-mocha",
  ["gruvbox-dark"] = "gruvbox",
}

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

function M.current()
  return vim.trim(read(dir .. "/current") or "")
end

-- Nombre del colorscheme del tema activo (nil si no tiene uno propio)
function M.colorscheme()
  return M.schemes[M.current()]
end

-- mini.base16 con los colores de terminal de la paleta (mismo orden que base16)
local function base16(name)
  local ok, palette = pcall(vim.json.decode, read(dir .. "/palettes/" .. name .. ".json") or "")
  if not ok or type(palette) ~= "table" then
    return false
  end
  local c = function(n)
    return palette["color" .. n]
  end
  require("mini.base16").setup({
    palette = {
      base00 = palette.bg or palette.background,
      base01 = c(0),
      base02 = palette.surface or c(8),
      base03 = c(8),
      base04 = palette.muted or c(7),
      base05 = palette.foreground or c(7),
      base06 = c(7),
      base07 = c(15),
      base08 = c(9),
      base09 = palette.warning or c(3),
      base0A = c(11),
      base0B = c(10),
      base0C = c(14),
      base0D = c(12),
      base0E = c(13),
      base0F = c(1),
    },
  })
  vim.g.colors_name = "theme-" .. name
  return true
end

function M.apply()
  local name = M.current()
  local scheme = M.schemes[name]
  if scheme and pcall(vim.cmd.colorscheme, scheme) then
    return
  end
  if not base16(name) then
    pcall(vim.cmd.colorscheme, "habamax")
  end
end

-- Recarga el colorscheme cuando `theme` cambia `current` (en todas las instancias abiertas)
local watcher
function M.watch()
  if watcher then
    return
  end
  watcher = vim.uv.new_fs_event()
  watcher:start(dir, {}, function(err, file)
    if not err and file == "current" then
      vim.schedule(M.apply)
    end
  end)
  -- Respaldo por si el aviso se pierde (p. ej. si `current` se sustituye por otro archivo)
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("theme_sync", { clear = true }),
    callback = function()
      local scheme = M.schemes[M.current()] or ("theme-" .. M.current())
      if vim.g.colors_name ~= scheme then
        M.apply()
      end
    end,
  })
end

return M


-------------------
-----TEMA----------
-------------------
-- Paleta activa, compartida con Quickshell (~/.config/theme).
-- Uso: local theme = require("theme"); theme.rgba(theme.accent, "ee")

-- Valores por defecto: Catppuccin Mocha (si falta el archivo o un token)
local theme = {
    bg              = "000000",
    border          = "1f1f1f",
    accent          = "cba6f7",
    muted           = "9399b2",
    surface         = "313244",
    text            = "cdd6f4",
    success         = "a6e3a1",
    error           = "f38ba8",
    warning         = "fab387",
    panel_border    = "313244",
    border_active_2 = "89b4fa",
    border_inactive = "45475a",
    shadow          = "11111b",
}

local function read(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("a")
    f:close()
    return content
end

local dir = os.getenv("HOME") .. "/.config/theme"
local name = (read(dir .. "/current") or "catppuccin-mocha"):gsub("%s+", "")
local json = read(dir .. "/palettes/" .. name .. ".json") or ""

-- JSON plano: "token": "#rrggbb"
for key, hex in json:gmatch('"([%w_]+)"%s*:%s*"#(%x+)"') do
    theme[key] = hex
end

theme.name = name

-- "cba6f7", "ee" -> "rgba(cba6f7ee)"
function theme.rgba(hex, alpha)
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return theme

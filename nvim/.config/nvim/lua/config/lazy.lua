-- Bootstrap de lazy.nvim (se clona la primera vez en ~/.local/share/nvim/lazy)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "No se pudo clonar lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPulsa una tecla para salir..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim y sus plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Extras declarados aquí (y no en lazyvim.json) para que la config sea reproducible
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    -- Plugins propios de lua/plugins/
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false, -- siempre la última versión de git (las versiones fijas se guardan en lazy-lock.json)
  },
  -- Colorscheme mientras se instalan los plugins la primera vez
  install = { colorscheme = { require("config.theme").colorscheme(), "habamax" } },
  -- Busca actualizaciones de plugins sin avisar cada vez
  checker = { enabled = true, notify = false },
  -- Ningún plugin de los que se usan necesita luarocks
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

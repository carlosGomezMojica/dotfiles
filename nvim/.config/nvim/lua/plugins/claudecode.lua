-- claudecode.nvim (extra ai.claudecode en config/lazy.lua): nvim hace de IDE para Claude Code con
-- el protocolo de la extensión de VS Code. Claude Code se abre en un split (<leader>ac) o, desde
-- otra terminal, se conecta con `/ide`; ve el archivo y la selección actuales y abre los diffs aquí
return {
  {
    "coder/claudecode.nvim",
    -- Sin cargar al arrancar, el servidor no existe hasta pulsar un atajo y `/ide` no ve este nvim
    lazy = false,
  },
}

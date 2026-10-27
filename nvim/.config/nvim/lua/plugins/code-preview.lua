-- code-preview.nvim: muestra en nvim el diff de cada edición de Claude Code antes de aceptarla.
-- Los hooks son por proyecto: `:CodePreviewInstallClaudeCodeHooks` en la raíz del proyecto
-- (escribe .claude/settings.local.json) y reiniciar Claude Code. Necesita jq.
return {
  {
    "Cannon07/code-preview.nvim",
    lazy = false, -- los hooks hablan con nvim por RPC en cualquier momento
    opts = {},
  },
}

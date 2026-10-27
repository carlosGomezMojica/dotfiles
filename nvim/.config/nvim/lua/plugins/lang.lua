-- Lenguajes de estos dotfiles: Lua (Hyprland, lo trae LazyVim), QML (Quickshell) y shell

-- zsh (.zshrc, *.zsh) con el resaltado de bash
vim.treesitter.language.register("bash", "zsh")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "bash", "lua", "qmljs", "json", "toml", "markdown", "markdown_inline", "yaml", "html", "mermaid" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
        -- qmlls viene con qt6-declarative (no está en mason)
        qmlls = {
          mason = false,
          cmd = { "/usr/lib/qt6/bin/qmlls" },
          filetypes = { "qml", "qmljs" },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "shellcheck", "shfmt" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
      },
    },
  },
}

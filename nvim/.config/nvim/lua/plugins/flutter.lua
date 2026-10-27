-- Flutter/Dart con flutter-tools: arranca dartls y añade run, hot reload, dispositivos y log.
-- El SDK está instalado con mise (`mise use -g flutter`)
return {
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = "dart",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>Fr", "<cmd>FlutterRun<cr>", desc = "Ejecutar", ft = "dart" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Parar", ft = "dart" },
      { "<leader>Fl", "<cmd>FlutterReload<cr>", desc = "Hot reload", ft = "dart" },
      { "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Hot restart", ft = "dart" },
      { "<leader>Fd", "<cmd>FlutterDevices<cr>", desc = "Dispositivos", ft = "dart" },
      { "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "Emuladores", ft = "dart" },
      { "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Árbol de widgets", ft = "dart" },
      { "<leader>Fc", "<cmd>FlutterLogToggle<cr>", desc = "Log", ft = "dart" },
    },
    opts = {
      -- Ruta del SDK de mise (si falla, busca `flutter` en el PATH)
      flutter_lookup_cmd = "mise where flutter",
      widget_guides = { enabled = true },
      closing_tags = { enabled = true },
      dev_log = { enabled = true, open_cmd = "botright 12split" },
      debugger = { enabled = false },
      lsp = {
        settings = {
          completeFunctionCalls = true,
          showTodos = true,
          renameFilesWithClasses = "prompt",
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "dart" } },
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { dart = { "dart_format" } } },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>F", group = "flutter", icon = "" } } },
  },
}

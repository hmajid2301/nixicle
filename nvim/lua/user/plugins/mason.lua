-- customize mason plugins
return {
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = {
      ensure_installed = { "svelte", "terraformls", "cssls", "lua_ls", "tailwindcss", "golangci_lint_ls", "gopls",
        "tsserver", "docker_compose_language_service", "dockerls", "marksman", "yamlls" },
    },
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources
  {
    "jay-babu/mason-null-ls.nvim",
    -- overrides `require("mason-null-ls").setup(...)`
    opts = {
      ensure_installed = { "prettier", "black", "goimports", "golangci-lint", "yamlint", "prettier_d", "flake8" },
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- overrides `require("mason-nvim-dap").setup(...)`
    opts = {
      ensure_installed = { "delve", "go-debug-adapter", "python" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "bash", "yaml", "python", "typescript", "dockerfile", "go" },
    },
  }
}

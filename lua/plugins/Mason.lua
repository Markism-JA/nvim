return {
  "mason-org/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  opts = {
    ensure_installed = {
      "lua_ls",
      "html",
      "cssls",
      "tsserver",
      "rust_analyzer",
      "roslyn",
      "rzls",
    },
  },
}

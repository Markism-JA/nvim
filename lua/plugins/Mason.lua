return {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
        ensure_installed = {
            "lua_ls",
            "html",
            "cssls",
            "tsserver",
            "rust_analyzer",
        },
    },
}

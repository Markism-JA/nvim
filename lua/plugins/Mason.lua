return {
    "mason-org/mason.nvim",
    log_level = vim.log.levels.DEBUG,
    opts = {
        ensure_installed = {
            -- lsp
            "lua-language-server",
            "html-lsp",
            "css-lsp",
            "rust-analyzer",
            "roslyn",
            "powershell-editor-services",
            "jdtls",
            "bash-language-server",
            "clangd",
            "ltex-ls",
            "marksman",
            "ruff",
            "vtsls",

            -- debugger
            "netcoredbg",
        },
    },
}

return {
    "mason-org/mason.nvim",
    opts = {
        log_level = vim.log.levels.INFO,
        registry_cache = {
            refresh = false,
        },
        ensure_installed = {
            -- lsp
            "lua-language-server",
            "html-lsp",
            "css-lsp",
            "rust-analyzer",
            "roslyn",
            "powershell-editor-services",
            "bash-language-server",
            "clangd",
            "ltex-ls",
            "marksman",
            "ruff",
            "vtsls",
            "lemminx",

            -- debugger
            "netcoredbg",

            -- formatter
            "prettierd",
        },
    },
}

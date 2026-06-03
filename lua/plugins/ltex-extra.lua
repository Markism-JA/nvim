-- This is for spell checks—basically Grammarly in latex and markdown.
return {
    "barreiroleo/ltex_extra.nvim",
    ft = { "markdown", "tex" },
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
        require("ltex_extra").setup({
            server_opts = {
                on_attach = function(client, bufnr)
                    vim.log.set_level(vim.log.levels.ERROR)
                end,
                settings = {
                    ltex = {
                        logLevel = "error",
                        diagnosticSeverity = "error",
                    },
                },
            },
        })
    end,
}

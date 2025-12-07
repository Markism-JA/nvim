return {
    "barreiroleo/ltex_extra.nvim",
    ft = { "markdown", "tex" },
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
        require("ltex_extra").setup({
            your_ltex_extra_opts,
            server_opts = {
                capabilities = your_capabilities,
                on_attach = function(client, bufnr) end,
                settings = {},
            },
        })
    end,
}

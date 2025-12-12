return {
    "barreiroleo/ltex_extra.nvim",
    ft = { "markdown", "tex" },
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
        require("ltex_extra").setup({
            server_opts = {
                on_attach = function(client, bufnr) end,
                settings = {},
            },
        })
    end,
}

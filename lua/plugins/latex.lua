return {
    {
        "lervag/vimtex",
        opts = function()
            vim.g.vimtex_view_method = "zathura"
            vim.g.vimtex_compiler_method = "latexmk"
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                tex = { "tex-fmt" },
            },
        },
    },
}

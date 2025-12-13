return {
    {
        "seblyng/roslyn.nvim",
        ft = { "cs", "razor" },
        dependencies = {
            {
                "tris203/rzls.nvim",
                config = true,
            },
            "mason-lspconfig.nvim",
        },
        opts = {},
        config = function()
            require("roslyn").setup({
                handlers = require("rzls.roslyn_handlers"),
            })
        end,
    },
}

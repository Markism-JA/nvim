return {
    {
        "ribru17/bamboo.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("bamboo").setup({
                style = "vulgaris",
            })
        end,
    },

    {
        "nyoom-engineering/oxocarbon.nvim",
    },

    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "bamboo",
        },
    },
}

return {
    {
        "NvChad/nvim-colorizer.lua",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("colorizer").setup({
                filetypes = { "*" },
                user_default_options = {
                    RGB = true,
                    RRGGBB = true,
                    names = true,
                    rgb_fn = true,
                    hsl_fn = true,
                    mode = "background", -- or "virtualtext"
                },
            })
        end,
    },
}

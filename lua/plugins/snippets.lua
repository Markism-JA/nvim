return {
    {
        "L3MON4D3/LuaSnip",
        opts = function()
            require("luasnip.loaders.from_vscode").lazy_load({
                paths = { vim.fn.stdpath("config") .. "/snippets" },
            })
        end,
    },
}

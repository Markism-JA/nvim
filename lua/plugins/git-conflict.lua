return {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = function()
        require("git-conflict").setup({
            default_mappings = true, -- disable if you want to define your own
            disable_diagnostics = false, -- pull diagnostics while in a conflict
            highlights = { -- customize colors
                incoming = "DiffAdd",
                current = "DiffText",
            },
        })
    end,
}

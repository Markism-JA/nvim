return {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
        { "<leader>U", "<cmd>UndotreeToggle<CR>", desc = "Toggle Undotree" },
    },
    config = function()
        -- Persistent undo
        vim.opt.undofile = true
        vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

        -- Always focus when opened
        vim.g.undotree_SetFocusWhenToggle = 1

        -- Floating layout
        vim.g.undotree_WindowLayout = 4 -- 4 = floating window
        vim.g.undotree_DiffpanelHeight = 15
        vim.g.undotree_FloatDiffpanel = 1
        vim.g.undotree_FloatDiffpanelPosition = "center"
    end,
}

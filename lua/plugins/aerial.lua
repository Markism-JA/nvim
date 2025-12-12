return {
    "stevearc/aerial.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter", -- for better syntax parsing
        "nvim-tree/nvim-web-devicons", -- optional, for icons
    },
    opts = {
        layout = {
            min_width = 28, -- sidebar width
            default_direction = "right", -- place on right side
        },
        show_guides = true, -- indent guides for nested symbols
        highlight_mode = "full_width", -- highlight entire line for current symbol
        autojump = true, -- jump to symbol when opened
        filter_kind = false, -- show all symbol types
        attach_mode = "window", -- track symbols for current window
        close_automatic_events = { "unsupported" }, -- auto-close if unsupported file
        manage_folds = true, -- folds linked to aerial symbols
        link_folds_to_tree = true,
        link_tree_to_folds = true,
    },
    config = function(_, opts)
        require("aerial").setup(opts)

        -- Keymap to toggle
        vim.keymap.set("n", "<leader>a", "<cmd>AerialToggle!<CR>", { desc = "Toggle Aerial" })

        -- Optional: automatically open aerial when entering certain filetypes
        -- vim.api.nvim_create_autocmd("FileType", {
        --   pattern = { "lua", "python", "cpp", "c", "java" },
        --   callback = function()
        --     require("aerial").open()
        --   end,
        -- })
    end,
}

return {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },

    init = function()
        vim.g.mkdp_auto_start = 0
        vim.g.mkdp_auto_close = 1
        vim.g.mkdp_refresh_slow = 0

        vim.g.mkdp_browser = "zen-browser"

        vim.g.mkdp_theme = "light"

        -- optional: inject CSS
        vim.g.mkdp_markdown_css = vim.fn.expand("~/.config/nvim/markdown.css")
        vim.g.mkdp_highlight_css = vim.fn.expand("~/.config/nvim/code.css")

        -- control scroll sync and rendering behavior
        vim.g.mkdp_preview_options = {
            disable_sync_scroll = 0,
            sync_scroll_type = "middle",
            hide_yaml_meta = 1,
            theme = "dark",
        }
    end,
}

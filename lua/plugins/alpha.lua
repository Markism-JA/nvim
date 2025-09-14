return {
    "goolord/alpha-nvim",
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")
        dashboard.section.header.val = {
            "Welcome to Mark's Neovim!",
            "🚀 Happy hacking!",
        }
        alpha.setup(dashboard.config)
    end,
}

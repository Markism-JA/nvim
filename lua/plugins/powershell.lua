local os = require("utils.os")

return {
    "TheLeoP/powershell.nvim",
    opts = function()
        local bundle_path

        if os.is_windows then
            bundle_path = "AppData/Local/nvim-data/mason/packages/powershell-editor-services/"
        elseif os.is_mac or os.is_linux then
            bundle_path = ".local/share/nvim/mason/packages/powershell-editor-services/"
        end

        return {
            bundle_path = bundle_path,
        }
    end,
}

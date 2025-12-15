return {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            powershell_es = {
                bundle_path = (function()
                    local mason_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services"
                    return mason_path
                end)(),
                settings = {
                    powershell = {
                        codeFormatting = { Preset = "OTBS" },
                    },
                },
            },
        },
    },
}

if vim.g.vscode then
    return {}, require("vsconfig.init")
else
    require("config.lazy")
    require("mason").setup({
        registries = {
            "github:mason-org/mason-registry",
            "github:Crashdummyy/mason-registry",
        },
    })
end

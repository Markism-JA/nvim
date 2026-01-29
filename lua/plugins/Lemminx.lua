return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                lemminx = {
                    ft = { "xml", "xsd", "xsl", "xslt", "svg" },
                    settings = {
                        xml = {
                            server = {
                                workDir = "~/.cache/lemminx",
                            },
                            fielAssociations = {
                                {
                                    pattern = "*.csproj",
                                    systemeId = "https://json.schemastore.org/msbuild",
                                },
                                {
                                    pattern = "*.props",
                                    systemeId = "https://json.schemastore.org/msbuild",
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}

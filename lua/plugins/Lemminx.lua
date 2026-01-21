return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                lemminx = {
                    ft = { "xml", "xsd", "xsl", "xslt", "svg" },
                },
            },
        },
    },
}

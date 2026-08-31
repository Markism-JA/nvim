return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                taplo = {
                    init_options = {
                        configFile = {
                            enabled = true,
                        },
                    },
                    settings = {
                        evenBetterToml = {
                            schema = {
                                enabled = true,
                                links = true,
                            },
                        },
                    },
                },
            },
        },
    },
}

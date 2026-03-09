return {
    { "Issafalcon/neotest-dotnet" },

    {
        "nvim-neotest/neotest",
        opts = {
            adapters = {
                ["neotest-dotnet"] = {
                    dap = {
                        args = { vim.fn.stdpath("data") .. "/mason/bin/netcoredbg" },
                    },
                },
            },
        },
    },
}

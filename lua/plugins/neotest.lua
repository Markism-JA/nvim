return {
    {
        "nvim-neotest/neotest",
        dependencies = { "issafalcon/neotest-dotnet" },
        opts = function(_, opts)
            opts.adapters = opts.adapters or {}
            table.insert(
                opts.adapters,
                require("neotest-dotnet")({
                    dap = { adapter_name = "coreclr" },
                    discovery_root = "project",
                })
            )
        end,
    },
}

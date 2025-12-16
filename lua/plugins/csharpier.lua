return {
    "stevearc/conform.nvim",
    opts = function(_, opts)
        local util = require("conform.util")

        opts.formatters = opts.formatters or {}
        opts.formatters.csharpier = {
            command = function(self, bufnr)
                local has_local_tool = util.root_file({ ".config/dotnet-tools.json" })(self, bufnr)

                if has_local_tool then
                    return "dotnet"
                else
                    return "csharpier"
                end
            end,

            args = function(self, bufnr)
                local has_local_tool = util.root_file({ ".config/dotnet-tools.json" })(self, bufnr)

                if has_local_tool then
                    vim.notify("Using LOCAL dotnet csharpier", vim.log.levels.INFO)
                    return { "csharpier", "format", "--stdin-path", "$FILENAME" }
                else
                    vim.notify("Using GLOBAL Mason csharpier", vim.log.levels.INFO)
                    return { "format" }
                end
            end,

            cwd = util.root_file({ ".config/dotnet-tools.json" }),
        }

        opts.formatters_by_ft = opts.formatters_by_ft or {}
        opts.formatters_by_ft.cs = { "csharpier" }
    end,
}

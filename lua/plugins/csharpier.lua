return {
    "stevearc/conform.nvim",
    opts = function(_, opts)
        local util = require("conform.util")

        -- 1. Receive the context table (ctx) instead of a raw buffer number
        local function check_local_tool(self, ctx)
            local bufnr = ctx.buf -- Extract the actual buffer ID

            -- Check if we've already cached the result for this specific buffer
            if vim.b[bufnr].has_local_csharpier == nil then
                -- Pass self and ctx down to the conform utility
                local root = util.root_file({ ".config/dotnet-tools.json" })(self, ctx)
                vim.b[bufnr].has_local_csharpier = (root ~= nil)

                -- Log the notification only once per buffer
                if vim.b[bufnr].has_local_csharpier then
                    vim.notify("Using LOCAL dotnet csharpier", vim.log.levels.INFO)
                else
                    vim.notify("Using GLOBAL Mason csharpier", vim.log.levels.INFO)
                end
            end

            return vim.b[bufnr].has_local_csharpier
        end

        opts.formatters = opts.formatters or {}
        opts.formatters.csharpier = {
            -- 2. Update the signatures to expect (self, ctx)
            command = function(self, ctx)
                if check_local_tool(self, ctx) then
                    return "dotnet"
                end
                return "csharpier"
            end,

            args = function(self, ctx)
                if check_local_tool(self, ctx) then
                    return { "csharpier", "format", "--stdin-path", "$FILENAME" }
                end
                return { "format" }
            end,

            cwd = util.root_file({ ".config/dotnet-tools.json", ".sln", ".csproj" }),
        }

        opts.formatters_by_ft = opts.formatters_by_ft or {}
        opts.formatters_by_ft.cs = { "csharpier" }
    end,
}

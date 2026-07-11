return {
    "stevearc/conform.nvim",
    opts = function(_, opts)
        local util = require("conform.util")

        local function check_local_tool(ctx)
            local bufnr = ctx.buf

            if not ctx.filename or ctx.filename == "" then
                return false
            end

            if vim.b[bufnr].has_local_csharpier == nil then
                local root = util.root_file({ ".config/dotnet-tools.json" })(ctx.filename)
                vim.b[bufnr].has_local_csharpier = (root ~= nil)

                if vim.b[bufnr].has_local_csharpier then
                    vim.notify("Using LOCAL dotnet csharpier", vim.log.levels.INFO, { title = "Conform" })
                else
                    vim.notify("Using GLOBAL Mason csharpier", vim.log.levels.INFO, { title = "Conform" })
                end
            end

            return vim.b[bufnr].has_local_csharpier
        end

        opts.formatters = opts.formatters or {}
        opts.formatters.csharpier = {
            command = function(ctx)
                if check_local_tool(ctx) then
                    return "dotnet"
                end
                return "csharpier"
            end,

            args = function(ctx)
                if check_local_tool(ctx) then
                    return { "csharpier", "format", "--stdin-path", "$FILENAME" }
                end
                return { "format" }
            end,

            cwd = util.root_file({ ".config/dotnet-tools.json", ".sln", ".slnx", ".csproj" }),
        }

        opts.formatters_by_ft = opts.formatters_by_ft or {}
        opts.formatters_by_ft.cs = { "csharpier" }
    end,
}

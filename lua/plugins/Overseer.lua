return {
    "stevearc/overseer.nvim",
    opts = {
        templates = { "builtin" },
    },
    config = function(_, opts)
        local overseer = require("overseer")

        overseer.setup(opts)

        overseer.register_template({
            name = "Dotnet Build",

            builder = function(params)
                return {
                    cmd = { "dotnet" },
                    args = { "build", "-c", "Debug" },

                    name = "Dotnet Build",

                    components = {
                        { "on_output_quickfix", open = false },
                        "default",
                    },
                }
            end,

            condition = {
                callback = function(search)
                    return vim.fn.glob("*.csproj") ~= "" or vim.fn.glob("*.sln") ~= ""
                end,
            },
        })
    end,
}

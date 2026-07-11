return {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "mfussenegger/nvim-dap",
        "ibhagwan/fzf-lua",
    },
    ft = { "cs", "csproj", "sln", "slnx" },
    opts = {
        lsp = { enabled = false },

        picker = "fzf",

        dap = {
            adapter = {
                type = "executable",
                command = "netcoredbg",
                args = { "--interpreter=vscode" },
            },
        },
        mappings = {
            run_interface = "<leader>dr",
            test_runner = "<leader>dt",
        },
    },
    config = function(_, opts)
        local easy_dotnet = require("easy-dotnet")
        easy_dotnet.setup(opts)

        -- Resolves LazyVim / nvim-dap race conditions
        vim.api.nvim_create_autocmd("User", {
            pattern = "LazyLoad",
            callback = function(event)
                if event.data == "nvim-dap" then
                    easy_dotnet.setup(opts)
                end
            end,
        })

        -- Corrected command maps leveraging the native subcommands safely
        vim.api.nvim_create_user_command("DotnetUI", "Dotnet run", {})
        vim.api.nvim_create_user_command("DotnetTest", "Dotnet test", {})
        vim.api.nvim_create_user_command("DotnetSecrets", "Dotnet secrets", {})
    end,
}

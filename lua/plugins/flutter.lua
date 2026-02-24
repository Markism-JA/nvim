return {
    {
        "akinsho/flutter-tools.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "stevearc/dressing.nvim",
            "mfussenegger/nvim-dap",
        },
        config = function()
            local dap = require("dap")

            require("flutter-tools").setup({
                ui = { border = "rounded" },
                decorations = {
                    statusline = { app_version = true, device = true },
                },
                widget_guides = { enabled = true },
                closing_tags = {
                    highlight = "WarningMsg",
                    prefix = " // ",
                    enabled = true,
                },
                lsp = {
                    color = {
                        enabled = true,
                        virtual_text = true,
                        virtual_text_str = "■",
                    },
                },
                debugger = {
                    enabled = true,
                    run_via_dap = true,
                },
            })

            dap.adapters.dart_cli = function(callback, config)
                config.console = "externalTerminal"
                callback({ type = "executable", command = "dart", args = { "debug_adapter" } })
            end

            dap.adapters.flutter_picker = function(callback, config)
                local items = { "chrome", "linux", "macos", "windows", "all" }
                vim.ui.select(items, { prompt = "Select Device:" }, function(choice)
                    if choice then
                        config.toolArgs = { "-d", choice }
                        config.name = "Flutter (" .. choice .. ")"
                        callback({ type = "executable", command = "flutter", args = { "debug_adapter" } })
                    end
                end)
            end

            dap.configurations.dart = {
                {
                    type = "flutter_picker",
                    request = "launch",
                    name = "Flutter App",
                    program = "${workspaceFolder}/lib/main.dart",
                    cwd = "${workspaceFolder}",
                },
            }

            require("dap.ext.vscode").type_to_filetypes["dart"] = { "dart" }
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
        opts = function(_, opts)
            opts.textobjects = opts.textobjects or {}

            opts.textobjects.swap = {
                enable = true,
                swap_next = { ["<leader>a"] = "@parameter.inner" },
                swap_previous = { ["<leader>A"] = "@parameter.inner" },
            }
        end,
    },
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.dart = { "dart_format" }
        end,
    },
}

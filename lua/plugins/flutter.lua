return {
    {
        "akinsho/flutter-tools.nvim",
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "mfussenegger/nvim-dap",
        },
        config = function()
            require("flutter-tools").setup({
                debugger = {
                    enabled = true,
                    run_via_dap = true,
                },
            })

            local dap = require("dap")

            -- ======================================================================
            -- 1. ADAPTERS (The Engines)
            -- ======================================================================

            -- A. Pure Dart Adapter (Standard)
            dap.adapters.dart_cli = {
                type = "executable",
                command = "dart",
                args = { "debug_adapter" },
            }

            -- B. The "Interactive" Flutter Adapter (The Fix)
            -- Instead of a static definition, this is a FUNCTION.
            -- nvim-dap calls this when the "flutter_picker" config type is selected.
            dap.adapters.flutter_picker = function(callback, config)
                local items = { "chrome", "linux", "macos", "windows", "all" }

                vim.ui.select(items, { prompt = "Select Target Device:" }, function(choice)
                    -- 1. Handle Cancel (User pressed Esc)
                    if choice == nil then
                        return
                    end

                    -- 2. Inject the selection into the config
                    config.toolArgs = { "-d", choice }

                    -- Update the tab name to what is running
                    config.name = "Flutter (" .. choice .. ")"

                    -- 3. Hand off to the REAL Flutter Adapter
                    callback({
                        type = "executable",
                        command = "flutter",
                        args = { "debug_adapter" },
                    })
                end)
            end

            -- ======================================================================
            -- 2. CONFIGURATIONS (The Menu)
            -- ======================================================================
            dap.configurations.dart = {

                -- CONFIG 1: Flutter (Interactive)
                {
                    type = "flutter_picker",
                    request = "launch",
                    name = "Flutter: Select Device",
                    program = "${workspaceFolder}/lib/main.dart",
                    cwd = "${workspaceFolder}",
                },

                -- CONFIG 2: Pure Dart (Current File)
                {
                    type = "dart_cli",
                    request = "launch",
                    name = "Dart: Run Current File",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                },

                -- CONFIG 3: Pure Dart (Main)
                {
                    type = "dart_cli",
                    request = "launch",
                    name = "Dart: Run bin/main.dart",
                    program = "${workspaceFolder}/bin/main.dart",
                    cwd = "${workspaceFolder}",
                },
            }

            pcall(require("dap.ext.vscode").load_launchjs, nil, { dart = { "flutter_picker", "dart_cli" } })
        end,
    },
}

return {
    {
        "akinsho/flutter-tools.nvim",
        lazy = false,
        config = function()
            local dap = require("dap")

            -- 1. SETUP FLUTTER TOOLS
            require("flutter-tools").setup({
                debugger = {
                    enabled = true,
                    run_via_dap = true,
                },
            })

            -- 2. DART ADAPTER (CLI)
            dap.adapters.dart_cli = function(callback, config)
                config.console = "externalTerminal"
                callback({
                    type = "executable",
                    command = "dart",
                    args = { "debug_adapter" },
                })
            end

            -- 3. FLUTTER ADAPTER (Device Picker)
            dap.adapters.flutter_picker = function(callback, config)
                local items = { "chrome", "linux", "macos", "windows", "all" }
                vim.ui.select(items, { prompt = "Select Device:" }, function(choice)
                    if choice then
                        config.toolArgs = { "-d", choice }
                        config.name = "Flutter (" .. choice .. ")"
                        callback({
                            type = "executable",
                            command = "flutter",
                            args = { "debug_adapter" },
                        })
                    end
                end)
            end

            -- 4. CONFIGURATIONS
            dap.configurations.dart = {
                {
                    type = "flutter_picker",
                    request = "launch",
                    name = "Flutter App",
                    program = "${workspaceFolder}/lib/main.dart",
                    cwd = "${workspaceFolder}",
                },
                {
                    type = "dart_cli",
                    request = "launch",
                    name = "Dart: Run Current File",
                    program = "${file}",
                    cwd = "${workspaceFolder}",
                },
                {
                    type = "dart_cli",
                    request = "launch",
                    name = "Dart: Run bin/main.dart",
                    program = "${workspaceFolder}/bin/main.dart",
                    cwd = "${workspaceFolder}",
                },
            }

            -- Load VSCode launch.json if present
            pcall(require("dap.ext.vscode").load_launchjs, nil, { dart = { "flutter_picker", "dart_cli" } })
        end,
    },
}

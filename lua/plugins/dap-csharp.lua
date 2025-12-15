-- NOTE:Not sure if this work, still not sure how DAP, DAP UI and the debugger works in NVIM.

return {
    "mfussenegger/nvim-dap",
    confi = function()
        local dap = require("dap")
        if not dap.adapters["coreclr"] then
            dap.adapters["coreclr"] = {
                type = "executable",
                command = vim.fn.exepath("netcoredbg"),
                args = { "--interpreter=vscode" },
            }
        end

        if not dap.configurations.cs then
            dap.configurations.cs = {
                {
                    type = "coreclr",
                    name = "launch - netcoredbg",
                    request = "launch",

                    program = function()
                        local cwd = vim.fn.getcwd()

                        local dll_path = vim.fn.glob(cwd .. "bin/Debug/**/*.dll", false, true)[1]

                        if dll_path and dll_path ~= "" then
                            return vim.fn.input("Path to dll: ", dll_path, "file")
                        else
                            return vim.fn.input("Path to dll: ", cwd .. "/bin/Debug", "file")
                        end
                    end,
                },
            }
        end
    end,
}

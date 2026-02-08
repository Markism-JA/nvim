return {
    {
        "mfussenegger/nvim-dap",
        optional = true,
        opts = function()
            local dap = require("dap")
            local overseer = require("overseer")
            local dap_vscode = require("dap.ext.vscode")

            local function get_dll_path()
                local cwd = vim.fn.getcwd()
                local csproj_path = vim.fn.glob(cwd .. "/*.csproj")

                if csproj_path == "" then
                    return vim.fn.input("No .csproj found. Path to dll: ", cwd .. "/bin/Debug/", "file")
                end

                local project_name = vim.fn.fnamemodify(csproj_path, ":t:r")
                local assembly_name = project_name
                local framework = "net8.0"

                local file = io.open(csproj_path, "r")
                if file then
                    local content = file:read("*a")
                    file:close()

                    local name_match = string.match(content, "<AssemblyName>(.-)</AssemblyName>")
                    if name_match then
                        assembly_name = name_match
                    end

                    local fw_match = string.match(content, "<TargetFramework>(.-)</TargetFramework>")
                    if fw_match then
                        framework = fw_match
                    end
                end

                local dll_path = string.format("%s/bin/Debug/%s/%s.dll", cwd, framework, assembly_name)

                if vim.fn.filereadable(dll_path) == 1 then
                    return dll_path
                else
                    return vim.fn.input("DLL not found. Path to dll: ", cwd .. "/bin/Debug/", "file")
                end
            end

            if not dap.adapters.coreclr then
                dap.adapters.coreclr = {
                    type = "executable",
                    command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
                    args = { "--interpreter=vscode" },
                }
            end

            dap.configurations.cs = {
                {
                    type = "coreclr",
                    name = "Build & Debug (Overseer)",
                    request = "launch",
                    runInTerminal = true,
                    console = "integratedTerminal",
                    program = function()
                        return coroutine.create(function(dap_run_co)
                            overseer.run_template({ name = "Dotnet Build" }, function(task)
                                if not task then
                                    vim.notify(
                                        "Could not find 'Dotnet Build' task. Check overseer.lua",
                                        vim.log.levels.ERROR
                                    )
                                    coroutine.resume(dap_run_co, nil)
                                    return
                                end

                                task:subscribe("on_complete", function()
                                    if task.status == "SUCCESS" then
                                        local dll = get_dll_path()
                                        coroutine.resume(dap_run_co, dll)
                                    else
                                        vim.notify("Build Failed", vim.log.levels.ERROR)
                                        overseer.open({ enter = false })
                                        coroutine.resume(dap_run_co, nil)
                                    end
                                end)

                                task:start()
                            end)
                        end)
                    end,
                },
                {
                    type = "coreclr",
                    name = "Debug (No Build)",
                    request = "launch",
                    runInTerminal = true,
                    console = "integratedTerminal",
                    program = function()
                        return get_dll_path()
                    end,
                },
            }

            dap_vscode.type_to_filetypes["coreclr"] = { "cs" }
            dap_vscode.load_launchjs()
        end,
    },
}

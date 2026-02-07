return {
    {
        "mfussenegger/nvim-dap",
        optional = true,
        opts = function()
            local dap = require("dap")

            local function build_project()
                vim.notify("Building project...", vim.log.levels.INFO)

                local cmd = { "dotnet", "build", "-c", "Debug" }

                local result = vim.system(cmd, { text = true }):wait()

                if result.code ~= 0 then
                    vim.notify(
                        "Build Failed!\n" .. (result.stdout or "") .. (result.stderr or ""),
                        vim.log.levels.ERROR
                    )
                    return false
                else
                    vim.notify("Build Success!", vim.log.levels.INFO)
                    return true
                end
            end

            local function get_dll_path(ensure_built)
                local cwd = vim.fn.getcwd()

                if ensure_built then
                    if not build_project() then
                        return nil
                    end
                end

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

                -- Construct path: bin/Debug/{framework}/{assembly_name}.dll
                local dll_path = string.format("%s/bin/Debug/%s/%s.dll", cwd, framework, assembly_name)

                if vim.fn.filereadable(dll_path) == 1 then
                    return dll_path
                else
                    vim.notify("DLL not found at: " .. dll_path, vim.log.levels.WARN)
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

            -- DEFAULT CONFIGURATIONS
            dap.configurations.cs = {
                -- OPTION 1: Build First (Safest)
                {
                    type = "coreclr",
                    name = "Build & Debug",
                    request = "launch",
                    runInTerminal = true,
                    console = "integratedTerminal",
                    -- NOTE: Not supported by netcoredbg
                    program = function()
                        return get_dll_path(true)
                    end,
                },
                -- OPTION 2: Just Debug (Fastest)
                {
                    type = "coreclr",
                    name = "Debug (No Build)",
                    request = "launch",
                    runInTerminal = true,
                    console = "integratedTerminal",
                    -- NOTE: Not supported by netcoredbg
                    program = function()
                        return get_dll_path(false)
                    end,
                },
            }

            local dap_vscode = require("dap.ext.vscode")

            dap_vscode.type_to_filetypes["coreclr"] = { "cs" }

            dap_vscode.load_launchjs()
        end,
    },
}

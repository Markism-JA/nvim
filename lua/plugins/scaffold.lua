return {
    {
        "user.scaffold",
        dir = vim.fn.stdpath("config"),
        lazy = false,
        dependencies = { "stevearc/dressing.nvim" },
        config = function()
            -- =================================================================
            -- 1. UTILITIES
            -- =================================================================
            local function load_templates()
                local templates = {}
                local template_dir = vim.fn.stdpath("config") .. "/templates"

                -- Silently create directory if missing (avoids errors)
                if vim.fn.isdirectory(template_dir) == 0 then
                    vim.fn.mkdir(template_dir, "p")
                end

                local files = vim.fs.find(function(name)
                    return name:match("%.lua$")
                end, { path = template_dir, type = "file", limit = 20 })

                for _, file_path in ipairs(files) do
                    local status, definition = pcall(dofile, file_path)
                    if status and definition and definition.name then
                        templates[definition.name] = definition
                    end
                end
                return templates
            end

            -- =================================================================
            -- 2. THE LOGIC
            -- =================================================================
            local function create_new_file()
                local base_dir = vim.loop.cwd()
                local status, MiniFiles = pcall(require, "mini.files")

                -- A. Robust Context Detection
                if status and vim.bo.filetype == "minifiles" then
                    -- Try to get the specific file under cursor
                    local entry = MiniFiles.get_fs_entry()
                    if entry then
                        base_dir = entry.fs_type == "directory" and entry.path or vim.fs.dirname(entry.path)
                    else
                        -- FALLBACK: If cursor is invalid (e.g. empty dir), get the current path of the explorer
                        -- 'MiniFiles.get_explorer_state().branch' contains the path history
                        local state = MiniFiles.get_explorer_state()
                        if state and state.branch and state.branch[state.target_window] then
                            base_dir = state.branch[state.target_window]
                        end
                    end
                    MiniFiles.close()
                elseif vim.fn.expand("%:p") ~= "" then
                    base_dir = vim.fs.dirname(vim.fn.expand("%:p"))
                end

                -- B. Load Templates
                local templates = load_templates()
                local template_keys = vim.tbl_keys(templates)

                if #template_keys == 0 then
                    return vim.notify(
                        "No templates found in " .. vim.fn.stdpath("config") .. "/templates",
                        vim.log.levels.WARN
                    )
                end
                table.sort(template_keys)

                -- C. The Interaction Loop
                vim.ui.select(
                    template_keys,
                    { prompt = "Create File (" .. vim.fn.fnamemodify(base_dir, ":t") .. "):" },
                    function(selected)
                        if not selected then
                            return
                        end
                        local template = templates[selected]

                        vim.ui.input({ prompt = "Filename (path/to/Name): " }, function(input)
                            if not input or input == "" then
                                return
                            end

                            -- D. Advanced Path Parsing
                            -- 1. Remove Extension (if user typed it)
                            local clean_input = input:gsub("%." .. template.ext .. "$", "")

                            -- 2. Split Path and Filename
                            -- Input: "Systems/Combat/DamageCalc"
                            -- Dir: "Systems/Combat"
                            -- Name: "DamageCalc"
                            local relative_dir = vim.fs.dirname(clean_input)
                            local filename = vim.fs.basename(clean_input)

                            -- Handle case where there is no directory in input (dirname returns ".")
                            local target_dir = base_dir
                            if relative_dir ~= "." then
                                target_dir = base_dir .. "/" .. relative_dir
                            end

                            -- 3. Ensure Target Directory Exists (mkdir -p)
                            if vim.fn.isdirectory(target_dir) == 0 then
                                vim.fn.mkdir(target_dir, "p")
                            end

                            local full_path = target_dir .. "/" .. filename .. "." .. template.ext

                            -- E. Content Generation
                            -- Pass the CLEAN filename ("DamageCalc") and the ACTUAL folder path
                            local lines = template.content(filename, target_dir)

                            -- F. Write to Disk
                            local file = io.open(full_path, "w")
                            if file then
                                for _, line in ipairs(lines) do
                                    file:write(line:gsub("%$CURSOR", "") .. "\n")
                                end
                                file:close()

                                -- G. Open and Position
                                vim.cmd("edit " .. full_path)
                                for i, line in ipairs(lines) do
                                    if line:find("%$CURSOR") then
                                        vim.api.nvim_win_set_cursor(0, { i, 0 })
                                        vim.cmd("startinsert")
                                        break
                                    end
                                end
                            else
                                vim.notify("Failed to write file: " .. full_path, vim.log.levels.ERROR)
                            end
                        end)
                    end
                )
            end

            -- =================================================================
            -- 3. COMMANDS & MAPPINGS
            -- =================================================================
            vim.api.nvim_create_user_command("Scaffold", create_new_file, {})

            -- Attach to mini.files
            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesBufferCreate",
                callback = function(args)
                    local buf_id = args.data.buf_id
                    vim.keymap.set("n", "gC", create_new_file, {
                        buffer = buf_id,
                        desc = "Scaffold from Template",
                    })
                end,
            })
        end,
    },
}

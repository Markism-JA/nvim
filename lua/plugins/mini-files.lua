return {
    {
        "nvim-mini/mini.files",
        opts = {
            windows = {
                preview = true,
                width_preview = 40,
            },
        },
        init = function()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1

            vim.api.nvim_create_autocmd("BufEnter", {
                group = vim.api.nvim_create_augroup("MiniFilesHijack", { clear = true }),
                pattern = "*",
                callback = function()
                    local path = vim.fn.expand("%:p")
                    if vim.fn.isdirectory(path) == 1 then
                        vim.cmd("bwipeout")
                        require("mini.files").open(path)
                    end
                end,
            })
        end,
        config = function(_, opts)
            require("mini.files").setup(opts)

            -- --- 1. EXTERNAL PREVIEW LOGIC ---
            local preview_active = false
            local current_job_id = nil
            local debounce_timer = vim.loop.new_timer()

            local function close_preview()
                if current_job_id then
                    vim.fn.jobstop(current_job_id)
                    current_job_id = nil
                end
            end

            local function sync_external_preview()
                if not preview_active then
                    return
                end
                local MiniFiles = require("mini.files")
                local status, entry = pcall(MiniFiles.get_fs_entry)
                if not status or not entry then
                    return
                end

                local ext = vim.fn.fnamemodify(entry.path, ":e"):lower()
                local is_image = vim.tbl_contains({ "png", "jpg", "jpeg", "webp", "gif", "svg" }, ext)

                if current_job_id then
                    vim.fn.jobstop(current_job_id)
                    current_job_id = nil
                end

                if entry.fs_type == "file" and is_image then
                    debounce_timer:stop()
                    debounce_timer:start(
                        50,
                        0,
                        vim.schedule_wrap(function()
                            if not preview_active then
                                return
                            end
                            current_job_id = vim.fn.jobstart({ "imv", entry.path }, {
                                detach = true,
                                env = { ["WAYLAND_DISPLAY"] = vim.env.WAYLAND_DISPLAY },
                            })
                        end)
                    )
                end
            end

            local grp = vim.api.nvim_create_augroup("MiniFilesUserEvents", { clear = true })
            vim.api.nvim_create_autocmd(
                "User",
                { pattern = "MiniFilesWindowUpdate", group = grp, callback = sync_external_preview }
            )
            vim.api.nvim_create_autocmd(
                "User",
                { pattern = "MiniFilesExplorerClose", group = grp, callback = close_preview }
            )

            -- --- 2. KEYMAPPINGS ---
            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesBufferCreate",
                group = grp,
                callback = function(args)
                    local buf_id = args.data.buf_id
                    local MiniFiles = require("mini.files")

                    -- [g/] GREP (Robust: Closes explorer first)
                    vim.keymap.set("n", "g/", function()
                        local entry = MiniFiles.get_fs_entry()
                        local dir = (entry and entry.fs_type == "directory") and entry.path
                            or vim.fs.dirname(entry.path)

                        -- 1. Close explorer to prevent focus conflict
                        MiniFiles.close()

                        -- 2. Schedule the grep to run in the next event loop
                        vim.schedule(function()
                            -- Support for LazyVim's Snacks or Telescope
                            if package.loaded["snacks"] then
                                Snacks.picker.grep({ cwd = dir })
                            else
                                LazyVim.pick("live_grep", { cwd = dir })()
                            end
                        end)
                    end, { buffer = buf_id, desc = "Grep in Directory" })

                    -- [gm] MOVE (Native Input with Path Completion)
                    vim.keymap.set("n", "gm", function()
                        local entry = MiniFiles.get_fs_entry()
                        if not entry then
                            return
                        end

                        local old_path = entry.path
                        local current_dir = vim.fs.dirname(old_path)

                        -- 1. Close explorer to focus on the Input Box
                        MiniFiles.close()

                        -- 2. Use vim.ui.input with 'completion = "dir"'
                        -- This allows you to type '~/', '../', or absolute paths with Tab completion
                        vim.schedule(function()
                            vim.ui.input({
                                prompt = "Move " .. entry.name .. " to: ",
                                default = current_dir .. "/", -- Pre-fill with current location
                                completion = "dir", -- ENABLE NATIVE PATH COMPLETION
                            }, function(destination)
                                if not destination or destination == "" then
                                    -- Cancelled? Re-open explorer
                                    MiniFiles.open(current_dir)
                                    return
                                end

                                -- Clean up destination path
                                local dest_path = vim.fn.fnamemodify(destination, ":p") -- Expand ~ and .

                                -- If destination is a folder, append the filename
                                if vim.fn.isdirectory(dest_path) == 1 then
                                    dest_path = dest_path .. entry.name
                                end

                                -- Execute Move
                                local ret = vim.fn.system({ "mv", old_path, dest_path })
                                if vim.v.shell_error ~= 0 then
                                    vim.notify("Move failed: " .. ret, vim.log.levels.ERROR)
                                    MiniFiles.open(current_dir)
                                else
                                    vim.notify("Moved to " .. dest_path)
                                    -- Re-open explorer at the OLD location (file will be gone)
                                    MiniFiles.open(current_dir)
                                end
                            end)
                        end)
                    end, { buffer = buf_id, desc = "Move File (Type Path)" })

                    -- [g.] REVEAL (Detached)
                    vim.keymap.set("n", "g.", function()
                        local entry = MiniFiles.get_fs_entry()
                        if not entry then
                            return
                        end
                        local dir = entry.fs_type == "directory" and entry.path or vim.fs.dirname(entry.path)
                        vim.fn.jobstart({ "xdg-open", dir }, { detach = true })
                    end, { buffer = buf_id, desc = "Show in File Manager" })

                    -- [gP] PREVIEW
                    vim.keymap.set("n", "gP", function()
                        preview_active = not preview_active
                        if preview_active then
                            vim.notify("External Preview: ON")
                            sync_external_preview()
                        else
                            vim.notify("External Preview: OFF")
                            close_preview()
                        end
                    end, { buffer = buf_id, desc = "Toggle Image Preview" })

                    -- [~] HOME
                    vim.keymap.set("n", "~", function()
                        MiniFiles.close()
                        MiniFiles.open(vim.loop.os_homedir())
                    end, { buffer = buf_id, desc = "Go Home" })

                    -- [gx] SYSTEM OPEN
                    vim.keymap.set("n", "gx", function()
                        local entry = MiniFiles.get_fs_entry()
                        if entry and entry.path then
                            vim.ui.open(entry.path)
                        end
                    end, { buffer = buf_id, desc = "System Open" })
                end,
            })
        end,
    },
    { "nvim-neo-tree/neo-tree.nvim", enabled = false },
}

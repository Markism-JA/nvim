return {
    {
        "echasnovski/mini.files",
        opts = {},
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

            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesBufferCreate",
                callback = function(args)
                    local buf_id = args.data.buf_id

                    local function open_external()
                        local entry = require("mini.files").get_fs_entry()
                        if entry and entry.path then
                            local _, err = vim.ui.open(entry.path)
                            if err then
                                vim.notify("Error opening file: " .. tostring(err), vim.log.levels.ERROR)
                            end
                        end
                    end

                    vim.keymap.set("n", "gx", open_external, {
                        buffer = buf_id,
                        desc = "Open file in system viewer (OS default)",
                    })
                end,
            })
        end,
    },

    { "nvim-neo-tree/neo-tree.nvim", enabled = false },
}

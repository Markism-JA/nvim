vim.filetype.add({
    extension = {
        luau = "luau",
    },
})

return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, { "luau", "lua" })
            end
        end,
    },

    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "luau-lsp", "stylua" })
        end,
    },

    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                luau = { "stylua" },
            },
        },
    },

    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                luau_lsp = {
                    enabled = false,
                },
            },
        },
    },

    -- luau-lsp.nvim setup
    {
        "lopi-py/luau-lsp.nvim",
        ft = { "luau" },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        opts = function()
            local current_file = vim.api.nvim_buf_get_name(0)
            local start_dir = (current_file ~= "" and vim.fs.dirname(current_file)) or vim.uv.cwd() or "."

            local root_marker =
                vim.fs.find({ ".luaurc", ".taplo.toml", "types", ".git" }, { upward = true, path = start_dir })[1]
            local root_dir = root_marker and vim.fs.dirname(root_marker) or start_dir

            local def_map = {}

            -- Check standalone root definition file
            local root_def = vim.fs.joinpath(root_dir, "definitions.d.luau")
            if vim.uv.fs_stat(root_def) then
                def_map["@"] = vim.fs.normalize(vim.fs.abspath(root_def))
            end

            -- Check all definitions in a types/ directory and map each with its basename
            local types_dir = vim.fs.joinpath(root_dir, "types")
            if vim.uv.fs_stat(types_dir) then
                for name, type in vim.fs.dir(types_dir) do
                    if type == "file" and name:match("%.d%.luau$") then
                        local abs_path = vim.fs.normalize(vim.fs.abspath(vim.fs.joinpath(types_dir, name)))
                        -- Strip extension (e.g., "ui.d.luau" -> "ui") or use the full name as the key
                        local key = name:gsub("%.d%.luau$", "")
                        def_map[key] = abs_path
                    end
                end
            end

            return {
                platform = {
                    type = "standard",
                },
                sourcemap = {
                    enabled = false,
                },
                fflags = {
                    enable_new_solver = true,
                },
                types = {
                    definition_files = def_map,
                },
            }
        end,
    },
}

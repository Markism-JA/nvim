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
        "mason-org/mason-lspconfig.nvim",
        opts = {
            automatic_enable = {
                exclude = { "luau_lsp" },
            },
        },
    },

    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                luau = { "stylua" },
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
            local start_dir = vim.uv.cwd() or "."
            local root_marker =
                vim.fs.find({ ".luaurc", ".taplo.toml", ".git" }, { upward = true, path = start_dir })[1]
            local root_dir = root_marker and vim.fs.dirname(root_marker) or start_dir

            local types_dir = vim.fs.joinpath(root_dir, "types")
            local bundle_file = vim.fs.joinpath(root_dir, "types", ".all.d.luau")

            -- Automatically scan types/ and merge all .d.luau files into a single root definition bundle
            if vim.uv.fs_stat(types_dir) then
                local merged_content = { "--!strict\n" }
                for name, type in vim.fs.dir(types_dir) do
                    if type == "file" and name:match("%.d%.luau$") and name ~= ".all.d.luau" then
                        local p = vim.fs.joinpath(types_dir, name)
                        local f = io.open(p, "r")
                        if f then
                            local content = f:read("*a")
                            f:close()
                            -- Strip mode comments like --!nocheck or --!strict from subfiles
                            content = content:gsub("^%-%-![^\n]*\n", "")
                            table.insert(merged_content, content)
                        end
                    end
                end
                local out = io.open(bundle_file, "w")
                if out then
                    out:write(table.concat(merged_content, "\n\n"))
                    out:close()
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
                    definition_files = {
                        ["@"] = bundle_file,
                    },
                },
            }
        end,
    },
}

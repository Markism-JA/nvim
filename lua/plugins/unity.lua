return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        opts = {
            filesystem = {
                filtered_items = {
                    visible = false,
                    hide_dotfiles = false,
                    hide_gitignored = true,
                    hide_by_name = {
                        "bin",
                        "obj",
                    },
                    hide_by_pattern = {
                        "*.meta",
                    },
                },
            },
        },
    },
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                sources = {
                    files = {
                        exclude = { "**/*.meta", "**/bin/*", "**/obj/*" },
                    },
                    explorer = {
                        exclude = { "**/*.meta", "**/bin/*", "**/obj/*" },
                    },
                },
            },
        },
    },
    {
        "nvim-mini/mini.files",
        opts = {
            content = {
                filter = function(entry)
                    return not entry.name:match("%.meta$") and entry.name ~= "bin" and entry.name ~= "obj"
                end,
            },
        },
    },
}

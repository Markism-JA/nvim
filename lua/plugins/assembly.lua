return {
    {
        "neovim/nvim-lspconfig",
        ft = { "asm", "nasm", "s" },
        opts = {
            servers = {
                asm_lsp = {
                    filetypes = { "asm", "nasm", "s" },
                },
            },
            setup = {
                asm_lsp = function(_, opts)
                    require("lspconfig").asm_lsp.setup({
                        cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/asm-lsp") },
                        filetypes = { "asm", "nasm", "s" },
                        root_dir = require("lspconfig.util").root_pattern(".git", ".asm-lsp.toml"),

                        on_attach = function(client, bufnr)
                            local ft = vim.bo[bufnr].filetype
                            if ft ~= "asm" and ft ~= "nasm" and ft ~= "s" then
                                vim.lsp.buf_detach_client(bufnr, client.id)
                            end
                        end,

                        settings = {
                            ["asm-lsp"] = {
                                assembler = "nasm",
                                instruction_set = "x86_64",
                            },
                        },
                    })
                    return true
                end,
            },
        },
    },

    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "asm-lsp", "asmfmt" })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, { "asm" })
            end
        end,
    },
}

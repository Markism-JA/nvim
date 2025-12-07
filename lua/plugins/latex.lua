return {

    -- VimTeX for LaTeX editing and compilation
    {
        "lervag/vimtex",
        ft = { "tex", "bib" },
        config = function()
            vim.g.vimtex_view_method = "zathura"
            vim.g.vimtex_compiler_method = "latexmk"

            local map = vim.keymap.set
            local opts = { noremap = true, silent = true, buffer = true }

            map("n", "<leader>cc", ":VimtexCompile<CR>", opts)
            map("n", "<leader>cv", ":VimtexView<CR>", opts)
            map("n", "<leader>ck", ":VimtexStop<CR>", opts)
            map("n", "<leader>cx", ":VimtexClean<CR>", opts)
            map("n", "<leader>ci", ":VimtexInfo<CR>", opts)
            map("n", "<leader>ct", ":VimtexTocToggle<CR>", opts)
        end,
    },

    -- Treesitter for better syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "lua",
                "vim",
                "vimdoc",
                "c",
                "latex",
            },
            highlight = { enable = true },
        },
    },

    -- 🧠 LSP setup for LaTeX
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                texlab = {},
                ltex = {},
            },
        },
    },

    -- 🪄 Auto-pairs for parentheses, brackets, etc.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        opts = {},
    },
}

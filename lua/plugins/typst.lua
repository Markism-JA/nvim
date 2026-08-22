return {
    -- =========================================================================
    -- Mason
    -- =========================================================================
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, {
                "tinymist",
                "typstyle",
            })
        end,
    },

    -- =========================================================================
    -- Conform (Auto-formatting on save)
    -- =========================================================================
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                typst = { "typstyle" },
            },
        },
    },

    -- =========================================================================
    -- Tinymist LSP
    -- =========================================================================
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

            local capabilities = has_cmp and cmp_nvim_lsp.default_capabilities()
                or vim.lsp.protocol.make_client_capabilities()

            capabilities.offsetEncoding = {
                "utf-8",
                "utf-16",
            }

            opts.servers = opts.servers or {}

            opts.servers.tinymist = {
                capabilities = capabilities,

                root_dir = function(fname)
                    return vim.fs.root(fname, {
                        "typst.toml",
                        ".git",
                    }) or vim.fs.dirname(fname)
                end,

                on_new_config = function(new_config, root_dir)
                    new_config.settings = new_config.settings or {}
                    new_config.settings.rootPath = root_dir

                    local fonts_dir = root_dir .. "/fonts"
                    if vim.fn.isdirectory(fonts_dir) == 1 then
                        new_config.settings.fontPaths = { fonts_dir }
                    else
                        new_config.settings.fontPaths = {}
                    end
                end,

                settings = {
                    formatterMode = "typstyle",
                    projectResolution = "lockDatabase",
                    exportPdf = "onSave",
                },

                keys = {
                    {
                        "<leader>tP",
                        function()
                            local bufnr = vim.api.nvim_get_current_buf()
                            local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "tinymist" })
                            if #clients == 0 then
                                vim.notify("Tinymist LSP is not active on this buffer", vim.log.levels.WARN)
                                return
                            end
                            clients[1]:exec_cmd({
                                title = "Pin Main Target",
                                command = "tinymist.pinMainToCurrent",
                            }, { bufnr = bufnr })
                            vim.notify(
                                "Pinned " .. vim.fn.expand("%:t") .. " as Tinymist main target",
                                vim.log.levels.INFO
                            )
                        end,
                        desc = "Typst: Pin Current File as Main Target",
                    },
                    {
                        "<leader>tU",
                        function()
                            local bufnr = vim.api.nvim_get_current_buf()
                            local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "tinymist" })
                            if #clients == 0 then
                                vim.notify("Tinymist LSP is not active on this buffer", vim.log.levels.WARN)
                                return
                            end
                            clients[1]:exec_cmd({
                                title = "Unpin Main Target",
                                command = "tinymist.unpinMain",
                            }, { bufnr = bufnr })
                            vim.notify("Unpinned Tinymist main target", vim.log.levels.INFO)
                        end,
                        desc = "Typst: Unpin Main Target",
                    },
                },

                on_attach = function(client, bufnr)
                    -- Fallback: auto-format on save via LSP if conform is not active
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = bufnr,
                        callback = function()
                            local has_conform, conform = pcall(require, "conform")
                            if has_conform then
                                conform.format({ bufnr = bufnr, lsp_fallback = true })
                            else
                                vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 2000 })
                            end
                        end,
                    })

                    -- Semantic tokens
                    if client.server_capabilities.semanticTokensProvider then
                        vim.lsp.semantic_tokens.start(bufnr, client.id)
                    end

                    -- Inlay hints
                    if client.server_capabilities.inlayHintProvider then
                        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
                    end

                    -- Code lens
                    if client.server_capabilities.codeLensProvider then
                        vim.lsp.codelens.refresh({ bufnr = bufnr })
                        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
                            buffer = bufnr,
                            callback = function()
                                if vim.api.nvim_buf_is_valid(bufnr) then
                                    vim.lsp.codelens.refresh({ bufnr = bufnr })
                                end
                            end,
                        })
                    end

                    -- Document highlight
                    if client.server_capabilities.documentHighlightProvider then
                        local group =
                            vim.api.nvim_create_augroup("tinymist-document-highlight-" .. bufnr, { clear = true })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            group = group,
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.document_highlight()
                            end,
                        })
                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            group = group,
                            buffer = bufnr,
                            callback = function()
                                vim.lsp.buf.clear_references()
                            end,
                        })
                    end
                end,
            }
        end,
    },

    -- =========================================================================
    -- Browser Live Preview
    -- =========================================================================
    {
        "chomosuke/typst-preview.nvim",
        ft = "typst",
        version = "1.*",
        opts = function()
            local function get_root(path)
                return vim.fs.root(path, {
                    "typst.toml",
                    ".git",
                }) or vim.fs.dirname(path)
            end

            local function get_main_file(path)
                local root = get_root(path)
                local main = vim.fs.find("main.typ", {
                    path = root,
                    type = "file",
                    limit = 1,
                })[1]
                return main or path
            end

            return {
                open_cmd = "xdg-open %s",
                invert_colors = "never",
                follow_cursor = true,
                refresh_rate = "onType",
                get_main_file = get_main_file,
                get_root = get_root,
                dependencies_bin = {
                    tinymist = "tinymist",
                    websocat = "websocat",
                },
            }
        end,
        keys = {
            { "<leader>tp", "<cmd>TypstPreviewToggle<cr>", desc = "Typst: Toggle Browser Preview" },
            { "<leader>tc", "<cmd>TypstPreviewFollowCursorToggle<cr>", desc = "Typst: Toggle Follow Cursor" },
            { "<leader>ts", "<cmd>TypstPreviewSyncCursor<cr>", desc = "Typst: Sync Cursor" },
        },
    },
}

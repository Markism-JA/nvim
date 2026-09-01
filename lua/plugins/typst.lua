-- ============================================================================
-- Typst Pipeline: Logging & Diagnostics
-- ============================================================================
local ENABLE_DEBUG = true
local LOG_FILE = vim.fn.stdpath("state") .. "/typst-pipeline.log"

local function typst_log(stage, data)
    if not ENABLE_DEBUG then
        return
    end
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local header = string.format("[%s] [Typst Pipeline | %s]\n", timestamp, stage)
    local body = vim.inspect(data) .. "\n" .. string.rep("-", 80) .. "\n"

    local file = io.open(LOG_FILE, "a")
    if file then
        file:write(header .. body)
        file:close()
    end
end

vim.api.nvim_create_user_command("TypstLog", function()
    vim.cmd("tabedit " .. vim.fn.fnameescape(LOG_FILE))
    vim.cmd("normal! G")
end, { desc = "Open Typst pipeline debug log" })

vim.api.nvim_create_user_command("TypstLogClear", function()
    local file = io.open(LOG_FILE, "w")
    if file then
        file:write("")
        file:close()
        vim.notify("Typst debug log cleared.", vim.log.levels.INFO)
    end
end, { desc = "Clear Typst pipeline debug log" })

-- ============================================================================
-- Filetype Detection
-- ============================================================================
vim.filetype.add({
    extension = {
        typ = function(path, bufnr)
            typst_log("Filetype Detection (.typ)", { path = path, bufnr = bufnr })
            return "typst"
        end,
        typst = function(path, bufnr)
            typst_log("Filetype Detection (.typst)", { path = path, bufnr = bufnr })
            return "typst"
        end,
    },
})

-- ============================================================================
-- Workspace & Path Resolution
-- ============================================================================
local function normalize_path(path)
    if type(path) == "number" then
        path = vim.api.nvim_buf_get_name(path)
    end
    if not path or path == "" then
        path = vim.api.nvim_buf_get_name(0)
    end
    return (path and path ~= "") and vim.fs.normalize(path) or vim.uv.cwd()
end

local function get_typst_project_root(raw_path)
    local path = normalize_path(raw_path)

    local env_root = os.getenv("TYPST_ROOT")
    if env_root and env_root ~= "" and vim.uv.fs_stat(env_root) then
        return env_root
    end

    local stat = vim.uv.fs_stat(path)
    local start_dir = (stat and stat.type == "directory") and path or vim.fs.dirname(path)

    local typst_root = vim.fs.root(start_dir, { "typst.toml" })
    if typst_root then
        return typst_root
    end

    local doc_root = vim.fs.root(start_dir, { "spec", "docs" })
    if doc_root then
        return doc_root
    end

    local git_root = vim.fs.root(start_dir, { ".git" })
    return git_root or start_dir or vim.fn.getcwd()
end

--- Locates the document entrypoint in multi-file projects (e.g., main.typ)
local function resolve_typst_entrypoint(raw_path)
    local buffer_path = normalize_path(raw_path)
    local root = get_typst_project_root(buffer_path)
    local parent_dir = vim.fs.dirname(buffer_path)
    local entry_names = { "main.typ", "document.typ", "root.typ", "index.typ", "lib.typ" }

    -- 1. Search upwards from buffer directory to project root
    local current = parent_dir
    while current and #current >= #root do
        for _, name in ipairs(entry_names) do
            local candidate = current .. "/" .. name
            if vim.uv.fs_stat(candidate) and candidate ~= buffer_path then
                typst_log("Entrypoint Found (Subtree)", candidate)
                return candidate
            end
        end
        if current == root then
            break
        end
        current = vim.fs.dirname(current)
    end

    -- 2. Check root directly
    for _, name in ipairs(entry_names) do
        local candidate = root .. "/" .. name
        if vim.uv.fs_stat(candidate) then
            typst_log("Entrypoint Found (Root)", candidate)
            return candidate
        end
    end

    return buffer_path
end

--- Discovers project font directories
local function resolve_font_path(raw_path)
    local path = normalize_path(raw_path)
    local root = get_typst_project_root(path)
    local font_candidates = {
        root .. "/fonts",
        root .. "/assets/fonts",
        vim.fs.dirname(path) .. "/fonts",
    }

    for _, dir in ipairs(font_candidates) do
        if vim.uv.fs_stat(dir) then
            typst_log("Font Directory Found", dir)
            return dir
        end
    end
    return nil
end

-- ============================================================================
-- Plugin Specs
-- ============================================================================
return {
    -- Mason Package Manager
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "tinymist" })
        end,
    },

    -- Tinymist LSP Configuration
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = opts.servers or {}
            opts.servers.tinymist = {
                filetypes = { "typst" },
                single_file_support = true,
                root_dir = function(fname)
                    return get_typst_project_root(fname)
                end,

                settings = {
                    exportPdf = "never",
                    formatterMode = "typstyle",
                    projectResolution = "lockDatabase",
                    semanticTokens = "enable",
                },

                keys = {
                    {
                        "<leader>cp",
                        function()
                            local client = vim.lsp.get_clients({ name = "tinymist", bufnr = 0 })[1]
                            if not client then
                                vim.notify("Tinymist client not attached", vim.log.levels.WARN)
                                return
                            end

                            local buf_name = vim.api.nvim_buf_get_name(0)
                            client:exec_cmd({
                                title = "pin",
                                command = "tinymist.pinMain",
                                arguments = { buf_name },
                            }, { bufnr = 0 })

                            vim.notify("Tinymist: Pinned main to " .. vim.fs.basename(buf_name), vim.log.levels.INFO)
                        end,
                        desc = "Tinymist: Pin Main File",
                    },
                    {
                        "<leader>cu",
                        function()
                            local client = vim.lsp.get_clients({ name = "tinymist", bufnr = 0 })[1]
                            if not client then
                                vim.notify("Tinymist client not attached", vim.log.levels.WARN)
                                return
                            end

                            client:exec_cmd({
                                title = "unpin",
                                command = "tinymist.pinMain",
                                arguments = { vim.NIL },
                            }, { bufnr = 0 })

                            vim.notify("Tinymist: Unpinned main file", vim.log.levels.INFO)
                        end,
                        desc = "Tinymist: Unpin Main File",
                    },
                },

                on_new_config = function(new_config, new_root_dir)
                    local bufname = vim.api.nvim_buf_get_name(0)
                    local font_dir = resolve_font_path(bufname)
                    local font_settings = { "fonts", "assets/fonts" }

                    if font_dir then
                        table.insert(font_settings, font_dir)
                    end

                    new_config.settings = new_config.settings or {}
                    new_config.settings.rootPath = new_root_dir
                    new_config.settings.fontPaths = font_settings

                    new_config.settings.tinymist = new_config.settings.tinymist or {}
                    new_config.settings.tinymist.rootPath = new_root_dir
                    new_config.settings.tinymist.fontPaths = font_settings

                    typst_log("LSP Injection Payload (on_new_config)", {
                        rootPath = new_root_dir,
                        fontPaths = font_settings,
                    })
                end,
            }
        end,
        -- Trigger LSP registration and enable Tinymist on Neovim 0.12
        config = function(_, opts)
            local lspconfig = require("lspconfig")
            local tinymist_opts = opts.servers and opts.servers.tinymist or {}

            lspconfig.tinymist.setup(tinymist_opts)

            -- Explicitly enable server in Nvim 0.12 core
            if vim.lsp.enable then
                vim.lsp.enable("tinymist")
            end
        end,
    },

    -- Typst Preview Configuration
    {
        "chomosuke/typst-preview.nvim",
        ft = "typst",
        cmd = { "TypstPreview", "TypstPreviewToggle", "TypstPreviewUpdate" },
        keys = {
            { "<leader>cp", "<cmd>TypstPreviewToggle<cr>", desc = "Toggle Typst Preview" },
        },
        opts = {
            debug = false,
            invert_colors = "never",
            partial_rendering = true,
            follow_cursor = true,
            dependencies_bin = {
                tinymist = "tinymist",
            },
            get_root = function(path_of_main_file)
                return get_typst_project_root(path_of_main_file)
            end,
            get_main_file = function(path_of_buffer)
                return resolve_typst_entrypoint(path_of_buffer)
            end,
            extra_args = function()
                local buf_path = vim.api.nvim_buf_get_name(0)
                local font_dir = resolve_font_path(buf_path)
                if font_dir then
                    return { "--font-path", font_dir }
                end
                return nil
            end,
        },
    },
}

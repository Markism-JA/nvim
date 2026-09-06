-- ============================================================================
-- Typst Pipeline: Logging & Diagnostics
-- ============================================================================
local ENABLE_DEBUG = false
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
-- Custom Typst Exporter (Flexible Destination & Renaming)
-- ============================================================================

--- Exports the document to a specified target directory/file or custom name asynchronously.
--- @param target? string Optional target path or custom output filename.
local function export_typst_document(target)
    local buf_path = vim.api.nvim_buf_get_name(0)
    local root = get_typst_project_root(buf_path)
    local entrypoint = resolve_typst_entrypoint(buf_path)
    local font_dir = resolve_font_path(buf_path)

    local default_name = vim.fs.basename(entrypoint):gsub("%.typ$", "")
    local dist_dir = root .. "/dist"
    local target_out = ""

    if not target or target == "" then
        -- Default: <root>/dist/<default_name>.pdf
        if not vim.uv.fs_stat(dist_dir) then
            vim.fn.mkdir(dist_dir, "p")
        end
        target_out = dist_dir .. "/" .. default_name .. ".pdf"
    else
        target = vim.fs.normalize(target)

        -- If the user only gave a new filename (no directory slashes)
        if not target:find("/") then
            if not target:match("%.pdf$") then
                target = target .. ".pdf"
            end
            if not vim.uv.fs_stat(dist_dir) then
                vim.fn.mkdir(dist_dir, "p")
            end
            target_out = dist_dir .. "/" .. target
        else
            -- If user provided a path
            local stat = vim.uv.fs_stat(target)
            if (stat and stat.type == "directory") or target:sub(-1) == "/" then
                if not vim.uv.fs_stat(target) then
                    vim.fn.mkdir(target, "p")
                end
                target_out = target:gsub("/+$", "") .. "/" .. default_name .. ".pdf"
            else
                if not target:match("%.pdf$") then
                    target = target .. ".pdf"
                end
                local parent = vim.fs.dirname(target)
                if parent and not vim.uv.fs_stat(parent) then
                    vim.fn.mkdir(parent, "p")
                end
                target_out = target
            end
        end
    end

    -- Build CLI args
    local cmd = { "typst", "compile", "--root", root }
    if font_dir then
        table.insert(cmd, "--font-path")
        table.insert(cmd, font_dir)
    end
    table.insert(cmd, entrypoint)
    table.insert(cmd, target_out)

    vim.notify("Typst: Compiling export to " .. target_out .. "...", vim.log.levels.INFO)

    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
                vim.schedule(function()
                    vim.notify("Typst Export Error:\n" .. table.concat(data, "\n"), vim.log.levels.ERROR)
                end)
            end
        end,
        on_exit = function(_, code)
            vim.schedule(function()
                if code == 0 then
                    vim.notify("Typst: Successfully exported to " .. target_out, vim.log.levels.INFO)
                else
                    vim.notify("Typst: Export failed with exit code " .. code, vim.log.levels.ERROR)
                end
            end)
        end,
    })
end

-- User Command: supports tab-completion for paths
vim.api.nvim_create_user_command("TypstExport", function(opts)
    local target = opts.args ~= "" and opts.args or nil
    export_typst_document(target)
end, {
    nargs = "?",
    complete = "file",
    desc = "Export Typst document (optional custom name or path)",
})

-- ============================================================================
-- Plugin Specs
-- ============================================================================
return {
    -- Mason Package Manager
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            vim.list_extend(opts.ensure_installed, { "tinymist", "typstyle" })
        end,
    },

    -- Tinymist LSP Configuration
    {
        "neovim/nvim-lspconfig",
        keys = {
            {
                "<leader>cP",
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
                ft = "typst",
                desc = "Pin Main File",
            },
            {
                "<leader>cU",
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
                ft = "typst",
                desc = "Unpin Main File",
            },
            {
                "<leader>cz",
                function()
                    local buf_name = vim.api.nvim_buf_get_name(0)
                    local main_file = resolve_typst_entrypoint(buf_name)
                    local pdf_file = main_file:gsub("%.typ$", ".pdf")

                    if vim.uv.fs_stat(pdf_file) then
                        local line = vim.api.nvim_win_get_cursor(0)[1]
                        vim.fn.jobstart({
                            "zathura",
                            "--synctex-forward",
                            string.format("%d:1:%s", line, buf_name),
                            pdf_file,
                        }, { detach = true })
                        vim.notify("Opened Zathura: " .. vim.fs.basename(pdf_file), vim.log.levels.INFO)
                    else
                        vim.notify("PDF not found. Save the file first to trigger compilation.", vim.log.levels.WARN)
                    end
                end,
                ft = "typst",
                desc = "Open in Zathura",
            },
            -- Quick export to project dist/<entrypoint>.pdf
            {
                "<leader>ce",
                function()
                    vim.cmd("TypstExport")
                end,
                ft = "typst",
                desc = "Export PDF (Default)",
            },
            -- Interactive prompt: enter a custom name OR full path
            {
                "<leader>cE",
                function()
                    local buf_path = vim.api.nvim_buf_get_name(0)
                    local entrypoint = resolve_typst_entrypoint(buf_path)
                    local default_name = vim.fs.basename(entrypoint):gsub("%.typ$", "")

                    vim.ui.input({
                        prompt = "Export name or path: ",
                        default = default_name,
                        completion = "file",
                    }, function(input)
                        if input and input ~= "" then
                            vim.cmd("TypstExport " .. vim.fn.fnameescape(input))
                        end
                    end)
                end,
                ft = "typst",
                desc = "Export PDF (Custom Name / Path)",
            },
        },

        filetypes = { "typst" },
        single_file_support = true,
        root_markers = { "typst.toml", ".git" },
        root_dir = function(bufnr)
            return get_typst_project_root(bufnr)
        end,

        init_options = {
            formatterMode = "typstyle",
        },

        settings = {
            exportPdf = "onSave",
            formatterMode = "typstyle",
            projectResolution = "lockDatabase",
            semanticTokens = "enable",
        },

        before_init = function(_, config)
            local buffname = vim.api.nvim.buf_get_name(0)
            local font_dir = resolve_font_path(buffname)
            local font_settings = { "fonts", "assets/fonts" }

            if font_dir then
                table.insert(font_settings, font_dir)
            end

            local root = config.root_dir or get_typst_project_root(buffname)
            config.settings.formatterMode = "typstyle"
            config.settings.rootPath = root
            config.settings.fontPaths = font_settings

            config.settings.tinymist = config.settings.tinymist or {}
            config.settings.tinymist.formatterMode = "typstyle"
            config.settings.tinymist.rootPath = root
            config.settings.tinymist.fontPaths = font_settings

            typst_log("LSP Injection Payload (before_init)", {
                rootPath = root,
                fontPaths = font_settings,
            })
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
            -- Use a specific browser (e.g., Brave, Chromium, Firefox, Zen)
            open_cmd = "firefox --private-window %s", -- Firefox (Gecko) is the most performant I've noticed
            -- or: open_cmd = "zen-browser %s", -- '%s' is replaced by the local preview URL
            -- or: open_cmd = "brave --new-window %s",

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

    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters = opts.formatters or {}

            opts.formatters.typstyle = {
                prepend_args = {
                    -- "--wrap-text=sentence", -- One sentence per line (best for git diffs)
                    "--wrap-text=fill", -- Wrap paragraphs to line-width (80 cols)

                    "--line-width",
                    "100",
                },
            }

            opts.formatters_by_ft.typst = { "typstyle" }
        end,
    },
}

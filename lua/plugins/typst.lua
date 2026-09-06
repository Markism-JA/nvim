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
---@param path? string|number
---@return string
local function normalize_path(path)
    local p = path
    if type(p) == "number" then
        p = vim.api.nvim_buf_get_name(p)
    end
    if not p or p == "" then
        p = vim.api.nvim_buf_get_name(0)
    end

    if p and p ~= "" then
        return vim.fs.normalize(p)
    end

    return vim.uv.cwd() or "."
end

---@param raw_path? string|number
---@return string
local function get_typst_project_root(raw_path)
    local path = normalize_path(raw_path)

    local env_root = os.getenv("TYPST_ROOT")
    if env_root and env_root ~= "" and vim.uv.fs_stat(env_root) then
        return env_root
    end

    local stat = vim.uv.fs_stat(path)
    local dirname = vim.fs.dirname(path)
    ---@type string
    local start_dir = ((stat and stat.type == "directory") and path) or dirname or vim.uv.cwd()

    local typst_root = vim.fs.root(start_dir, { "typst.toml" })
    if typst_root then
        return typst_root
    end

    local doc_root = vim.fs.root(start_dir, { "spec", "docs" })
    if doc_root then
        return doc_root
    end

    local git_root = vim.fs.root(start_dir, { ".git" })
    return git_root or start_dir
end

--- Locates the document entrypoint in multi-file projects (e.g., main.typ)
---@param raw_path? string|number
---@return string
local function resolve_typst_entrypoint(raw_path)
    local buffer_path = normalize_path(raw_path)
    local root = get_typst_project_root(buffer_path)
    local parent_dir = vim.fs.dirname(buffer_path) or root
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
        current = vim.fs.dirname(current) or root
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
---@param raw_path? string|number
---@return string?
local function resolve_font_path(raw_path)
    local path = normalize_path(raw_path)
    local root = get_typst_project_root(path)
    local dir_parent = vim.fs.dirname(path) or root
    local font_candidates = {
        root .. "/fonts",
        root .. "/assets/fonts",
        dir_parent .. "/fonts",
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
-- Centralized Pinning State Machine & Status Indicators
-- ============================================================================
--- Stores project-level pin state: [project_root] = { path = string, manual = boolean }
local pinned_roots = {}

local function update_typst_pin_indicators(target_root)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "typst" then
            local buf_path = normalize_path(bufnr)
            local root = get_typst_project_root(buf_path)

            if not target_root or root == target_root then
                local pin_info = pinned_roots[root]
                if pin_info and pin_info.path then
                    local is_main = (buf_path == pin_info.path)
                    local tag = pin_info.manual and "📌 (manual)" or "📌"
                    local target_name = vim.fs.basename(pin_info.path)

                    if is_main then
                        vim.b[bufnr].typst_pin_status = string.format("%s [Main]", tag)
                    else
                        vim.b[bufnr].typst_pin_status = string.format("%s -> %s", tag, target_name)
                    end

                    vim.b[bufnr].typst_pinned_file = pin_info.path
                    vim.b[bufnr].typst_is_manual_pin = pin_info.manual
                else
                    vim.b[bufnr].typst_pin_status = ""
                    vim.b[bufnr].typst_pinned_file = nil
                    vim.b[bufnr].typst_is_manual_pin = false
                end
            end
        end
    end
end

local function get_active_typst_entrypoint(raw_path)
    local path = normalize_path(raw_path)
    local root = get_typst_project_root(path)
    local pin_info = pinned_roots[root]

    if pin_info and pin_info.path and vim.uv.fs_stat(pin_info.path) then
        return pin_info.path, pin_info.manual
    end

    local detected = resolve_typst_entrypoint(path)
    return detected, false
end

-- ============================================================================
-- Custom Typst Exporter
-- ============================================================================
local function export_typst_document(target)
    local buf_path = vim.api.nvim_buf_get_name(0)
    local root = get_typst_project_root(buf_path)
    local entrypoint = get_active_typst_entrypoint(buf_path)
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
        opts = {
            servers = {
                tinymist = {
                    filetypes = { "typst" },
                    single_file_support = true,
                    root_markers = { "typst.toml", ".git" },
                    root_dir = function(bufnr_or_path)
                        return get_typst_project_root(bufnr_or_path)
                    end,

                    init_options = {
                        formatterMode = "typstyle",
                    },

                    settings = {
                        exportPdf = "onType",
                        formatterMode = "typstyle",
                        projectResolution = "lockDatabase",
                        semanticTokens = "enable",
                    },

                    keys = {
                        -- Manual Override: Pin active buffer as main
                        {
                            "<leader>cP",
                            function()
                                local client = vim.lsp.get_clients({ name = "tinymist", bufnr = 0 })[1]
                                if not client then
                                    vim.notify("Tinymist client not attached", vim.log.levels.WARN)
                                    return
                                end

                                local buf_name = normalize_path(0)
                                local root = get_typst_project_root(buf_name)

                                pinned_roots[root] = { path = buf_name, manual = true }
                                client:exec_cmd({
                                    title = "pin",
                                    command = "tinymist.pinMain",
                                    arguments = { buf_name },
                                }, { bufnr = 0 })

                                update_typst_pin_indicators(root)
                                vim.notify(
                                    "Tinymist: Manually pinned to " .. vim.fs.basename(buf_name),
                                    vim.log.levels.INFO
                                )
                            end,
                            desc = "Pin Main File (Manual Override)",
                        },
                        -- Reset: Clear manual override and fallback to auto-detection
                        {
                            "<leader>cU",
                            function()
                                local client = vim.lsp.get_clients({ name = "tinymist", bufnr = 0 })[1]
                                if not client then
                                    vim.notify("Tinymist client not attached", vim.log.levels.WARN)
                                    return
                                end

                                local buf_name = normalize_path(0)
                                local root = get_typst_project_root(buf_name)
                                local auto_entrypoint = resolve_typst_entrypoint(buf_name)

                                pinned_roots[root] = { path = auto_entrypoint, manual = false }
                                client:exec_cmd({
                                    title = "unpin",
                                    command = "tinymist.pinMain",
                                    arguments = { auto_entrypoint },
                                }, { bufnr = 0 })

                                update_typst_pin_indicators(root)
                                vim.notify(
                                    "Tinymist: Reset pin to auto-detected " .. vim.fs.basename(auto_entrypoint),
                                    vim.log.levels.INFO
                                )
                            end,
                            desc = "Reset Pin to Auto-Detected Main",
                        },
                        {
                            "<leader>cz",
                            function()
                                local buf_name = vim.api.nvim_buf_get_name(0)
                                local main_file = get_active_typst_entrypoint(buf_name)
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
                                    vim.notify(
                                        "PDF not found. Save the file first to trigger compilation.",
                                        vim.log.levels.WARN
                                    )
                                end
                            end,
                            desc = "Open in Zathura",
                        },
                        {
                            "<leader>ce",
                            function()
                                vim.cmd("TypstExport")
                            end,
                            desc = "Export PDF (Default)",
                        },
                        {
                            "<leader>cE",
                            function()
                                local buf_path = vim.api.nvim_buf_get_name(0)
                                local entrypoint = get_active_typst_entrypoint(buf_path)
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
                            desc = "Export PDF (Custom Name / Path)",
                        },
                    },

                    on_attach = function(client, bufnr)
                        local buf_path = normalize_path(bufnr)
                        local root = get_typst_project_root(buf_path)
                        local pin_info = pinned_roots[root]
                        local target_entrypoint = nil

                        if pin_info and pin_info.manual and pin_info.path then
                            target_entrypoint = pin_info.path
                        else
                            target_entrypoint = resolve_typst_entrypoint(buf_path)
                            pinned_roots[root] = { path = target_entrypoint, manual = false }
                        end

                        if target_entrypoint and target_entrypoint ~= "" then
                            client:exec_cmd({
                                title = "pin",
                                command = "tinymist.pinMain",
                                arguments = { target_entrypoint },
                            }, { bufnr = bufnr })
                        end

                        update_typst_pin_indicators(root)
                    end,

                    on_init = function(client, _)
                        local target_path = client.root_dir or vim.api.nvim_buf_get_name(0)
                        local font_dir = resolve_font_path(target_path)
                        local font_settings = { "fonts", "assets/fonts" }

                        if font_dir then
                            table.insert(font_settings, font_dir)
                        end

                        local root = client.root_dir or get_typst_project_root(target_path)

                        client.settings = client.settings or {}
                        client.settings.exportPdf = "onType"
                        client.settings.formatterMode = "typstyle"
                        client.settings.rootPath = root
                        client.settings.fontPaths = font_settings

                        client.settings.tinymist = client.settings.tinymist or {}
                        client.settings.tinymist.exportPdf = "onType"
                        client.settings.tinymist.formatterMode = "typstyle"
                        client.settings.tinymist.rootPath = root
                        client.settings.tinymist.fontPaths = font_settings

                        client:notify("workspace/didChangeConfiguration", {
                            settings = client.settings,
                        })

                        typst_log("LSP Dynamic Settings Applied (on_init)", {
                            rootPath = root,
                            fontPaths = font_settings,
                        })
                    end,
                },
            },

            setup = {
                tinymist = function(_, opts)
                    require("lspconfig").tinymist.setup(opts)
                    return true
                end,
            },
        },
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

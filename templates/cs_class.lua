return {
    name = "C# Class",
    ext = "cs",

    content = function(filename, dir)
        -- 1. Namespace Logic
        local function get_namespace(target_dir)
            local project_root = vim.fs.find(function(name)
                return name:match("%.csproj$")
            end, { path = target_dir, upward = true })[1]

            if not project_root then
                return vim.fn.fnamemodify(target_dir, ":t")
            end

            local root_dir = vim.fs.dirname(project_root)
            local rel_path = target_dir:sub(#root_dir + 2)
            local ns = rel_path:gsub("/", ".")
            local project_name = vim.fn.fnamemodify(root_dir, ":t")

            return ns == "" and project_name or (project_name .. "." .. ns)
        end

        local ns = get_namespace(dir)

        return {
            "namespace " .. ns,
            "{",
            "    public class " .. filename,
            "    {",
            "        public " .. filename .. "()",
            "        {",
            "            $CURSOR",
            "        }",
            "    }",
            "}",
        }
    end,
}

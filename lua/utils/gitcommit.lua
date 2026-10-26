local M = {}

local token_cache = {
  bearer = nil,
  expires_at = 0,
}

--- Wraps a single line of text at max_width respecting word boundaries
---@param text string
---@param max_width number
---@param indent? string
---@return string[]
function M.wrap_text(text, max_width, indent)
  indent = indent or ""
  local words = vim.split(text, "%s+", { trimempty = true })
  if #words == 0 then
    return { "" }
  end

  local lines = {}
  local current = ""
  for _, word in ipairs(words) do
    if current == "" then
      current = word
    elseif #(current .. " " .. word) <= max_width then
      current = current .. " " .. word
    else
      table.insert(lines, current)
      current = indent .. word
    end
  end
  if current ~= "" then
    table.insert(lines, current)
  end
  return lines
end

--- Formats a full git commit buffer adhering strictly to Conventional Commits:
--- - Subject line kept intact on line 1 (trimmed)
--- - Line 2 guaranteed to be blank if body exists
--- - Body paragraphs wrapped strictly at max_width (default 72)
--- - Bullet points (- / * / + / 1.) wrapped with matching hanging indentation
--- - Code fences (```) preserved verbatim
--- - Git trailers (Signed-off-by:, BREAKING CHANGE:, etc.) formatted cleanly
--- - Git comments (# ...) preserved verbatim at bottom
---@param lines string[]
---@param max_width? number
---@return string[]
function M.format_commit_buffer(lines, max_width)
  max_width = max_width or 72
  local formatted = {}
  local in_code_block = false

  local content_lines = {}
  local comment_lines = {}
  local found_comments = false

  -- Separate content lines from trailing git comments (# ...)
  for _, line in ipairs(lines) do
    if not found_comments then
      if line:match("^%s*#") then
        found_comments = true
        table.insert(comment_lines, line)
      else
        table.insert(content_lines, line)
      end
    else
      table.insert(comment_lines, line)
    end
  end

  -- Trim trailing empty lines from content
  while #content_lines > 0 and vim.trim(content_lines[#content_lines]) == "" do
    table.remove(content_lines)
  end

  if #content_lines == 0 then
    return lines
  end

  -- Line 1 is the subject / title
  local title = vim.trim(content_lines[1] or "")
  table.insert(formatted, title)

  if #content_lines > 1 then
    table.insert(formatted, "") -- Always ensure line 2 is blank

    local idx = 2
    while idx <= #content_lines and vim.trim(content_lines[idx]) == "" do
      idx = idx + 1
    end

    local current_para = {}
    local current_bullet = nil

    local function flush_para()
      if #current_para > 0 then
        local para_text = table.concat(current_para, " ")
        local wrapped = M.wrap_text(para_text, max_width)
        for _, wl in ipairs(wrapped) do
          table.insert(formatted, wl)
        end
        current_para = {}
      end
    end

    local function flush_bullet()
      if current_bullet then
        local bullet = current_bullet.bullet
        local indent = string.rep(" ", #bullet)
        local all_words = vim.split(table.concat(current_bullet.words, " "), "%s+", { trimempty = true })
        local cur = bullet
        for _, w in ipairs(all_words) do
          if cur == bullet then
            cur = bullet .. w
          elseif #(cur .. " " .. w) <= max_width then
            cur = cur .. " " .. w
          else
            table.insert(formatted, cur)
            cur = indent .. w
          end
        end
        if cur ~= "" then
          table.insert(formatted, cur)
        end
        current_bullet = nil
      end
    end

    while idx <= #content_lines do
      local line = content_lines[idx]
      local trimmed = vim.trim(line)

      if trimmed:match("^```") then
        flush_para()
        flush_bullet()
        in_code_block = not in_code_block
        table.insert(formatted, line)
      elseif in_code_block then
        table.insert(formatted, line)
      elseif trimmed == "" then
        flush_para()
        flush_bullet()
        table.insert(formatted, "")
      else
        local bullet, rest = line:match("^(%s*[%-%*%+]%s+)(.*)$")
        if not bullet then
          bullet, rest = line:match("^(%s*%d+%.%s+)(.*)$")
        end

        if bullet then
          flush_para()
          flush_bullet()
          current_bullet = { bullet = bullet, words = { rest } }
        elseif current_bullet and line:match("^%s%s+") then
          -- Continuation line under list item
          table.insert(current_bullet.words, trimmed)
        elseif trimmed:match("^[A-Z][a-zA-Z%-]+:%s+") or trimmed:match("^BREAKING CHANGE:") then
          -- Git trailer or breaking change
          flush_para()
          flush_bullet()
          if #trimmed > max_width then
            local key, val = trimmed:match("^(.-:%s*)(.*)$")
            if key and val then
              local words = vim.split(val, "%s+", { trimempty = true })
              local cur = key
              local indent = "  "
              for _, w in ipairs(words) do
                if cur == key then
                  cur = key .. w
                elseif #(cur .. " " .. w) <= max_width then
                  cur = cur .. " " .. w
                else
                  table.insert(formatted, cur)
                  cur = indent .. w
                end
              end
              if cur ~= "" then
                table.insert(formatted, cur)
              end
            else
              table.insert(formatted, trimmed)
            end
          else
            table.insert(formatted, trimmed)
          end
        else
          flush_bullet()
          table.insert(current_para, trimmed)
        end
      end
      idx = idx + 1
    end
    flush_para()
    flush_bullet()
  end

  -- Re-attach git comments
  if #comment_lines > 0 then
    if #formatted > 0 and formatted[#formatted] ~= "" then
      table.insert(formatted, "")
    end
    for _, l in ipairs(comment_lines) do
      table.insert(formatted, l)
    end
  end

  return formatted
end

--- Re-wraps the given buffer to max_width (default 72) preserving cursor
---@param bufnr? number
---@param max_width? number
function M.wrap_current_buffer(bufnr, max_width)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local formatted = M.format_commit_buffer(lines, max_width or 72)

  if not vim.deep_equal(lines, formatted) then
    local win = vim.api.nvim_get_current_win()
    local cursor = nil
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      cursor = vim.api.nvim_win_get_cursor(win)
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)

    if cursor and vim.api.nvim_win_is_valid(win) then
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local row = math.min(cursor[1], line_count)
      local col = math.min(cursor[2], #(formatted[row] or ""))
      pcall(vim.api.nvim_win_set_cursor, win, { row, col })
    end
  end
end

--- Retrieves the GitHub OAuth token for Copilot from local config or environment
---@return string?
function M.get_github_oauth_token()
  -- 1. Environment variables
  local env_token = os.getenv("COPILOT_TOKEN") or os.getenv("GITHUB_TOKEN")
  if env_token and env_token ~= "" then
    return env_token
  end

  -- 2. Copilot config files (apps.json, hosts.json)
  local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local files = {
    config_home .. "/github-copilot/apps.json",
    config_home .. "/github-copilot/hosts.json",
  }

  for _, path in ipairs(files) do
    local f = io.open(path, "r")
    if f then
      local data = f:read("*a")
      f:close()
      local ok, json = pcall(vim.json.decode, data)
      if ok and json then
        for k, v in pairs(json) do
          if k:find("github.com") and v and v.oauth_token then
            return v.oauth_token
          end
        end
      end
    end
  end

  -- 3. GitHub CLI
  if vim.fn.executable("gh") == 1 then
    local out = vim.fn.system({ "gh", "auth", "token" })
    if vim.v.shell_error == 0 then
      local tok = vim.trim(out)
      if tok ~= "" and not tok:find("no oauth token") then
        return tok
      end
    end
  end

  return nil
end

--- Retrieves an active Copilot Bearer token asynchronously
---@param callback fun(token: string?, err: string?)
function M.get_copilot_token(callback)
  local now = os.time()
  if token_cache.bearer and token_cache.expires_at > (now + 60) then
    callback(token_cache.bearer, nil)
    return
  end

  local oauth = M.get_github_oauth_token()
  if not oauth then
    callback(nil, "No GitHub Copilot authentication found. Please sign in via :Copilot auth or GitHub CLI.")
    return
  end

  local ok_pcurl, pcurl = pcall(require, "plenary.curl")
  if not ok_pcurl then
    callback(nil, "plenary.nvim is required for HTTP requests")
    return
  end

  pcurl.get("https://api.github.com/copilot_internal/v2/token", {
    headers = {
      ["Authorization"] = "Token " .. oauth,
    },
    callback = vim.schedule_wrap(function(res)
      if not res or res.status ~= 200 then
        callback(nil, "Failed to authenticate Copilot token: " .. tostring(res and res.body or "network error"))
        return
      end

      local ok, body = pcall(vim.json.decode, res.body)
      if not ok or not body or not body.token then
        callback(nil, "Invalid authentication response from Copilot")
        return
      end

      token_cache.bearer = body.token
      token_cache.expires_at = body.expires_at or (os.time() + 1800)
      callback(token_cache.bearer, nil)
    end),
  })
end

--- Retrieves staged git diff and status information
---@return table? staged_info
function M.get_staged_info()
  local git_check = vim.fn.system({ "git", "rev-parse", "--is-inside-work-tree" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Not inside a git repository", vim.log.levels.WARN, { title = "Git Commit AI" })
    return nil
  end

  local staged_files = vim.fn.system({ "git", "diff", "--cached", "--name-status" })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to retrieve staged files", vim.log.levels.ERROR, { title = "Git Commit AI" })
    return nil
  end

  if vim.trim(staged_files) == "" then
    local status = vim.fn.system({ "git", "status", "--porcelain" })
    if vim.trim(status) ~= "" then
      vim.notify("⚠️ No staged changes found! Stage files with `git add` before committing.", vim.log.levels.WARN, {
        title = "Git Commit AI",
      })
    else
      vim.notify("Working tree clean. Nothing to commit.", vim.log.levels.INFO, { title = "Git Commit AI" })
    end
    return nil
  end

  local stat = vim.fn.system({ "git", "diff", "--cached", "--stat" })
  local diff = vim.fn.system({ "git", "diff", "--cached" })

  -- Truncate diff if extremely large to prevent token overflow
  if #diff > 12000 then
    diff = diff:sub(1, 12000) .. "\n\n[... staged diff truncated for length ...]"
  end

  return {
    files = staged_files,
    stat = stat,
    diff = diff,
  }
end

--- Generates a conventional commit message from staged changes using Copilot Chat API
---@param callback fun(lines: string[])
function M.generate_message(callback)
  local staged = M.get_staged_info()
  if not staged then
    return
  end

  local ok_pcurl, pcurl = pcall(require, "plenary.curl")
  if not ok_pcurl then
    vim.notify("plenary.nvim is required for AI generation", vim.log.levels.ERROR, { title = "Git Commit AI" })
    return
  end

  vim.notify("🤖 Analyzing staged changes & generating commit message...", vim.log.levels.INFO, {
    title = "Git Commit AI",
  })

  M.get_copilot_token(function(bearer_token, err)
    if err or not bearer_token then
      vim.notify("Copilot auth failed: " .. tostring(err), vim.log.levels.ERROR, { title = "Git Commit AI" })
      return
    end

    local system_prompt = [[You are an expert Git commit message generator.
Generate a concise, professional commit message following the Conventional Commits specification based strictly on the staged changes provided.

Rules:
1. Format: <type>(<optional scope>): <description>
2. Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
3. Title line: imperative mood, lowercase description (e.g. "feat(auth): add OAuth2 provider"), strictly <= 50 characters, never exceed 72, NO period at end.
4. Blank line between title and body.
5. Body (if needed): explain WHAT changed and WHY (not how). Each line wrapped strictly at <= 72 characters.
6. Bullet points use "- " with 2 spaces indent on continuation lines.
7. If there are breaking changes, include "BREAKING CHANGE: <explanation>".
8. Output ONLY the raw commit message text. Do NOT wrap in markdown code blocks (```). Do NOT include conversational comments.]]

    local user_prompt = "Staged Summary:\n" .. staged.stat .. "\n\nStaged Changes:\n" .. staged.diff

    pcurl.post("https://api.githubcopilot.com/chat/completions", {
      headers = {
        ["Authorization"] = "Bearer " .. bearer_token,
        ["Editor-Version"] = "Neovim/" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
        ["Editor-Plugin-Version"] = "CopilotChat.nvim/*",
        ["Copilot-Integration-Id"] = "vscode-chat",
        ["Content-Type"] = "application/json",
      },
      body = vim.json.encode({
        model = "gpt-4o",
        messages = {
          { role = "system", content = system_prompt },
          { role = "user", content = user_prompt },
        },
      }),
      callback = vim.schedule_wrap(function(res)
        if not res or res.status ~= 200 then
          local err_msg = res and res.body or "network error"
          vim.notify("Copilot API error (" .. tostring(res and res.status) .. "): " .. err_msg, vim.log.levels.ERROR, {
            title = "Git Commit AI",
          })
          return
        end

        local ok_json, body = pcall(vim.json.decode, res.body)
        if not ok_json or not body or not body.choices or not body.choices[1] then
          vim.notify("Failed to parse Copilot response", vim.log.levels.ERROR, { title = "Git Commit AI" })
          return
        end

        local raw_content = body.choices[1].message.content or ""
        -- Strip markdown code block fences if any
        local cleaned = raw_content:gsub("^```[%w]*\r?\n", ""):gsub("\r?\n```%s*$", "")
        cleaned = vim.trim(cleaned)

        local lines = vim.split(cleaned, "\n", { plain = true })
        local formatted = M.format_commit_buffer(lines, 72)
        callback(formatted)
      end),
    })
  end)
end

--- Inserts generated commit message directly into an active gitcommit buffer
---@param bufnr? number
function M.insert_into_gitcommit_buffer(bufnr)
  bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()

  M.generate_message(function(lines)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      bufnr = vim.api.nvim_get_current_buf()
    end

    local existing = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Locate where git comments begin (#)
    local comment_idx = #existing + 1
    for idx, line in ipairs(existing) do
      if line:match("^%s*#") then
        comment_idx = idx
        break
      end
    end

    local new_lines = {}
    for _, l in ipairs(lines) do
      table.insert(new_lines, l)
    end
    table.insert(new_lines, "")

    for idx = comment_idx, #existing do
      table.insert(new_lines, existing[idx])
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)

    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == bufnr then
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end

    vim.notify("✨ Conventional commit message generated! Press :w or :wq to commit.", vim.log.levels.INFO, {
      title = "Git Commit AI",
    })
  end)
end

--- Opens a sleek floating git commit editor pre-populated with AI generated commit message
function M.commit_staged_interactive()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  -- If already in a gitcommit buffer, insert directly
  if ft == "gitcommit" then
    M.insert_into_gitcommit_buffer(bufnr)
    return
  end

  local staged = M.get_staged_info()
  if not staged then
    return
  end

  M.generate_message(function(lines)
    -- Format git status comments
    local status_raw = vim.fn.system({ "git", "-c", "color.status=false", "status" })
    local comment_block = {
      "# Please enter the commit message for your changes. Lines starting",
      "# with '#' will be ignored, and an empty message aborts the commit.",
      "#",
    }
    for _, s_line in ipairs(vim.split(status_raw, "\n", { plain = true })) do
      if s_line ~= "" then
        table.insert(comment_block, "# " .. s_line)
      end
    end

    local full_content = {}
    for _, l in ipairs(lines) do
      table.insert(full_content, l)
    end
    table.insert(full_content, "")
    for _, l in ipairs(comment_block) do
      table.insert(full_content, l)
    end

    local tmpfile = vim.fn.tempname() .. ".COMMIT_EDITMSG"
    local f = io.open(tmpfile, "w")
    if not f then
      vim.notify("Failed to create temporary commit file", vim.log.levels.ERROR, { title = "Git Commit AI" })
      return
    end
    f:write(table.concat(full_content, "\n") .. "\n")
    f:close()

    local committed = false

    local function do_commit(win_obj)
      if committed then
        return
      end

      -- Re-wrap buffer before commit
      if win_obj and win_obj.buf and vim.api.nvim_buf_is_valid(win_obj.buf) then
        M.wrap_current_buffer(win_obj.buf, 72)
        vim.api.nvim_buf_call(win_obj.buf, function()
          vim.cmd("silent! write")
        end)
      end

      local out = vim.fn.system({ "git", "commit", "-F", tmpfile, "--cleanup=strip" })
      if vim.v.shell_error == 0 then
        committed = true
        if win_obj then
          win_obj:close()
        end
        pcall(os.remove, tmpfile)
        local summary = vim.split(vim.trim(out), "\n")[1] or "Committed successfully"
        vim.notify("🎉 " .. summary, vim.log.levels.INFO, { title = "Git Commit" })
        vim.cmd("checktime")
      else
        if out:find("empty commit message") then
          committed = true
          if win_obj then
            win_obj:close()
          end
          pcall(os.remove, tmpfile)
          vim.notify("Commit aborted (empty commit message)", vim.log.levels.WARN, { title = "Git Commit" })
        else
          vim.notify("Git commit error:\n" .. out, vim.log.levels.ERROR, { title = "Git Commit" })
        end
      end
    end

    if Snacks and Snacks.win then
      local win = Snacks.win({
        file = tmpfile,
        position = "float",
        border = "rounded",
        width = 0.78,
        height = 0.72,
        title = " Git Commit (:wq or <C-c><C-c> to commit, q to abort) ",
        title_pos = "center",
        ft = "gitcommit",
        enter = true,
        keys = {
          ["<C-c><C-c>"] = function(self)
            do_commit(self)
          end,
          ["<leader><CR>"] = function(self)
            do_commit(self)
          end,
          ["q"] = function(self)
            self:close()
            pcall(os.remove, tmpfile)
            vim.notify("Commit cancelled.", vim.log.levels.INFO, { title = "Git Commit" })
          end,
        },
      })

      -- Hook commit onto window closure if the file was modified/written
      vim.api.nvim_create_autocmd("WinClosed", {
        pattern = tostring(win.win),
        once = true,
        callback = function()
          vim.schedule(function()
            if not committed then
              -- Check if user committed via :wq
              local f_check = io.open(tmpfile, "r")
              if f_check then
                local current_content = f_check:read("*a")
                f_check:close()
                -- If non-comment lines exist, commit
                local has_content = false
                for _, cl in ipairs(vim.split(current_content, "\n")) do
                  if not cl:match("^%s*#") and vim.trim(cl) ~= "" then
                    has_content = true
                    break
                  end
                end
                if has_content then
                  do_commit(nil)
                else
                  pcall(os.remove, tmpfile)
                end
              end
            end
          end)
        end,
      })
    else
      -- Fallback split buffer
      vim.cmd("split " .. vim.fn.fnameescape(tmpfile))
      local win_id = vim.api.nvim_get_current_win()
      vim.keymap.set("n", "<C-c><C-c>", function()
        do_commit({
          close = function()
            pcall(vim.api.nvim_win_close, win_id, true)
          end,
          buf = vim.api.nvim_get_current_buf(),
        })
      end, { buffer = true, desc = "Submit git commit" })
    end
  end)
end

return M

-- Tab indentation
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- Line width and wrapping
vim.opt_local.textwidth = 72
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true

-- Auto-wrap formatting options:
-- 't' = auto-wrap text using textwidth as you type
-- 'c' = auto-wrap comments using textwidth
-- 'r' = auto-insert comment/list leader on <Enter>
-- 'o' = auto-insert comment/list leader on 'o' or 'O'
-- 'q' = allow formatting comments with "gq" / "gw"
-- 'n' = recognize numbered lists
-- 'j' = remove comment leader when joining lines
vim.opt_local.formatoptions:append("tcrqonj")
vim.opt_local.formatoptions:remove("l")

-- List patterns for bulleted points in commit body
vim.opt_local.formatlistpat = [[^\s*[\-\*]\s\+]]

-- Visual guidelines: column 50 for subject line, column 72 for body limit
vim.opt_local.colorcolumn = "50,72"

-- Spell checking for commit messages
vim.opt_local.spell = true
vim.opt_local.spelllang = "en_us"

local bufnr = vim.api.nvim_get_current_buf()

-- Buffer-local keymaps
local map_opts = { buffer = bufnr, silent = true }

-- Generate AI commit message into the buffer
vim.keymap.set("n", "<localleader>g", function()
  require("utils.gitcommit").insert_into_gitcommit_buffer(bufnr)
end, vim.tbl_extend("force", map_opts, { desc = "Generate commit message with AI (staged)" }))

vim.keymap.set("n", "<leader>cg", function()
  require("utils.gitcommit").insert_into_gitcommit_buffer(bufnr)
end, vim.tbl_extend("force", map_opts, { desc = "Generate commit message with AI (staged)" }))

-- Hard-wrap commit body at 72 characters (paragraph / entire buffer)
vim.keymap.set("n", "<localleader>w", function()
  require("utils.gitcommit").wrap_current_buffer(bufnr, 72)
  vim.notify("Wrapped commit body to 72 characters", vim.log.levels.INFO, { title = "Git Commit" })
end, vim.tbl_extend("force", map_opts, { desc = "Wrap commit body to 72 cols" }))

vim.keymap.set("n", "<leader>cw", function()
  require("utils.gitcommit").wrap_current_buffer(bufnr, 72)
  vim.notify("Wrapped commit body to 72 characters", vim.log.levels.INFO, { title = "Git Commit" })
end, vim.tbl_extend("force", map_opts, { desc = "Wrap commit body to 72 cols" }))

-- Auto line wrapping on save (BufWritePre)
local autowrap_group = vim.api.nvim_create_augroup("gitcommit_autowrap_" .. bufnr, { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = autowrap_group,
  buffer = bufnr,
  callback = function()
    if not vim.b[bufnr].disable_gitcommit_autowrap then
      require("utils.gitcommit").wrap_current_buffer(bufnr, 72)
    end
  end,
  desc = "Auto-wrap git commit message body to 72 cols on save",
})

-- Buffer-local user commands
vim.api.nvim_buf_create_user_command(bufnr, "GitCommitAI", function()
  require("utils.gitcommit").insert_into_gitcommit_buffer(bufnr)
end, { desc = "Generate Conventional Commit Message with AI from staged changes" })

vim.api.nvim_buf_create_user_command(bufnr, "GitCommitWrap", function()
  require("utils.gitcommit").wrap_current_buffer(bufnr, 72)
  vim.notify("Wrapped commit body to 72 characters", vim.log.levels.INFO, { title = "Git Commit" })
end, { desc = "Wrap git commit body to 72 characters" })

-- Move cursor to line 1, column 1 when opening COMMIT_EDITMSG
vim.schedule(function()
  if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_get_current_buf() == bufnr then
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    -- If the commit message is currently empty (only git comments exist), show helpful hint
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
    local first_line = lines[1] or ""
    if first_line == "" or first_line:match("^%s*#") then
      vim.notify("💡 Press <localleader>g (or :GitCommitAI) to generate commit message from staged changes.", vim.log.levels.INFO, { title = "Git Commit" })
    end
  end
end)

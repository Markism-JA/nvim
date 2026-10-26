return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    build = "make tiktoken",
    opts = function(_, opts)
      opts.model = "gpt-4o"
      opts.prompts = opts.prompts or {}
      opts.prompts.CommitStaged = {
        prompt = "Write a concise commit message following Conventional Commits for the staged changes. Keep title under 50 chars and body wrapped at 72 chars.",
        resources = { "gitdiff:staged" },
      }
      return opts
    end,
    keys = {
      {
        "<leader>aG",
        function()
          require("utils.gitcommit").commit_staged_interactive()
        end,
        desc = "AI Git Commit (Staged Changes)",
        mode = { "n" },
      },
      {
        "<leader>gc",
        function()
          require("utils.gitcommit").commit_staged_interactive()
        end,
        desc = "AI Git Commit (Staged Changes)",
        mode = { "n" },
      },
    },
    init = function()
      vim.api.nvim_create_user_command("GitCommitAI", function()
        require("utils.gitcommit").commit_staged_interactive()
      end, { desc = "Generate Conventional Commit Message with AI from staged changes" })
    end,
  },
}

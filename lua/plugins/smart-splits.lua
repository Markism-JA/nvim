return {
  {
    "mrjones2014/smart-splits.nvim",
    opts = {
      ignored_filetypes = { "nofile", "quickfix", "qf", "prompt" },
      ignored_buftypes = { "NvimTree", "neo-tree", "notify" },
    },
    keys = {
      -- Move between splits
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
        desc = "Go to left split",
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
        desc = "Go to below split",
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
        desc = "Go to above split",
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
        desc = "Go to right split",
      },

      -- Resize splits
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
        desc = "Resize Split Left",
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
        desc = "Resize Split Right",
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
        desc = "Resize Split Down",
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
        desc = "Resize Split Up",
      },

      -- Swap windows
      {
        "<leader><leader>h",
        function()
          require("smart-splits").swap_buf_left()
        end,
        desc = "Swap Buffer Left",
      },
      {
        "<leader><leader>j",
        function()
          require("smart-splits").swap_buf_down()
        end,
        desc = "Swap Buffer Down",
      },
      {
        "<leader><leader>k",
        function()
          require("smart-splits").swap_buf_up()
        end,
        desc = "Swap Buffer Up",
      },
      {
        "<leader><leader>l",
        function()
          require("smart-splits").swap_buf_right()
        end,
        desc = "Swap Buffer Right",
      },
    },
  },
}

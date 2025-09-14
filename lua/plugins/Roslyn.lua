return {
  -- Add a custom plugin spec for roslyn.nvim
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor" },
    dependencies = {
      {
        "tris203/rzls.nvim",
        config = true,
      },
      "mason-lspconfig.nvim", -- Declare a dependency on mason-lspconfig
    },
    opts = {}, -- You can add custom options for roslyn.nvim here
    config = function()
      -- Configure the roslyn.nvim plugin to communicate with rzls
      require("roslyn").setup({
        handlers = require("rzls.roslyn_handlers"),
        -- Other configuration options for roslyn.nvim
      })
    end,
  },
}

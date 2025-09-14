-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("mason").setup({
  registries = {
    "github:mason-org/mason-registry",
    "github:Crashdummyy/mason-registry",
  },
})

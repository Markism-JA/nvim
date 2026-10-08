-- tab indentation
vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.expandtab = true

-- line width
vim.opt_local.textwidth = 72

vim.opt_local.formatoptions:append("ntcq")
vim.opt_local.formatlistpat = [[^\s*-\s\+]]

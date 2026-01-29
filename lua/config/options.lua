-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
-- Indentation settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.shiftwidth = 4 -- Number of spaces for each indentation level
vim.opt.tabstop = 4 -- Number of spaces a <Tab> counts for
vim.opt.softtabstop = 4 -- Number of spaces when pressing <Tab>
vim.opt.autoindent = true -- Copy indentation from current line
vim.opt.smartindent = true -- Smarter auto-indenting when starting a new line

vim.filetype.add({
    extension = {
        csproj = "xml",
        props = "xml",
        targets = "xml",
        axaml = "xml",
    },
})

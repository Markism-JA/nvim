vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.guifont = "JetBrainsMono Nerd Font:h9"
if vim.g.neovide then
    vim.g.neovide_padding_top = 20
    vim.g.neovide_padding_bottom = 20
    vim.g.neovide_padding_left = 20
    vim.g.neovide_padding_right = 20
end

vim.filetype.add({
    extension = {
        csproj = "xml",
        props = "xml",
        targets = "xml",
        axaml = "xml",
    },
})

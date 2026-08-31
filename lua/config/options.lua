vim.o.exrc = true

vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc"
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true
vim.g.lazygit_config = false
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

vim.filetype.add({
    extension = {
        asm = "nasm",
        s = "nasm",
    },
})

vim.filetype.add({
    extension = {
        xsl = "xsl",
        xslt = "xslt",
        jsx = "javascript.jsx",
        tsx = "typescript.tsx",
        typ = "typst",
        typst = "typst",
        dox = "c.doxygen",
    },
    pattern = {
        [".*docker%-compose.*%.ya?ml"] = "yaml.docker-compose",
        [".*compose.*%.ya?ml"] = "yaml.docker-compose",
        [".*gitlab%-ci.*%.ya?ml"] = "yaml.gitlab",
        [".*/templates/.*%.ya?ml"] = "yaml.helm-values",
        [".*values.*%.ya?ml"] = "yaml.helm-values",
        [".*%.dox"] = "c.doxygen",
        [".*%.doxygen"] = "cpp.doxygen",
    },
})

vim.lsp.log.set_level(vim.lsp.log.levels.ERROR)

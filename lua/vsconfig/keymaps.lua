vim.g.mapleader = " "
vim.keymap.set("n", "<leader>e", function()
    vim.fn["VSCodeNotify"]("workbench.view.explorer")
end)

-- Shift+H to go to the next tab (left)
vim.keymap.set("n", "H", function()
    vim.fn.VSCodeNotify("workbench.action.previousEditorInGroup")
end)

-- Shift+l (L) to go to the next tab (right)
vim.keymap.set("n", "L", function()
    vim.fn.VSCodeNotify("workbench.action.nextEditorInGroup")
end)

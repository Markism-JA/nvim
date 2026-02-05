return {
    {
        "mfussenegger/nvim-dap",
        config = function()
            local dap = require("dap")

            local signs = {
                DapBreakpoint = {
                    text = "●",
                    texthl = "DapBreakpoint",
                    linehl = "DapBreakpointLine",
                    numhl = "DapBreakpoint",
                },
                DapBreakpointCondition = {
                    text = "●",
                    texthl = "DapBreakpointCondition",
                    linehl = "DapBreakpointLine",
                    numhl = "DapBreakpointCondition",
                },
                DapBreakpointRejected = {
                    text = "",
                    texthl = "DapBreakpoint",
                    linehl = "DapBreakpointLine",
                    numhl = "DapBreakpoint",
                },

                DapStopped = { text = "▶", texthl = "DapStopped", linehl = "", numhl = "DapStopped" },

                DapLogPoint = { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "DapLogPoint" },
            }

            for type, icon in pairs(signs) do
                vim.fn.sign_define(type, icon)
            end

            vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#ff5d5e" })
            vim.api.nvim_set_hl(0, "DapBreakpointLine", { bg = "#2a1010" })

            vim.api.nvim_set_hl(0, "DapStopped", { fg = "#9ece6a" })

            local function configure_external_terminal()
                if vim.env.TMUX then
                    dap.defaults.fallback.external_terminal =
                        { command = "tmux", args = { "split-window", "-h", "-p", "50" } }
                elseif vim.env.TERMINAL and vim.fn.executable(vim.env.TERMINAL) == 1 then
                    dap.defaults.fallback.external_terminal = { command = vim.env.TERMINAL, args = { "-e" } }
                else
                    local terms = { "kitty", "alacritty", "wezterm", "foot", "gnome-terminal" }
                    for _, t in ipairs(terms) do
                        if vim.fn.executable(t) == 1 then
                            dap.defaults.fallback.external_terminal = { command = t, args = { "-e" } }
                            break
                        end
                    end
                end
                dap.defaults.fallback.force_external_terminal = true
            end

            configure_external_terminal()
        end,
    },
}

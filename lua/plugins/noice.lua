return {
    "folke/noice.nvim",
    opts = {
        lsp = {
            progress = {
                format = function(event)
                    -- Safely get client name
                    local client_name = ""
                    if event.client_id then
                        local client = vim.lsp.get_client_by_id(event.client_id)
                        if client then
                            client_name = client.name
                        end
                    end

                    -- Disable progress for Roslyn
                    if client_name == "roslyn" then
                        return ""
                    end

                    -- Fallback for other LSPs (avoid nil errors)
                    local token = event.token or "?"
                    local message = (event.value and event.value.message) or ""
                    return token .. ": " .. message
                end,
            },
        },
    },
}

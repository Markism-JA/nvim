local uname = vim.loop.os_uname().sysname

return {
    is_windows = uname == "Windows_NT",
    is_linux = uname == "Linux",
    is_mac = uname == "Darwin",
}

require("plenary.reload").reload_module("neovim-irc-ui");

local IrcWindow = require("neovim-irc-ui.ui")

local window = IrcWindow:new()
window:toggle_main()

window:write_to_main({
    "",
    "",
    " WELCOME TO PRIME's IRC",
    "",
})

window:write_to_main({
    "",
    "",
    " WELCOME TO PRIME's IRC",
    "",
})


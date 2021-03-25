require("plenary.reload").reload_module("neovim-irc-ui");

Client = require("neovim-irc-ui")

Client.open()

function ircm(message)
    Client.message(message)
end


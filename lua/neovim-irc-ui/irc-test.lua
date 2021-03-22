require("plenary.reload").reload_module("neovim-irc-ui");

local Client = require("neovim-irc-ui.irc_client")

function Irc_multi_client(n)
    local client1 = Client:new("BESATCOSUCKS")
    client1:open_irc()
    client1:on("line", function(line)
        print("Client1", line)
    end)

    local client2 = Client:new("YAYAYAY")
    client2:open_irc()
    client2:on("line", function(line)
        print("Client2", line)
    end)

    local timer = vim.loop.new_timer()
    local next = { client1, client2 }
    local next_idx = 0

    timer:start(100, 1000, vim.schedule_wrap(function()
        pcall(function()
            next_idx = next_idx + 1
            local idx = (math.fmod(next_idx, 2)) + 1
            local client = next[idx]

            print("Idx", idx, client)
            client.tcpClient:msg(client.name, string.format("HELLO %d", next_idx))
        end)
    end))
end

IRCClient = nil
function Irc_single_client_global()
    IRCClient = Client:new("Global")
    IRCClient:on("line", function(line)
        print("IRCClient", line)
    end)
    IRCClient:open_irc()
end



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
            client.ircClient:msg(client.name, string.format("HELLO %d", next_idx))
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

function parse_to_token_test()
    local test = "foo bar baz"
    local res = parse_to_token(test, 1, " ")
    print(vim.inspect(res))

    print(type(res.offset), res.offset)
    res = parse_to_token(test, res.offset, " ")
    print(vim.inspect(res))
end

function parse_irc_message_test()
    print(vim.inspect(parse_irc_message(":foo PRIVMSG bar :test\r\n")))
    print(vim.inspect(parse_irc_message(":foo JOIN\r\n")))
    print(vim.inspect(parse_irc_message(":foo PONG\r\n")))
    print(vim.inspect(parse_irc_message(":foo PING\r\n")))
end

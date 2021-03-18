require("plenary.reload").reload_module("neovim-irc-ui");

local Client = require("neovim-irc-ui")

local client1 = Client:new(0, "BESATCOSUCKS")
client1:open_irc()

local client2 = Client:new(50, "YAYAYAY")
client2:open_irc()


local timer = vim.loop.new_timer()

local next = { client1, client2 }
local next_idx = 0

timer:start(1000, 750, vim.schedule_wrap(function()
    pcall(function()
        next_idx = next_idx + 1
        local idx = (math.fmod(next_idx, 2)) + 1
        local client = next[idx]

        print("Idx", idx, client)
        client:msg(client.name, string.format("HELLO %d", next_idx))
    end)
end))

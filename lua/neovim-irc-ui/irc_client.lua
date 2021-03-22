local TcpClient = require("neovim-irc-ui.tcp_client")

local function listen_to_client(client)
    client.tcpClient:on("connect", function(err)
        if err ~= nil then
            print("ERROR", err)
            error("Unable to connect to theprimeagen's irc server.")
            client:disconnect()
            return
        end

        vim.schedule(function()
            client:_callback("connected", nil)
            client:_join(client.name)
        end)
    end)

    client.tcpClient:on("data", function(line)
        -- Aggregate the irc chat
        client:process_irc_msg(line)
    end)

    client.tcpClient:on("disconnect", function()
        client:on_tcp_close()
    end)
end

local IrcClient = {}
function IrcClient:new(name)
    local obj = {
        neovimIrcData = {},
        tcpClient = nil,
        name = name,
        host = "irc.theprimeagen.tv",
        port = 1337,
        callbacks = {},
    }

    assert(#name > 0)

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function IrcClient:on_tcp_close()
    self:_callback("disconnected", nil)
end

function IrcClient:_callback(event, ...)
    if self.callbacks[event] == nil then
        return;
    end
    for idx = 1, #self.callbacks[event] do
        self.callbacks[event][idx](...)
    end
end


function IrcClient:process_irc_msg(line)
    -- TODO: DO THIS BETTER...
    -- You are not even aggregating the lines...
    -- what are you doing.  If the chat is moving fast enough, you could
    -- technically receive the 2 lines one message...
    self:_callback("line", line)
end

function IrcClient:open_irc()
    if self.tcpClient == nil then
        self.tcpClient = TcpClient:new(self.host, self.port)
        self.tcpClient:connect()
        listen_to_client(self)
    end
end

function IrcClient:disconnect()
    if self.tcpClient == nil then
        return
    end
    self.tcpClient:disconnect()
end

function IrcClient:write(msg)
    if not self.tcpClient:isConnected() then
        error("You are not connected, please call M.open_irc")
    end

    self.tcpClient:msg(self.name, msg)
end

local join_command = ":%s JOIN\r\n"
function IrcClient:_join(name)
    if not self.tcpClient:write(string.format(join_command, name)) then
    end
end

local msg_command = ":%s PRIVMSG %s :%s\r\n"
function IrcClient:msg(str)
    local host = string.format("%s:%d", self.host, self.port)
    local msg = string.format(msg_command, self.name, host, str)
    print("IRCClient:MSG", msg)
    if not self.tcpClient:write(msg) then
        -- what do i do here?
    end
end

function IrcClient:on(event, callback)
    if self.callbacks[event] == nil then
        self.callbacks[event] = {}
    end

    table.insert(self.callbacks[event], callback);
end

return IrcClient

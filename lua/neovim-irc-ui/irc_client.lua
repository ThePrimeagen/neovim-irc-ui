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
        partial_message = "",
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

local function parse_to_token(line, offset, token)

    local start = string.find(line, token, offset, false)
    if start == nil then
        return nil
    end

    return {
        item = line:sub(offset, start - 1),
        offset = start + 1,
    }
end

local function parse_irc_message(line)
    local pos = 1
    local to = ""
    local from = ""
    local params = ""
    local cmd = ""

    -- parse out name
    local results = parse_to_token(line, pos, " ")
    if results == nil then
        return nil
    end
    pos = results.offset
    from = results.item

    local command_res = parse_to_token(line, pos, " ") or
                        parse_to_token(line, pos, "\r\n")
    if command_res == nil then
        return nil
    end
    pos = command_res.offset
    cmd = command_res.item

    if cmd == "JOIN" or cmd == "PING" then
        -- TODO: TECHNICALLY THERE IS NO CHANNELS, but we don't support
        return {
            to = to,
            from = from,
            cmd = cmd,
            params = params
        }
    elseif cmd ~= "PRIVMSG" then
        return nil
    end

    local to_res = parse_to_token(line, pos, " ")
    if to_res == nil then
        return nil
    end
    pos = to_res.offset
    to = to_res.item

    if parse_to_token(line, pos, "\r\n") == nil then
        return nil
    end

    params = line:sub(pos)

    if line:sub(pos, pos) ~= ":" then
        return nil
    end

    return {
        to = to,
        from = from,
        cmd = cmd,
        params = params
    }
end

function IrcClient:process_irc_msg(line)
    local message = self.partial_message .. line
    local start = nil

    repeat
        start = string.find(message, "\r\n", 1, false)
        if start ~= nil then
            self:_callback("line", parse_irc_message(line))
            message = message:sub(start + 2)
        end
    until start == nil or #message == 0
    self.partial_message = message
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

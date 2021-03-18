local states = {
    disconnected = 1,
    connecting = 2,
    connected = 3,
    error = 4,
    timedout = 5,
}

local IrcClient = {}

function IrcClient:new(host, port)
    local obj = {
        host = host,
        port = port,
        client = nil,
        state = states.disconnected,
        callbacks = {},
    }

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function IrcClient:isConnected()
    return self.state == states.connected
end

function IrcClient:_callback(event, ...)
    if self.callbacks[event] == nil then
        return;
    end
    for idx = 1, #self.callbacks[event] do
        self.callbacks[event][idx](...)
    end
end

function IrcClient:_get_ip(host)
    local results = vim.loop.getaddrinfo(host)
    local actual_addr = nil

    for idx = 1, #results do
        local res = results[idx]
        if res.family == "inet" and res.socktype == "stream" then
            actual_addr = res.addr
        end
    end

    return actual_addr
end

function IrcClient:_connect_to_irc()
    print("TCP#connect_to_irc FIRST LINE")
    self.client = vim.loop.new_tcp()

    local ip = self:_get_ip(self.host)

    self.state = states.connecting

    print("TCP#connect_to_irc", ip, self.host)
    self.client:connect(ip, tonumber(self.port), function (err)
        print("CONNECTED!!", ip, self.host)
        if self.state ~= states.connecting then
            return
        end

        if err ~= nil then
            self.state = states.error
            self:_callback("connect", err)
            return
        end

        self.state = states.connected

        self.client:read_start(vim.schedule_wrap(function(_, chunk)
            if chunk == nil then
                self:_callback("disconnected", nil)
                return
            end
            self:_callback("data", chunk)
        end))

        self:_callback("connect", nil);
    end)

    vim.fn.timer_start(10000, function()
        if self.state == states.connected then
            return
        end

        self.state = states.timedout
        self:_callback("connect",
            string.format("Unable to connect to %s:%d", self.host, self.port))
    end)
end

function IrcClient:isError()
    return self.state == states.error
end

function IrcClient:isTimeout()
    return self.state == states.timedout
end

function IrcClient:disconnect()
    if self.state == states.connecting then
        self.state = states.disconnected
    end

    if self.client == nil then
        return
    end

    self.client:shutdown()
    self.client:close()
    self.client = nil
end

function IrcClient:connect()
    if self.state ~= states.disconnected then
        return
    end

    self:_connect_to_irc()
end

function IrcClient:on(event, callback)
    if self.callbacks[event] == nil then
        self.callbacks[event] = {}
    end

    table.insert(self.callbacks[event], callback);
end

local join_command = ":%s JOIN\r\n"
function IrcClient:join(name)
    self:_write(string.format(join_command, name))
end

function IrcClient:_write(str)
    if self.state ~= states.connected then
        return
    end

    self.client:write(str)
end

local msg_command = ":%s PRIVMSG %s :%s\r\n"
function IrcClient:msg(name, str)
    if self.state ~= states.connected then
        return
    end

    local host = string.format("%s:%d", self.host, self.port)
    self.client:write(string.format(msg_command, name, host, str))
end

return IrcClient

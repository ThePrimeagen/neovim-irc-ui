local TcpClient = require("neovim-irc-ui.tcp_client")
local Path = require("plenary.path")
local path_to_data = string.format("%s/%s", vim.fn.stdpath("data"), "theprimeagen-neovim-irc.json")

--[[
local function move_cursor_to_end()
    if not vim.api.nvim_buf_is_valid(NircBufnr) or
       not vim.api.nvim_win_is_valid(NircWinId) then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(NircBufnr)
    vim.api.nvim_win_set_cursor(NircWinId, {line_count - 1, 0})
end

local function refresh_data(client)
    local ok = pcall(function()
        NeovimIrcData = vim.fn.json_decode(Path:new(path_to_data):read())
    end)

    if not ok then
        NeovimIrcData = {}
    end
end

--]]

local punc = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
local alpha_numeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function valid_text(text)
    if text == nil or type(text) ~= "string" or #text == 0 then
        return false
    end

    for idx = 1, #text do
        local char = text:sub(idx, idx)
        print("Char", idx, "is", char, " :: ", punc:match(char), " == nil and ", alpha_numeric:match(char), " == nil")

        -- SORRY FOR INLINE RETURNING...
        if punc:match(char) == nil and alpha_numeric:match(char) == nil then
            return false
        end
    end

    return true
end

local function get_valid_text(question, reprompt)
    local text
    repeat
        text = vim.fn.input(question)

        print("WHAT WAS MY TEXT", text)
        if not valid_text(text) then
            error("Please provide valid text (a-Z and punc)")
            text = nil
        end

    until text ~= nil and (not reprompt or text ~= "")

    return text
end


local function listen_to_client(client)
    print("Attempting to connect to the client")
    client.ircClient:on("connect", function(err)
        print("Connected to the client")
        if err ~= nil then
            print("ERROR", err)
            error("Unable to connect to theprimeagen's irc server.")
            client:disconnect()
            return
        end

        -- refresh_data()

        vim.schedule(function()
            client:create_win_thanks_anttttt()
            client:write_to_window({
                "",
                "",
                " Welcome to ThePrimeagen's IRC",
                "",
                "",
            })

            if client.name == nil then
                client.name = get_valid_text("IRC Name? ", true)
            end

            client.ircClient:join(client.name)
        end)
    end)

    client.ircClient:on("data", function(line)
        -- Aggregate the irc chat
        client:process_irc_msg(line)
    end)

    client.ircClient:on("disconnect", function() client:on_tcp_close() end)
end

local Client = {}
function Client:new(offset, name)
    local obj = {
        neovimIrcData = {},
        ircWinId = nil,
        ircBufnr = nil,
        ircClient = nil,
        name = name,
        win_id = nil,
        buf_nr = nil,
        x_offset = offset
    }

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function Client:on_tcp_close()
    print("THIS?? IS CLOSEDDD%%!!!!")
end

function Client:create_win_thanks_anttttt(options)
    local default_options = {
        relative = 'editor',
        style = 'minimal',
        width = 30,
        height = 15,
        row = 2,
        col = self.x_offset + 2,
    }
    options = vim.tbl_extend('keep', options or {}, default_options)

    if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
        -- annnnttttt THANKS FOR FN
        self.bufnr = options.bufnr or vim.api.nvim_create_buf(false, true)
    end

    if not self.win_id or not vim.api.nvim_buf_is_valid(self.win_id) then
        -- annnnttttt THANKS FOR FN
        self.win_id = vim.api.nvim_open_win(self.bufnr, true, options)
    end

    vim.api.nvim_win_set_buf(NircWinId, self.bufnr)
end


function Client:write_to_window(lines)
    if not vim.api.nvim_buf_is_valid(self.bufnr) then
        return
    end

    vim.api.nvim_buf_set_lines(self.bufnr, -1, -1, false, lines)
    -- // DO THIS LATER
    -- move_cursor_to_end()
end


function Client:process_irc_msg(line)
    print("process_irc_msg", line)
end

function Client:open_irc()
    print("Self client", self.ircClient)
    if self.ircClient == nil then
        self.ircClient = TcpClient:new("irc.theprimeagen.tv", 1337)
        self.ircClient:connect()
        listen_to_client(self)
    end
end

function Client:close_irc_win()
    if NircWinId == nil then
        return
    end

    vim.api.nvim_win_close(NircWinId, true)
    NircWinId = nil
end

function Client:disconnect()
    self.close_irc_win()
    if self.ircClient == nil then
        return
    end
    self.ircClient:disconnect()
end

function Client:write()
    if not self.ircClient:isConnected() then
        error("You are not connected, please call M.open_irc")
    end

    local text = get_valid_text("Message to send: ")
    if not text then
        return
    end

    self.ircClient:msg(self.name, text)
end

return Client

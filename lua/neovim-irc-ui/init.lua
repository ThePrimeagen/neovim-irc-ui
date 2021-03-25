local Client = require("neovim-irc-ui.irc_client")
local Window = require("neovim-irc-ui.ui")

local punc = "! \"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
local alpha_numeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function valid_text(text)
    if text == nil or type(text) ~= "string" or #text == 0 then
        return false
    end

    for idx = 1, #text do
        local char = text:sub(idx, idx)

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

        if not valid_text(text) then
            error("Please provide valid text (a-Z and punc)")
            text = nil
        end

    until text ~= nil and (not reprompt or text ~= "")

    return text
end

local IrcClient = nil
local IrcWindow = nil

local M = {}

local function create_client()
    if IrcClient ~= nil then
        return
    end

    local name = get_valid_text("Your IRC Name: ")

    IrcClient = Client:new(name)
    IrcClient:open_irc()

    IrcWindow = Window:new()

    IrcClient:on("line", function(parsed)
        if parsed.cmd == "JOIN" then
            IrcWindow:write_to_main({string.format("welcome %s!", parsed.from)})
            return
        end

        local line = parsed.params
        local start = string.find(line, '\r\n', 1, true)
        if start ~= nil then
            line = line:gsub("\r\n", "")
        end

        IrcWindow:write_to_main({string.format("%s: %s", parsed.from, line)})
    end)
end

M.open = function()
    create_client()
    IrcWindow:open_main()
end

M.close = function()
    if IrcWindow ~= nil then
        IrcWindow:close_main()
    end
end

M.disconnect = function()
    IrcClient:disconnect()
    IrcWindow:close_main()

    IrcClient = nil
    IrcWindow = nil
end

M.toggle = function()
    create_client()
    IrcWindow:toggle_main()
end

M.message = function(message)
    if IrcClient == nil then
        print("Please call open before sending any messages")
        return
    end

    if message == nil then
        message = get_valid_text("Message to send: ")
    end

    if not message or not valid_text(message) then
        return
    end

    if type(message) ~= "string" then
        error("Please provide strings only")
        return
    end

    IrcClient:msg(message)
end

return M

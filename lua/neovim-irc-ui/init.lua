local TcpClient = require("neovim-irc-ui.tcp_client")
local Path = require("plenary.path")
local path_to_data = string.format("%s/%s", vim.fn.stdpath("data"), "theprimeagen-neovim-irc.json")

NeovimIrcData = NeovimIrcData or {}

NircWinId = NircWinId or nil
NircBufnr = NircBufnr or nil
NircClient = NircClient or nil

local M = {}

local function create_win_thanks_anttttt(options)
    local default_options = {
        relative = 'editor',
        style = 'minimal',
        width = 30,
        height = 15,
        row = 2,
        col = 2,
    }
    options = vim.tbl_extend('keep', options or {}, default_options)

    if not NircBufnr or not vim.api.nvim_buf_is_valid(NircBufnr) then
        NircBufnr = options.bufnr or vim.fn.nvim_create_buf(false, true)
    end

    if not NircWinId or not vim.api.nvim_buf_is_valid(NircWinId) then
        NircWinId = vim.fn.nvim_open_win(NircBufnr, true, options)
    end

    vim.api.nvim_win_set_buf(NircWinId, NircBufnr)
end


local function process_irc_msg(line)
    print("process_irc_msg", line)
end

local function refresh_data()
    local ok = pcall(function()
        NeovimIrcData = vim.fn.json_decode(Path:new(path_to_data):read())
    end)

    if not ok then
        NeovimIrcData = {}
    end
end

local punc = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
local alpha_numeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function move_cursor_to_end()
    if not vim.api.nvim_buf_is_valid(NircBufnr) or
       not vim.api.nvim_win_is_valid(NircWinId) then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(NircBufnr)
    vim.api.nvim_win_set_cursor(NircWinId, {line_count - 1, 0})
end

local function write_to_window(lines)
    if not vim.api.nvim_buf_is_valid(NircBufnr) then
        return
    end

    vim.api.nvim_buf_set_lines(NircBufnr, -1, -1, false, lines)
    move_cursor_to_end()
end

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

local function listen_to_client()
    NircClient:on("connect", function(err)
        if err ~= nil then
            print("ERROR", err)
            error("Unable to connect to theprimeagen's irc server.")
            M.disconnect()
            return
        end

        refresh_data()

        vim.schedule(function()
            create_win_thanks_anttttt()
            write_to_window({
                "",
                "",
                " Welcome to ThePrimeagen's IRC",
                "",
                "",
            })

            if NeovimIrcData.name == nil then
                NeovimIrcData.name = get_valid_text("IRC Name? ", true)
            end

            NircClient:join(NeovimIrcData.name)
        end)
    end)

    NircClient:on("data", function(line)
        -- Aggregate the irc chat
        process_irc_msg(line)
    end)

    NircClient:on("disconnect", M.on_tcp_close)
end

M.open_irc = function() if NircClient == nil then
    if NircClient == nil then
        NircClient = TcpClient:new("irc.theprimeagen.tv", 1337)
        listen_to_client()
    end
end

if NircClient:isConnected() and NircWinId == nil then
    create_win_thanks_anttttt()
    elseif not NircClient:isConnected() then
        NircClient:connect()
    end
end

M.close_irc_win = function()
    if NircWinId == nil then
        return
    end

    vim.api.nvim_win_close(NircWinId, true)
    NircWinId = nil
end

M.disconnect = function()
    M.close_irc_win()
    if NircClient == nil then
        return
    end
    NircClient:disconnect()
end

M.write = function()
    if not NircClient:isConnected() then
        error("You are not connected, please call M.open_irc")
    end

    local text = get_valid_text("Message to send: ")
    if not text then
        return
    end

    NircClient:msg(NeovimIrcData.name, text)
end

return M

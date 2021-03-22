
local IrcWindow = {
    _open_windows = {}
}

local function move_cursor_to_end(win_id, bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or
       not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(win_id, {line_count - 1, 0})
end

function IrcWindow:new(options)
    local obj = vim.tbl_extend('force', {
        toast_win_id = nil,
        toast_bufnr = nil,
        main_win_id = nil,
        main_bufnr = nil,
        main_height = 10,
        main_width = 30,
        main_row_offset = 0,
        main_col_offset = 0,
    }, options or {})

    setmetatable(obj, self)
    self.__index = self

    -- TODO: How to close?
    -- Little confused on some odd memory leak...
    table.insert(IrcWindow._open_windows, obj)

    return obj
end

function IrcWindow:_write_to_window(lines, bufnr, win_id, move_cursor)
end

function IrcWindow:write_to_main(lines)
    if not vim.api.nvim_buf_is_valid(self.main_bufnr) then
        return
    end

    vim.api.nvim_buf_set_lines(self.main_bufnr, -1, -1, false, lines)
    move_cursor_to_end(self.main_win_id, self.main_bufnr)
end

function IrcWindow:increment_toast()
    -- TODO: Toast?  Do we even want to do it right now?
    -- NO SCOTTY
end

function IrcWindow:toggle_toast()
    local is_open = vim.api.nvim_win_is_valid(self.toast_win_id)

    if is_open then
        vim.api.nvim_win_close(self.toast_win_id, true)
        self.toast_win_id = nil
        self.toast_bufnr = nil
    else
        local win_id, bufnr = self:_create_win({}, self.toast_win_id, self.toast_bufnr)
        self.toast_win_id = win_id
        self.toast_bufnr = bufnr
    end
end

function IrcWindow:open_main()
    if self.main_win_id and vim.api.nvim_win_is_valid(self.main_win_id) then
        return
    end

    local win_id, bufnr = self:_create_win({}, self.main_win_id, self.main_bufnr)
    self.main_win_id = win_id
    self.main_bufnr = bufnr
end

function IrcWindow:close_main()
    if self.main_win_id and vim.api.nvim_win_is_valid(self.main_win_id) then
        vim.api.nvim_win_close(self.main_win_id, true)
    end

    self.main_win_id = nil
    self.main_bufnr = nil
end

function IrcWindow:toggle_main()
    -- THANKS TJ
    local is_open = vim.api.nvim_win_is_valid(self.main_win_id or -69)
    if is_open then
        self:close_main()
    else
        self:open_main()
    end
end

-- was called _create_win_thanks_anttttt, RIP long lines
function IrcWindow:_create_win(options, win_id, bufnr)
    local default_options = {
        relative = 'editor',
        style = 'minimal',
        width = self.main_width,
        height = self.main_height,
        row = self.main_row_offset + 2,
        col = self.main_col_offset + 2,
    }

    options = vim.tbl_extend('keep', options or {}, default_options)

    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        -- annnnttttt THANKS FOR FN
        bufnr = options.bufnr or vim.api.nvim_create_buf(false, true)
    end

    if not win_id or not vim.api.nvim_win_is_valid(win_id) then
        -- annnnttttt THANKS FOR FN
        win_id = vim.api.nvim_open_win(bufnr, true, options)
    end

    vim.api.nvim_win_set_buf(win_id, bufnr)
    return win_id, bufnr
end

return IrcWindow

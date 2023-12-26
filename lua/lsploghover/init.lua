-- Not super sure how globals work/ why this is needed
local default_log_key = "[[LSPLOGHOVER]]"
Log_key = Log_key or default_log_key
Log_path = Log_path or require("vim.lsp.log").get_filename()
Max_win_height = Max_win_height or 20

local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end

    local content = file:read("*a")
    file:close()
    return content
end

-- Have the start command mark a start time, any logs timestamped after
-- that will be accepted, any before are filtered out
-- Clean the log statement up, take out time stamp info and such
local function process_logs(logs)
    if not logs then
        return nil
    end

    local file = io.open(Log_path, "r")
    if not file then
        return nil
    end

    local filtered_logs = {}
    for line in file:lines() do
        if string.find(line, Log_key, nil, true) then
            filtered_logs[#filtered_logs + 1] = line
            if #filtered_logs > Max_win_height then
                table.remove(filtered_logs, 1)
            end
        end
    end
    file:close()

    if next(filtered_logs) == nil then
        return nil
    end

    return filtered_logs
end

local function get_logs()
    local logs = read_file(Log_path)
    if logs == nil then
        return nil
    end

    local contents = process_logs(logs)
    if contents == nil then
        return nil
    end

    return contents
end

local function show_logs()
    local logs = get_logs()
    if logs == nil then
        return
    end

    local user_win = vim.api.nvim_get_current_win()
    local buf_handle = vim.api.nvim_create_buf(false, true)

    local width = vim.api.nvim_win_get_width(0)
    local opts = {
        relative = "editor",
        width = width,
        height = math.min(#logs, Max_win_height),
        row = 1,
        col = 1,
        style = "minimal",
        border = "rounded",
        title = "LspLogHover",
        title_pos = "center",
    }

    local win_handle = vim.api.nvim_open_win(buf_handle, true, opts)
    vim.api.nvim_set_current_win(win_handle)
    vim.api.nvim_put(logs, "l", true, true)
    vim.api.nvim_set_current_win(user_win)
end

local M = {}

M.setup = function(opts)
    if opts ~= nil then
        if opts.log_path == nil then
            Log_path = require("vim.lsp.log").get_filename()
        else
            Log_path = opts.log_path
        end

        if opts.log_key ~= nil then
            Log_key = opts.log_key
        else
            Log_key = default_log_key
        end

        if opts.max_win_height ~= nil then
            Max_win_height = 20
        end
    end
end

M.start = function(log_key)
    if log_key ~= nil then
        Log_key = log_key
    end

    show_logs()
end

M.change_log_key = function(log_key)
    if log_key ~= nil then
        Log_key = log_key
    end
end

return M

-- Not super sure how globals work/ why this is needed
local default_log_key = "<<LSPLOGHOVER>>"
Log_key = Log_key or default_log_key
Log_path = Log_path or require("vim.lsp.log").get_filename()
Max_win_height = Max_win_height or 20
Start_time = Start_time or nil

-- delete any and all characters up through the Log key
local function clean_log(log)
    local match_str = ".+" .. Log_key
    return string.gsub(log, match_str, "")
end

local function extract_timestamp(log)
    local match_str = "%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d"
    local start_idx, end_idx = string.find(log, match_str)
    if (not start_idx) or (not end_idx) then
        return nil
    end

    local date_str = string.sub(log, start_idx, end_idx)
    local year = string.sub(date_str, 1, 4)
    local month = string.sub(date_str, 6, 7)
    local day = string.sub(date_str, 9, 10)
    local hour = string.sub(date_str, 12, 13)
    local min = string.sub(date_str, 15, 16)
    local sec = string.sub(date_str, 18, 19)

    local time_stamp = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min =
            tonumber(min),
        sec = tonumber(sec)
    }

    return time_stamp
end

local function log_after_start(log)
    if not log then
        return false
    end

    -- If no starting time was marked, allow all logs through
    if not Start_time then
        return true
    end

    -- Get the timestamp out of the log as a table
    local timestamp = extract_timestamp(log)

    -- Check if it was before or after the starting time
    if os.time(timestamp) >= Start_time then
        return true
    else
        return false
    end
end

local function get_processed_logs()
    local file = io.open(Log_path, "r")
    if not file then
        return nil
    end

    local filtered_logs = {}
    for line in file:lines() do
        if log_after_start(line) then
            if string.find(line, Log_key, nil, true) then
                filtered_logs[#filtered_logs + 1] = clean_log(line)
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
    local contents = get_processed_logs()
    if contents == nil then
        return nil
    end

    return contents
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
    Start_time = nil
end

M.show_logs = function()
    local logs = get_logs()
    if logs == nil then
        return
    end

    local max_width = 0
    for _, log in ipairs(logs) do
        max_width = math.max(max_width, #log)
    end

    local user_win = vim.api.nvim_get_current_win()
    local buf_handle = vim.api.nvim_create_buf(false, true)

    -- TODO: Figure out how to get the window to wrap text without using deprecated API
    -- TODO: Look into making window "more temp", so it goes away on a cursor movement
    local win_width = vim.api.nvim_win_get_width(0)
    local opts = {
        relative = "editor",
        width = math.min(max_width, win_width),
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

M.start = function(log_key)
    if log_key ~= nil then
        Log_key = log_key
    end

    Start_time = os.time()
end

M.change_log_key = function(log_key)
    if log_key ~= nil then
        Log_key = log_key
    end
end

M.set_log_path = function(log_path)
    if log_path ~= nil then
        Log_path = log_path
    else
        Log_path = require("vim.lsp.log").get_filename()
    end
end

return M

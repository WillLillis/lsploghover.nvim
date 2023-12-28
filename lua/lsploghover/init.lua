-- Not super sure how globals work/ why this is needed
local default_log_key = "LSPLOGHOVER"
Log_key = Log_key or default_log_key
Log_path = Log_path or require("vim.lsp.log").get_filename()
Max_win_height = Max_win_height or 20
Start_time = Start_time or nil

-- Extract the relevant part from the log
local function clean_log(log)
    local cleaned_logs = {}
    local match_str = Log_key .. "%b<>"
    local start_idx, end_idx = string.find(log, match_str)
    -- Sometimes multiple logs get flushed together, take care of that here
    while start_idx and end_idx do
        local captured = string.sub(log, start_idx, end_idx) -- sub string we captured
        captured = string.gsub(captured, Log_key .. "<", "") -- strip off marking from start
        captured = string.sub(captured, 1, #captured - 1)    -- strip off marking from end
        cleaned_logs[#cleaned_logs + 1] = captured
        start_idx, end_idx = string.find(log, match_str, end_idx)
    end

    return cleaned_logs
end

local function extract_timestamp(log)
    -- yyyy-mm-dd hh:mm:ss
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

    -- I don't understand why, but without an empty string, text wrapping
    -- *doesn't* happen in the hover window when there's a single log
    local filtered_logs = { "" }
    for line in file:lines() do
        if log_after_start(line) then
            if string.find(line, Log_key, nil, true) then
                local cleaned_logs = clean_log(line)
                for _, cleaned in ipairs(cleaned_logs) do
                    filtered_logs[#filtered_logs + 1] = cleaned
                end
            end
        end
    end

    file:close()

    -- If it just has the placeholder empty string, it's really empty
    if #filtered_logs == 1 then
        return nil
    end

    return filtered_logs
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

-- Show marked logs in a hover window, if there are any
-- If Start_time is set, only logs that came after will be shown
-- If Start_time isn't set, all marked logs will be shown
M.show_logs = function()
    local logs = get_processed_logs()
    if logs == nil then
        return
    end

    local max_width = 0
    for _, log in ipairs(logs) do
        max_width = math.max(max_width, #log)
    end

    local user_win = vim.api.nvim_get_current_win()
    local buf_handle = vim.api.nvim_create_buf(false, true)

    -- TODO: Look into making window "more temp", so it goes away on a cursor movement
    local win_width = vim.api.nvim_win_get_width(0)
    local width = math.min(max_width, win_width)
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

    vim.api.nvim_set_option_value("wrap", true, { win = win_handle })
    vim.api.nvim_set_current_win(win_handle)
    vim.api.nvim_put(logs, "l", true, true)
    vim.api.nvim_set_current_win(user_win)
end

-- Mark a start time to filter logs by
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

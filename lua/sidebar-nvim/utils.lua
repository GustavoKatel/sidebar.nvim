local M = {}
local api = vim.api
local luv = vim.loop

local logger = require("sidebar-nvim.logger")

local function get_builtin_section(name)
    local ret, section = pcall(require, "sidebar-nvim.builtin." .. name)
    if not ret then
        logger:warn("error trying to load section: " .. name)
        return nil
    end

    return section:new()
end

function M.resolve_section(section)
    if type(section) == "string" then
        return get_builtin_section(section)
    elseif type(section) == "table" then
        return section
    end

    error("could not resolve section")
end

function M.is_instance(o, class)
    while o do
        o = getmetatable(o)
        if class == o then
            return true
        end
    end
    return false
end

-- Reference: https://github.com/hoob3rt/lualine.nvim/blob/master/lua/lualine/components/filename.lua#L9

local function count(base, pattern)
    return select(2, string.gsub(base, pattern, ""))
end

function M.shorten_path(path, min_len)
    if #path <= min_len then
        return path
    end

    local sep = package.config:sub(1, 1)

    for _ = 0, count(path, sep) do
        if #path <= min_len then
            return path
        end

        -- ('([^/])[^/]+%/', '%1/', 1)
        path = path:gsub(string.format("([^%s])[^%s]+%%%s", sep, sep, sep), "%1" .. sep, 1)
    end

    return path
end

function M.shortest_path(path)
    local sep = package.config:sub(1, 1)

    for _ = 0, count(path, sep) do
        -- ('([^/])[^/]+%/', '%1/', 1)
        path = path:gsub(string.format("([^%s])[^%s]+%%%s", sep, sep, sep), "%1" .. sep, 1)
    end

    return path
end

function M.filename(path)
    local split = vim.split(path, "/")
    return split[#split]
end

function M.file_exist(path)
    local _, err = luv.fs_stat(path)
    return err == nil
end

function M.truncate(s, size)
    local length = #s

    if length <= size then
        return s
    else
        return s:sub(1, size) .. ".."
    end
end

-- @param opts table
-- @param opts.modified boolean filter buffers by modified or not
function M.get_existing_buffers(opts)
    return vim.tbl_filter(function(buf)
        local modified_filter = true
        if opts and opts.modified ~= nil then
            local is_ok, is_modified = pcall(api.nvim_buf_get_option, buf, "modified")

            if is_ok then
                modified_filter = is_modified == opts.modified
            end
        end

        return api.nvim_buf_is_valid(buf) and vim.fn.buflisted(buf) == 1 and modified_filter
    end, api.nvim_list_bufs())
end

return M

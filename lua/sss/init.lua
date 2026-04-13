---@class SimpleStartScreenOpts
---@field arts string[][]
---@field vim_b_opts table<string, any>?

---@class SimpleStartScreen
---@field opts SimpleStartScreenOpts
---@field buffer integer
---@field width integer
---@field height integer
---@field lines string[]
---@field init_buf fun(SimpleStartScreen)
---@field apply_buf_options fun(SimpleStartScreen)
---@field init_art fun(SimpleStartScreen)
---@field render fun(SimpleStartScreen)

local SimpleStartScreen = {}
SimpleStartScreen.__index = SimpleStartScreen

function SimpleStartScreen.new(opts)
    ---@type SimpleStartScreen
    local self = setmetatable({}, SimpleStartScreen)
    self.opts = opts
    self:init_buf()
    self:apply_buf_options()
    self:init_art()
    return self
end

function SimpleStartScreen:init_buf()
    self.buffer = vim.api.nvim_get_current_buf()
    if self.buffer == nil or not vim.api.nvim_buf_is_valid(self.buffer) then
        self.buffer = vim.api.nvim_create_buf(false, true)
    end

end

function SimpleStartScreen:apply_buf_options()
    vim.cmd("noautocmd silent! set filetype=simplestartscreen")

    local options = {
        -- Taken from 'vim-startify'
        'bufhidden=wipe',
        'colorcolumn=',
        'foldcolumn=0',
        'matchpairs=',
        'nobuflisted',
        'nocursorcolumn',
        'nocursorline',
        'nolist',
        'nonumber',
        'noreadonly',
        'norelativenumber',
        'nospell',
        'noswapfile',
        'signcolumn=no',
        'statuscolumn=',
        'synmaxcol&',
        -- Taken from 'mini.starter'
        'buftype=nofile',
        'nomodeline',
        'nomodifiable',
        'foldlevel=999',
        'nowrap',
    }

    -- Vim's `setlocal` is currently more robust compared to `opt_local`
    vim.cmd(('silent! noautocmd setlocal %s'):format(table.concat(options, ' ')))

    -- Hide tabline on single tab by setting `showtabline` to default value (but
    -- not statusline as it weirdly feels 'naked' without it).
    vim.o.showtabline = 1

    if self.opts.vim_b_opts ~= nil then
        for k, v in pairs(self.opts.vim_b_opts) do
            vim.b[k] = v
        end
    end
end

function SimpleStartScreen:init_art()
    math.randomseed(os.time())
    self.lines = self.opts.arts[math.random(#self.opts.arts)]
    local width = 0
    for _, line in ipairs(self.lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    self.width = width
    self.height = #self.lines
end

function SimpleStartScreen:render()
    local usable_width = vim.o.columns
    local usable_height = vim.o.lines - 1

    if usable_width < self.width or usable_height < self.height then
        return
    end

    local top_padding = math.floor((usable_height - self.height) / 2)
    local left_padding = math.floor((usable_width - self.width) / 2)

    local centered_lines = {}

    for _ = 1, top_padding do
        table.insert(centered_lines, "")
    end

    local left_fill = (" "):rep(left_padding)
    for _, line in ipairs(self.lines) do
        table.insert(centered_lines, left_fill .. line)
    end

    vim.bo[self.buffer].modifiable = true
    vim.api.nvim_buf_set_lines(self.buffer, 0, -1, false, centered_lines)
    vim.bo[self.buffer].modifiable = false
end

local M = {}

---@type SimpleStartScreenOpts
M.config = {
    arts = require("sss.arts"),
    vim_b_opts = {
        ministatusline_disable = true,
        miniindentscope_disable = true,
    }
}

---@param opts SimpleStartScreenOpts?
function M.setup(opts)

    opts = vim.tbl_deep_extend("force", M.config, opts or {})
    local sss = SimpleStartScreen.new(opts)

    vim.api.nvim_create_autocmd({ "VimEnter", "VimResized" }, {
        desc = "Simple Start Screen",
        callback = function()
            if vim.fn.argc() > 0 then return end
            sss:render()
        end
    })
end

return M

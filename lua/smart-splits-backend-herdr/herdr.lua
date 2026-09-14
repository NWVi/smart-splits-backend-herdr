---@module 'smart-splits.backend'

---@class HerdrBackend.Focus
---@field changed boolean|nil
---@field reason string|nil

---@class HerdrBackend.Area
---@field width number|nil
---@field height number|nil

---@class HerdrBackend.Layout
---@field area HerdrBackend.Area|nil

local M = {}

-- Keeps a hung herdr from blocking a keypress.
local TIMEOUT_MS = 500

---@return string
function M.bin()
  local path = vim.env.HERDR_BIN_PATH
  return (path ~= nil and path ~= '') and path or 'herdr'
end

---@return boolean
function M.in_session()
  return vim.env.HERDR_ENV ~= nil and vim.env.HERDR_ENV ~= ''
end

---@return boolean
function M.exists()
  return vim.fn.executable(M.bin()) == 1
end

---Run a herdr command and return the decoded `result` field.
---@param args string[]
---@return table|nil result nil on a failed, empty or malformed response
function M.exec(args)
  local cmd = vim.list_extend({ M.bin() }, args)
  local ok, output = pcall(function()
    return vim.system(cmd, { text = true, timeout = TIMEOUT_MS }):wait()
  end)
  if not ok or type(output) ~= 'table' or output.code ~= 0 or not output.stdout or output.stdout == '' then
    return nil
  end

  local decoded_ok, decoded = pcall(vim.json.decode, output.stdout, { luanil = { object = true, array = true } })
  if not decoded_ok or type(decoded) ~= 'table' or type(decoded.result) ~= 'table' then
    return nil
  end
  return decoded.result
end

---@param direction SmartSplitsDirection
---@return HerdrBackend.Focus|nil
function M.focus(direction)
  local result = M.exec({ 'pane', 'focus', '--direction', direction, '--current' })
  return result and type(result.focus) == 'table' and result.focus or nil
end

---@return HerdrBackend.Layout|nil
function M.layout()
  local result = M.exec({ 'pane', 'layout', '--current' })
  return result and type(result.layout) == 'table' and result.layout or nil
end

---@param direction SmartSplitsDirection
---@param ratio number split-ratio delta, not cells
---@return boolean changed
function M.resize(direction, ratio)
  local result = M.exec({
    'pane',
    'resize',
    '--direction',
    direction,
    '--amount',
    string.format('%.4f', ratio),
    '--current',
  })
  return result ~= nil and type(result.resize) == 'table' and result.resize.changed == true
end

---Split the current pane and focus the new one.
---@param direction 'right'|'down'
---@return boolean
function M.split(direction)
  local result = M.exec({ 'pane', 'split', '--direction', direction, '--current', '--focus' })
  return result ~= nil and type(result.pane) == 'table' and result.pane.pane_id ~= nil
end

---@param direction SmartSplitsDirection
---@return boolean
function M.swap(direction)
  local result = M.exec({ 'pane', 'swap', '--direction', direction, '--current' })
  return result ~= nil and result.swap ~= nil
end

return M

---@module 'smart-splits.backend'

local config = require('smart-splits-backend-herdr.config')
local herdr = require('smart-splits-backend-herdr.herdr')

local M = {}

-- herdr only splits right or down; left and up swap the new pane into place.
---@type table<SmartSplitsDirection, { split: 'right'|'down', swap?: SmartSplitsDirection }>
local splits = {
  left = { split = 'right', swap = 'right' },
  right = { split = 'right' },
  up = { split = 'down', swap = 'down' },
  down = { split = 'down' },
}

---@param direction SmartSplitsDirection
---@return boolean
local function split(direction)
  local spec = splits[direction]
  if spec == nil or not herdr.split(spec.split) then
    return false
  end
  return spec.swap == nil or herdr.swap(spec.swap)
end

---@param direction SmartSplitsDirection
---@param opts? SmartSplitsBackendMoveOpts
---@return boolean
function M.move(direction, opts)
  opts = opts or {}
  if not config.options.enable or not herdr.in_session() then
    return false
  end

  local focus = herdr.focus(direction)
  if focus == nil then
    return false
  end
  if focus.changed == true then
    return true
  end

  -- herdr never wraps, so 'wrap' falls through to core.
  if opts.at_edge == 'split' then
    return split(direction)
  end
  return false
end

return M

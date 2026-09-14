---@module 'smart-splits.backend'

local config = require('smart-splits-backend-herdr.config')
local herdr = require('smart-splits-backend-herdr.herdr')

local M = {}

-- Split-ratio delta used when no cell count can be converted.
local DEFAULT_RATIO = 0.02

-- `herdr pane resize --amount` takes a split-ratio delta, so cells are divided by the tab size.
---@param direction SmartSplitsDirection
---@param cells number
---@return number|nil
local function cells_to_ratio(direction, cells)
  local layout = herdr.layout()
  local area = layout and layout.area
  if area == nil then
    return nil
  end

  local size = (direction == 'left' or direction == 'right') and area.width or area.height
  if type(size) ~= 'number' or size <= 0 then
    return nil
  end
  return cells / size
end

---@param direction SmartSplitsDirection
---@param opts? SmartSplitsBackendResizeOpts
---@return boolean
function M.resize(direction, opts)
  opts = opts or {}
  if not config.options.enable or not herdr.in_session() then
    return false
  end

  local ratio = opts.amount and cells_to_ratio(direction, opts.amount) or DEFAULT_RATIO
  return herdr.resize(direction, ratio)
end

return M

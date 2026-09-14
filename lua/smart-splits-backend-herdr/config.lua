---@class HerdrBackend.Config
---@field enable boolean

---@alias HerdrBackend.PartialConfig { enable?: boolean }

local M = {}

---@type HerdrBackend.Config
M.defaults = {
  enable = true,
}

---@type HerdrBackend.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? HerdrBackend.PartialConfig
---@return HerdrBackend.Config
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend('force', M.defaults, opts)
  return M.options
end

return M

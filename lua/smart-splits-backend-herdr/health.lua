local config = require('smart-splits-backend-herdr.config')
local herdr = require('smart-splits-backend-herdr.herdr')

local M = {}

function M.report()
  if not config.options.enable then
    vim.health.info('Disabled by config (`enable = false`)')
  end

  local bin = herdr.bin()
  if herdr.exists() then
    vim.health.ok(('herdr is executable: `%s`'):format(bin))
  else
    vim.health.error(('herdr is not executable: `%s`'):format(bin), 'Install herdr or set HERDR_BIN_PATH')
  end

  if herdr.in_session() then
    vim.health.ok('Running inside herdr (HERDR_ENV is set)')
  else
    vim.health.warn('Not running inside herdr (HERDR_ENV is unset)')
  end

  if vim.fn.executable('jq') == 1 then
    vim.health.ok('jq is executable, the herdr plugin scripts can detect Vim')
  else
    vim.health.warn('jq is not executable, the herdr plugin scripts cannot detect Vim')
  end
end

---@return nil
function M.check()
  vim.health.start('smart-splits-backend-herdr')
  M.report()
end

return M

---@module 'smart-splits.backend'

local config = require('smart-splits-backend-herdr.config')
local health = require('smart-splits-backend-herdr.health')
local herdr = require('smart-splits-backend-herdr.herdr')
local move = require('smart-splits-backend-herdr.move')
local resize = require('smart-splits-backend-herdr.resize')

---@type SmartSplitsBackend
local M = {
  name = 'smart-splits-backend-herdr',
  protocol_version = '3.0.0',
  setup = function(opts)
    config.setup(opts)
  end,
  detect = function()
    return config.options.enable and herdr.in_session() and herdr.exists()
  end,
  move = move.move,
  resize = resize.resize,
  health = health.report,
}

return M

local h = require('tests.helpers')

local layout = { layout = { area = { width = 300, height = 100 } } }
local changed = { resize = { changed = true } }

describe('resize()', function()
  before_each(function()
    h.reset_backend()
    h.enter_session()
  end)

  after_each(function()
    h.reset_backend()
  end)

  it('converts cells to a ratio of the tab width', function()
    local backend = require('smart-splits-backend-herdr')
    local calls = h.stub_system({ layout = layout, resize = changed })
    assert.is_true(backend.resize('left', { amount = 3 }))
    assert.same({ 'herdr', 'pane', 'layout', '--current' }, calls[1])
    assert.same({ 'herdr', 'pane', 'resize', '--direction', 'left', '--amount', '0.0100', '--current' }, calls[2])
  end)

  it('converts cells to a ratio of the tab height', function()
    local backend = require('smart-splits-backend-herdr')
    local calls = h.stub_system({ layout = layout, resize = changed })
    assert.is_true(backend.resize('down', { amount = 5 }))
    assert.same({ 'herdr', 'pane', 'resize', '--direction', 'down', '--amount', '0.0500', '--current' }, calls[2])
  end)

  it('falls back to a default ratio without layout data', function()
    local backend = require('smart-splits-backend-herdr')
    local calls = h.stub_system({ resize = changed })
    assert.is_true(backend.resize('left', { amount = 3 }))
    assert.same({ 'herdr', 'pane', 'resize', '--direction', 'left', '--amount', '0.0200', '--current' }, calls[2])
  end)

  it('uses the default ratio without querying layout when amount is absent', function()
    local backend = require('smart-splits-backend-herdr')
    local calls = h.stub_system({ layout = layout, resize = changed })
    assert.is_true(backend.resize('right'))
    assert.same({ { 'herdr', 'pane', 'resize', '--direction', 'right', '--amount', '0.0200', '--current' } }, calls)
  end)

  it('returns false when nothing changed', function()
    local backend = require('smart-splits-backend-herdr')
    h.stub_system({ layout = layout, resize = { resize = { changed = false } } })
    assert.is_false(backend.resize('right', { amount = 3 }))
  end)

  it('uses HERDR_BIN_PATH when set', function()
    local backend = require('smart-splits-backend-herdr')
    vim.env.HERDR_BIN_PATH = '/custom/bin/herdr'
    local calls = h.stub_system({ resize = changed })
    assert.is_true(backend.resize('right'))
    assert.are.equal('/custom/bin/herdr', calls[1][1])
  end)

  it('returns false without running herdr outside herdr', function()
    local backend = require('smart-splits-backend-herdr')
    vim.env.HERDR_ENV = nil
    local calls = h.stub_system({ resize = changed })
    assert.is_false(backend.resize('right', { amount = 3 }))
    assert.are.equal(0, #calls)
  end)
end)

local h = require('tests.helpers')

---@param backend SmartSplitsBackend
local function assert_conforms(backend)
  local protocol_tests = require('smart-splits.protocol_tests')
  for _, test in ipairs(protocol_tests.tests(backend)) do
    local result = test.fn()
    assert.is_true(result, test.name .. ': ' .. tostring(result))
  end
end

describe('backend protocol conformance', function()
  before_each(function()
    h.reset_backend()
  end)

  after_each(function()
    h.reset_backend()
  end)

  it('implements the v3 backend protocol outside herdr without running herdr', function()
    local backend = require('smart-splits-backend-herdr')
    local calls = h.stub_system({})
    assert_conforms(backend)
    assert.are.equal(0, #calls)
  end)

  it('implements the v3 backend protocol inside herdr', function()
    local backend = require('smart-splits-backend-herdr')
    h.enter_session()
    h.stub_executable(true)
    h.stub_system({
      focus = { focus = { changed = true } },
      layout = { layout = { area = { width = 200, height = 50 } } },
      resize = { resize = { changed = true } },
    })
    assert_conforms(backend)
  end)
end)

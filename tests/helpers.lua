local M = {}

local original_system = vim.system
local original_executable = vim.fn.executable

-- Isolates each test from any real herdr session running the suite.
function M.reset_backend()
  vim.env.HERDR_ENV = nil
  vim.env.HERDR_BIN_PATH = nil
  vim.system = original_system
  vim.fn.executable = original_executable
  require('smart-splits-backend-herdr.config').setup()
end

function M.enter_session()
  vim.env.HERDR_ENV = '1'
end

---@param executable boolean
function M.stub_executable(executable)
  vim.fn.executable = function(_) ---@diagnostic disable-line: duplicate-set-field
    return executable and 1 or 0
  end
end

---Stub `vim.system`, answering `herdr pane <subcommand>` from `responses`.
---A table is sent as the `result` field, a string as raw stdout, `false` as a non-zero exit,
---and a missing subcommand as empty stdout.
---@param responses table<string, table|string|false>
---@return string[][] calls every command run, in order
function M.stub_system(responses)
  local calls = {}
  vim.system = function(cmd) ---@diagnostic disable-line: duplicate-set-field
    table.insert(calls, vim.deepcopy(cmd))
    local response = responses[cmd[3]]
    local output
    if response == false then
      output = { code = 1, stdout = '', stderr = 'error' }
    elseif type(response) == 'string' then
      output = { code = 0, stdout = response, stderr = '' }
    elseif type(response) == 'table' then
      output = { code = 0, stdout = vim.json.encode({ ok = true, result = response }), stderr = '' }
    else
      output = { code = 0, stdout = '', stderr = '' }
    end
    return {
      wait = function()
        return output
      end,
    }
  end
  return calls
end

return M

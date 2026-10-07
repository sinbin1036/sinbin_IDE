-- Debug keymaps (TASK-014). nvim-dap, nvim-dap-view and the adapter settings
-- (plugins/debug_config.lua) load on the first of these keys, not at startup (TASK-023:
-- about 40ms of the startup time). vim.pack.add skips their packadd (plugins/init.lua).

local M = {}

local config
--- Loads the debugger once.
--- @return table debug_config module
function M.load()
  if not config then
    vim.cmd.packadd("nvim-dap")
    vim.cmd.packadd("nvim-dap-view")
    config = require("sinbin.plugins.debug_config")
  end
  return config
end

--- A key action that loads the debugger first: `fn(dap)`.
local function with_dap(fn)
  return function()
    M.load()
    fn(require("dap"))
  end
end

local map = vim.keymap.set
local function start_or_continue() M.load().start_or_continue() end

map("n", "<Leader>db", with_dap(function(dap) dap.toggle_breakpoint() end), { desc = "Toggle breakpoint" })
map("n", "<Leader>dB", with_dap(function(dap)
  dap.set_breakpoint(vim.fn.input("조건: "))
end), { desc = "Conditional breakpoint" })
map("n", "<Leader>dc", start_or_continue, { desc = "Start / continue" })
map("n", "<Leader>dn", with_dap(function(dap) dap.step_over() end), { desc = "Step over" })
map("n", "<Leader>di", with_dap(function(dap) dap.step_into() end), { desc = "Step into" })
map("n", "<Leader>do", with_dap(function(dap) dap.step_out() end), { desc = "Step out" })
map("n", "<Leader>dq", with_dap(function(dap) dap.terminate() end), { desc = "Terminate" })
-- Hidden -> open, visible elsewhere -> focus, focused -> close (TASK-016).
map("n", "<Leader>du", function()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[win].dapview_win and win ~= vim.api.nvim_get_current_win() then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  M.load()
  require("dap-view").toggle()
end, { desc = "Debug panel" })
map({ "n", "x" }, "<Leader>de", function()
  M.load()
  require("dap-view").hover()
end, { desc = "Evaluate expression" })
-- VS Code style function keys.
map("n", "<F5>", start_or_continue, { desc = "Debug: start / continue" })
map("n", "<F10>", with_dap(function(dap) dap.step_over() end), { desc = "Debug: step over" })
map("n", "<F11>", with_dap(function(dap) dap.step_into() end), { desc = "Debug: step into" })
map("n", "<F12>", with_dap(function(dap) dap.step_out() end), { desc = "Debug: step out" })

return M

-- Korean IME Han/Eng state by window (TASK-017): entering a code window turns a Korean
-- IME state into English (Normal mode commands need English), nothing when already
-- English. Agent / terminal windows are left alone, so Korean can be typed there freely.
-- Runs only on window / buffer changes (no polling) and only while Neovim has focus.
-- The OS side is the Platform Layer's `ime` (Windows only; no-op elsewhere).

local ime = require("sinbin.platform").ime
local settings = require("sinbin.settings")
if not ime then
  return
end

--- Whether the terminal running Neovim has focus (FocusGained / FocusLost). Assumed at
--- startup; without it a window change made by a timer while another application is in
--- front would switch that application's IME (the helper also checks the foreground
--- process).
local focused = true

--- A terminal UI (`nvim` in a terminal), not an embedding client: test harnesses and
--- GUIs must not switch the IME of whatever terminal is in front.
local function in_terminal_ui()
  for _, ui in ipairs(vim.api.nvim_list_uis()) do
    if ui.stdout_tty then
      return true
    end
  end
  return false
end

local function in_code_window()
  local win = vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_config(win).relative == "" and vim.bo.buftype == ""
end

local pending = false
local group = vim.api.nvim_create_augroup("sinbin_ime", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = group,
  desc = "Korean IME to English in code windows",
  callback = function()
    -- WinEnter and BufEnter come together: one check after both.
    if pending then
      return
    end
    pending = true
    vim.schedule(function()
      pending = false
      if focused and settings.get("ime") and in_code_window() and in_terminal_ui() then
        ime.to_english()
      end
    end)
  end,
})
vim.api.nvim_create_autocmd("FocusGained", { group = group, desc = "IME: focus", callback = function() focused = true end })
vim.api.nvim_create_autocmd("FocusLost", { group = group, desc = "IME: focus", callback = function() focused = false end })

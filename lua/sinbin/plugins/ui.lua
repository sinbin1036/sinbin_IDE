-- UI plugins (TASK-006): colorscheme, icons, statusline, key clues,
-- notifications, start screen. Tab bar (TASK-016).

-- Soft neon dark, not pitch black (user choice). Style and transparency are settings
-- (TASK-019).
require("sinbin.settings").apply_theme()

-- Requires a Nerd Font in the terminal for glyphs.
require("mini.icons").setup()
-- bufferline and aerial look for nvim-web-devicons; mini.icons answers for it.
MiniIcons.mock_nvim_web_devicons()

-- One statusline for the whole screen ('laststatus' = 3 in options.lua), content in
-- sinbin/statusline.lua.
local statusline = require("sinbin.statusline")
require("mini.statusline").setup({ content = { active = statusline.active } })

-- Tab bar (TASK-016): open files (listed buffers) at the top, shared by all windows.
local function close_buffer(buf) require("sinbin.layout").close_buffer(buf) end
require("bufferline").setup({
  options = {
    -- Closing a tab keeps the window layout (built-in :bdelete closes the window too).
    close_command = close_buffer,
    middle_mouse_command = close_buffer,
    right_mouse_command = nil,
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(_, _, diag)
      local parts = {}
      if diag.error then
        parts[#parts + 1] = "\u{f057} " .. diag.error
      end
      if diag.warning then
        parts[#parts + 1] = "\u{f071} " .. diag.warning
      end
      return table.concat(parts, " ")
    end,
    show_close_icon = false,
    -- No tab for directory buffers (`nvim .` shows the folder in mini.files), nor for
    -- the empty [No Name] buffer of a new code window (TASK-022): it gets a tab once
    -- something is typed in it.
    custom_filter = function(buf)
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then
        return vim.bo[buf].modified
          or vim.api.nvim_buf_line_count(buf) > 1
          or vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] ~= ""
      end
      return vim.fn.isdirectory(name) == 0
    end,
    always_show_bufferline = true,
    -- Tabs start right of the Outline sidebar.
    offsets = { { filetype = "aerial", text = "Outline", text_align = "left", separator = true } },
  },
})

-- Tab keymaps. ]b / [b replace the built-in :bnext / :bprevious to follow the tab order.
local map = vim.keymap.set
map("n", "]b", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
map("n", "[b", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Previous tab" })
map("n", "<Leader>bd", function() close_buffer(0) end, { desc = "Close tab" })
map("n", "<Leader>bo", function() require("bufferline").close_others() end, { desc = "Close other tabs" })
map("n", "<Leader>bp", "<Cmd>BufferLinePick<CR>", { desc = "Pick tab" })
map("n", "<Leader>bP", "<Cmd>BufferLineTogglePin<CR>", { desc = "Pin / unpin tab" })
map("n", "<Leader>b]", "<Cmd>BufferLineMoveNext<CR>", { desc = "Move tab right" })
map("n", "<Leader>b[", "<Cmd>BufferLineMovePrev<CR>", { desc = "Move tab left" })

-- Replaces vim.notify with a floating notification window.
-- LSP progress messages are hidden (user choice): too noisy, especially jdtls.
require("mini.notify").setup({ lsp_progress = { enable = false } })

-- Start screen layout (TASK-018).
require("sinbin.starter").setup()

local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = { "n", "x" }, keys = "<Leader>" },
    { mode = "n", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "i", keys = "<C-x>" },
    { mode = { "n", "x" }, keys = "g" },
    { mode = { "n", "x" }, keys = "'" },
    { mode = { "n", "x" }, keys = "`" },
    { mode = { "n", "x" }, keys = '"' },
    { mode = { "i", "c" }, keys = "<C-r>" },
    { mode = "n", keys = "<C-w>" },
    { mode = { "n", "x" }, keys = "z" },
  },
  clues = {
    -- Leader groups from docs/PROJECT.md "Keymap 방향".
    { mode = "n", keys = "<Leader>f", desc = "+File" },
    { mode = "n", keys = "<Leader>s", desc = "+Search" },
    { mode = "n", keys = "<Leader>b", desc = "+Buffer/Tab" },
    { mode = { "n", "x" }, keys = "<Leader>c", desc = "+Code" },
    { mode = "n", keys = "<Leader>e", desc = "+Error/Diagnostic" },
    { mode = { "n", "x" }, keys = "<Leader>g", desc = "+Git" },
    { mode = "n", keys = "<Leader>t", desc = "+Terminal" },
    { mode = "n", keys = "<Leader>r", desc = "+Run" },
    { mode = "n", keys = "<Leader>x", desc = "+Test" },
    { mode = { "n", "x" }, keys = "<Leader>d", desc = "+Debug" },
    { mode = { "n", "x" }, keys = "<Leader>a", desc = "+AI Agent" },
    miniclue.gen_clues.square_brackets(),
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
})

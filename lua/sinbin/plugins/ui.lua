-- UI plugins (TASK-006): colorscheme, icons, statusline, key clues,
-- notifications, start screen.

-- Soft neon dark, not pitch black (user choice).
require("tokyonight").setup({ style = "moon" })
vim.cmd.colorscheme("tokyonight")

-- Requires a Nerd Font in the terminal for glyphs.
require("mini.icons").setup()

require("mini.statusline").setup()

-- Replaces vim.notify with a floating notification window.
require("mini.notify").setup()

require("mini.starter").setup()

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
    miniclue.gen_clues.square_brackets(),
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
})

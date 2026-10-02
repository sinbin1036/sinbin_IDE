-- Editing plugins (TASK-005, D-008): mini.pairs, mini.surround.

require("mini.pairs").setup()

-- tpope/vim-surround style keys (:h MiniSurround-vim-surround-config).
-- Keeps the built-in `s` key untouched.
require("mini.surround").setup({
  mappings = {
    add = "ys",
    delete = "ds",
    find = "",
    find_left = "",
    highlight = "",
    replace = "cs",
    suffix_last = "",
    suffix_next = "",
  },
  search_method = "cover_or_next",
})
vim.keymap.del("x", "ys")
vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true, desc = "Add surrounding" })
vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Add surrounding to line" })

-- Search / Navigation plugins (TASK-006): mini.pick, mini.extra, mini.files.
-- Keymaps follow the <Leader>f File / <Leader>s Search groups (docs/PROJECT.md).
-- Content search uses ripgrep (rg) when present.

local pick = require("mini.pick")
pick.setup()
require("mini.extra").setup()
require("mini.files").setup()

-- In the explorer, `g.` makes the directory under the cursor (or the file's directory)
-- the working directory. The explorer itself never changes it. (Not `gc`: that is the
-- built-in comment key and too close to <Leader>gc.)
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  group = vim.api.nvim_create_augroup("sinbin_minifiles", { clear = true }),
  desc = "mini.files: g. sets the working directory",
  callback = function(args)
    vim.keymap.set("n", "g.", function()
      local entry = MiniFiles.get_fs_entry()
      if not entry then
        return
      end
      local dir = entry.fs_type == "directory" and entry.path or vim.fs.dirname(entry.path)
      vim.fn.chdir(dir)
      vim.notify("작업 폴더: " .. vim.fs.normalize(dir), vim.log.levels.INFO)
    end, { buffer = args.data.buf_id, desc = "Set working directory" })
  end,
})

local map = vim.keymap.set

map("n", "<Leader>ff", pick.builtin.files, { desc = "Find files" })
map("n", "<Leader>fb", pick.builtin.buffers, { desc = "Buffers" })
map("n", "<Leader>fr", function() MiniExtra.pickers.oldfiles() end, { desc = "Recent files" })
map("n", "<Leader>fe", function()
  -- Toggle. Checks the state instead of close()'s result: close() returns false when
  -- the user keeps unsynced edits, which must not reopen the explorer.
  if MiniFiles.get_explorer_state() then
    MiniFiles.close()
    return
  end
  -- Open at the current file; fall back to cwd for unnamed/unsaved buffers.
  local path = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(vim.uv.fs_stat(path) and path or nil)
end, { desc = "File explorer (toggle)" })

map("n", "<Leader>sg", pick.builtin.grep_live, { desc = "Grep (live)" })
map("n", "<Leader>sw", function()
  pick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })
map("n", "<Leader>sh", pick.builtin.help, { desc = "Help tags" })
map("n", "<Leader>sr", pick.builtin.resume, { desc = "Resume last picker" })

-- Diagnostic pickers (TASK-009). Other <Leader>e keymaps are in sinbin/diagnostics.lua.
map("n", "<Leader>ed", function()
  MiniExtra.pickers.diagnostic({ scope = "current" })
end, { desc = "Diagnostics (buffer)" })
map("n", "<Leader>eD", function()
  MiniExtra.pickers.diagnostic({ scope = "all" })
end, { desc = "Diagnostics (all)" })

-- Terminal list (TASK-012): pick a live shell terminal to show.
map("n", "<Leader>tl", function()
  local terminal = require("sinbin.terminal")
  local items = {}
  for _, t in ipairs(terminal.list()) do
    items[#items + 1] = { text = t.name, bufnr = t.buf, id = t.id }
  end
  if #items == 0 then
    vim.notify("열린 terminal 없음", vim.log.levels.INFO)
    return
  end
  pick.start({
    source = {
      name = "Terminals",
      items = items,
      choose = function(item)
        -- Leave the picker window before opening a split.
        vim.schedule(function() terminal.show(item.id) end)
      end,
    },
  })
end, { desc = "Terminal list" })

-- Run/Test command list (TASK-013): [파일] / [프로젝트] commands of the current context.
map("n", "<Leader>rt", function()
  local run = require("sinbin.run")
  run.commands(function(items)
    pick.start({
      source = {
        name = "Run commands",
        items = items,
        choose = function(item)
          vim.schedule(function() run.run_item(item) end)
        end,
      },
    })
  end)
end, { desc = "Run command list" })

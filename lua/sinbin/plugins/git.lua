-- Git (TASK-011): gitsigns.nvim for changes inside the buffer, diffview for reviewing
-- all changed files and file history, mini.extra pickers for hunks/commits/branches.
-- Full Git UI is lazygit (sinbin.lazygit).

local gitsigns = require("gitsigns")

gitsigns.setup({
  -- Who changed the cursor line and when, dimmed at the end of the line.
  current_line_blame = require("sinbin.settings").get("blame"),
  on_attach = function(buf)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    local function range()
      return { vim.fn.line("."), vim.fn.line("v") }
    end

    map("n", "]h", function() gitsigns.nav_hunk("next") end, "Next hunk")
    map("n", "[h", function() gitsigns.nav_hunk("prev") end, "Previous hunk")
    map("n", "<Leader>gp", gitsigns.preview_hunk, "Preview hunk")
    -- On an already staged hunk this unstages it.
    map("n", "<Leader>gs", gitsigns.stage_hunk, "Stage hunk")
    map("x", "<Leader>gs", function() gitsigns.stage_hunk(range()) end, "Stage selected lines")
    map("n", "<Leader>gr", gitsigns.reset_hunk, "Reset hunk")
    map("x", "<Leader>gr", function() gitsigns.reset_hunk(range()) end, "Reset selected lines")
    map("n", "<Leader>gS", gitsigns.stage_buffer, "Stage file")
    map("n", "<Leader>gR", gitsigns.reset_buffer, "Reset file")
    map("n", "<Leader>gb", function() gitsigns.blame_line({ full = true }) end, "Blame line")
    map("n", "<Leader>gd", gitsigns.diffthis, "Diff file")
  end,
})

-- `q` closes diffview from any of its windows (no default close key).
local close = { "n", "q", "<Cmd>DiffviewClose<CR>", { desc = "Close diffview" } }
require("diffview").setup({
  keymaps = {
    view = { close },
    file_panel = { close },
    file_history_panel = { close },
  },
})

-- Check before opening diffview, which otherwise reports these cases with an English error.
local function notify(msg)
  vim.notify(msg, vim.log.levels.WARN)
end

--- @param need_history boolean require a file buffer with at least one commit
--- @return string? git root, or nil after notifying why diffview cannot open
local function git_root(need_history)
  local path = vim.api.nvim_buf_get_name(0)
  local is_file = vim.bo.buftype == "" and path ~= ""
  if need_history and not is_file then
    notify("파일 버퍼 아님")
    return
  end
  local root = vim.fs.root(is_file and path or vim.fn.getcwd(), ".git")
  if not root then
    notify("git 저장소 아님")
    return
  end
  if need_history then
    local log = vim.system({ "git", "log", "-1", "--format=%H", "--", path }, { cwd = root, text = true }):wait()
    if log.code ~= 0 or vim.trim(log.stdout) == "" then
      notify("커밋 이력 없음 (아직 commit 안 된 파일)")
      return
    end
  end
  return root
end

local map = vim.keymap.set
map("n", "<Leader>gv", function()
  if require("diffview.lib").get_current_view() then
    vim.cmd("DiffviewClose")
  elseif git_root(false) then
    vim.cmd("DiffviewOpen")
  end
end, { desc = "Review all changes" })
map("n", "<Leader>gl", function()
  if git_root(true) then
    vim.cmd("DiffviewFileHistory %")
  end
end, { desc = "Current file history" })
-- mini.extra git pickers raise a Lua error outside a repository, so check first.
local function git_picker(name)
  return function()
    if git_root(false) then
      MiniExtra.pickers[name]()
    end
  end
end
map("n", "<Leader>gh", git_picker("git_hunks"), { desc = "Changed hunks" })
map("n", "<Leader>gc", git_picker("git_commits"), { desc = "Commits" })
map("n", "<Leader>gB", git_picker("git_branches"), { desc = "Branches" })

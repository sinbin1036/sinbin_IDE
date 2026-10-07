-- AI Coding Agents (TASK-015): Claude Code and Codex CLI as independent CLIs in the
-- right area (docs/DECISIONS.md D-002, D-017), which also holds a plain shell, opened at
-- startup (TASK-016). Neovim only runs them and hands over file references; edits they
-- make come back through checktime and <Leader>gv.

local terminal = require("sinbin.terminal")

local M = {}

--- @type table<string, { cmd: string, name: string }>
local AGENTS = {
  claude = { cmd = "claude", name = "Claude Code" },
  codex = { cmd = "codex", name = "Codex" },
}

local last = "claude"
--- Working directory each agent was started in, for relative file references.
--- @type table<string, string>
local cwds = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.WARN)
end

local function term_id(agent)
  return "agent:" .. agent
end

--- The plain shell of the right area.
local SHELL = "side"

--- Git root of the current file, else the working directory.
local function root_dir()
  local file = vim.api.nvim_buf_get_name(0)
  local source = (vim.bo.buftype == "" and file ~= "") and file or vim.fn.getcwd()
  return vim.fs.normalize(vim.fs.root(source, ".git") or vim.fn.getcwd())
end

--- Shows or hides `agent`, starting it on first use in the git root of the current file
--- (or the working directory).
function M.toggle(agent)
  local spec = AGENTS[agent]
  if vim.fn.executable(spec.cmd) == 0 then
    notify(("%s 없음 (설치: npm install -g ...)"):format(spec.cmd))
    return
  end
  last = agent
  if not terminal.is_running(term_id(agent)) then
    cwds[agent] = root_dir()
  end
  terminal.toggle(term_id(agent), "right", { cmd = spec.cmd, cwd = cwds[agent], name = spec.name })
end

--- Agent to send to: the last used one that is running, else any running one.
local function target()
  if terminal.is_running(term_id(last)) then
    return last
  end
  for agent in pairs(AGENTS) do
    if terminal.is_running(term_id(agent)) then
      return agent
    end
  end
end

--- Names of the agents running now, for the statusline.
--- @return string[]
function M.running()
  local names = {}
  for agent, spec in pairs(AGENTS) do
    if terminal.is_running(term_id(agent)) then
      names[#names + 1] = spec.name
    end
  end
  table.sort(names)
  return names
end

--- `@path#L10-20` for the current file, relative to the agent's directory when inside it.
local function reference(agent, line1, line2)
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local cwd = cwds[agent]
  local path = file
  if cwd and file:sub(1, #cwd + 1) == cwd .. "/" then
    path = file:sub(#cwd + 2)
  end
  local ref = "@" .. path
  if line1 then
    ref = ref .. "#L" .. line1 .. ((line2 and line2 ~= line1) and ("-" .. line2) or "")
  end
  return ref .. " "
end

--- Types a reference to the current file (and line range) into the agent's input,
--- without Enter, and moves there so the question can follow.
function M.send_reference(line1, line2)
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or name == "" then
    notify("파일 버퍼 아님")
    return
  end
  local agent = target()
  if not agent then
    notify("실행 중인 Agent 없음 (<Space>ac Claude Code, <Space>ax Codex)")
    return
  end
  local ref = reference(agent, line1, line2)
  terminal.send(term_id(agent), ref)
  terminal.focus(term_id(agent))
end

--- Window the cursor came from when jumping to an agent, to jump back to.
local code_win

--- One key back and forth between the code window and the right area: into whatever
--- the right area shows (else a running agent, else its shell, else the last agent
--- started), and back to the code window it was entered from. Kept with the TASK-016
--- window keys (Alt+h/j/k/l move to any neighbour).
function M.jump()
  if vim.w.sinbin_region == "right" then
    -- Full screen covers the code window: back to the column first.
    if terminal.is_zoomed() then
      terminal.toggle_zoom()
    end
    vim.cmd.stopinsert()
    if code_win and vim.api.nvim_win_is_valid(code_win) then
      vim.api.nvim_set_current_win(code_win)
    else
      vim.cmd.wincmd("p")
    end
    return
  end
  code_win = vim.api.nvim_get_current_win()
  local win = require("sinbin.layout").right_win()
  if win then
    vim.api.nvim_set_current_win(win)
    vim.cmd.startinsert()
    return
  end
  local agent = target()
  if agent then
    terminal.focus(term_id(agent))
  elseif terminal.is_running(SHELL) then
    terminal.show(SHELL)
  else
    M.toggle(last)
  end
end

--- The right area's plain shell: open / move / hide like the other area keys.
--- @param background? boolean start without taking the cursor
function M.toggle_shell(background)
  terminal.toggle(SHELL, "right", { name = "Terminal", cwd = root_dir(), background = background })
end

-- At startup the right area opens with a plain shell, not an agent (user choice,
-- TASK-016). Not for git commit messages, diff mode, a Neovim inside a Neovim terminal
-- (lazygit's editor) or without a UI.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("sinbin_agent", { clear = true }),
  desc = "Right area shell at startup",
  once = true,
  callback = function()
    local ft = vim.bo.filetype
    if #vim.api.nvim_list_uis() == 0 or vim.env.NVIM or vim.o.diff or ft == "gitcommit" or ft == "gitrebase" then
      return
    end
    M.toggle_shell(true)
    -- The start screen centers its content on the narrower window.
    if vim.bo.filetype == "ministarter" then
      MiniStarter.refresh()
    end
  end,
})

local map = vim.keymap.set
map({ "n", "t" }, "<M-a>", M.jump, { desc = "Jump between code and agent" })
map("n", "<Leader>ac", function() M.toggle("claude") end, { desc = "Claude Code" })
map("n", "<Leader>ax", function() M.toggle("codex") end, { desc = "Codex" })
map("n", "<Leader>at", function() M.toggle_shell() end, { desc = "Terminal (right area)" })
-- Right area full screen and back (TASK-016). Alt: works while typing in the agent.
map("n", "<Leader>az", terminal.toggle_zoom, { desc = "Right area full screen" })
map({ "n", "t" }, "<M-z>", terminal.toggle_zoom, { desc = "Right area full screen" })
map("n", "<Leader>af", function() M.send_reference() end, { desc = "Send file to agent" })
map("x", "<Leader>as", function()
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  if a > b then
    a, b = b, a
  end
  -- Leave Visual mode before switching windows.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  M.send_reference(a, b)
end, { desc = "Send selected lines to agent" })

return M

-- AI Coding Agents (TASK-015): Claude Code and Codex CLI as independent CLIs in a right
-- split (docs/DECISIONS.md D-002, D-017). Neovim only runs them and hands over file
-- references; edits they make come back through checktime and <Leader>gv.

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
    local file = vim.api.nvim_buf_get_name(0)
    local source = (vim.bo.buftype == "" and file ~= "") and file or vim.fn.getcwd()
    cwds[agent] = vim.fs.normalize(vim.fs.root(source, ".git") or vim.fn.getcwd())
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

--- Agent id of the current buffer, if it is an agent terminal.
local function current_agent()
  local buf = vim.api.nvim_get_current_buf()
  for _, t in ipairs(terminal.list()) do
    if t.buf == buf and t.id:match("^agent:") then
      return t.id:sub(#"agent:" + 1)
    end
  end
end

--- One key back and forth: code window -> agent (shown or started, ready for input),
--- agent -> the code window it was entered from. Temporary until the Phase 11 layout.
function M.jump()
  if current_agent() then
    vim.cmd.stopinsert()
    if code_win and vim.api.nvim_win_is_valid(code_win) then
      vim.api.nvim_set_current_win(code_win)
    else
      vim.cmd.wincmd("p")
    end
    return
  end
  code_win = vim.api.nvim_get_current_win()
  local agent = target() or last
  if not terminal.focus(term_id(agent)) then
    M.toggle(agent)
  end
end

local map = vim.keymap.set
map({ "n", "t" }, "<M-a>", M.jump, { desc = "Jump between code and agent" })
map("n", "<Leader>aa", function() M.toggle(last) end, { desc = "Agent (last used)" })
map("n", "<Leader>ac", function() M.toggle("claude") end, { desc = "Claude Code" })
map("n", "<Leader>ax", function() M.toggle("codex") end, { desc = "Codex" })
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

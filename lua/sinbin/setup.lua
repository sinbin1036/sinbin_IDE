-- :Setup and the start screen `s` item (TASK-021): runs the install script of this
-- repository (Platform Layer `setup_cmd`, Windows: setup.ps1) in a terminal tab page.
-- Uses only built-in Neovim, so it works when the plugins are missing (git or the
-- network failed on the first start) or failed to load.

local M = {}

function M.run()
  -- The real repository path: through the config junction setup.ps1 would see its own
  -- link as the repository.
  local root = vim.uv.fs_realpath(vim.fn.stdpath("config")) or vim.fn.stdpath("config")
  local cmd_of = require("sinbin.platform").setup_cmd
  local cmd = cmd_of and cmd_of(root)
  if not cmd then
    vim.notify("이 OS용 설치 스크립트 없음 (Windows: setup.ps1)", vim.log.levels.WARN)
    return
  end

  -- A scratch buffer, not :tabnew's empty file buffer: entering a file buffer opens the
  -- right area shell after the start screen (sinbin.agent), which the setup tab should not.
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.cmd("tab sbuffer " .. buf)
  vim.fn.jobstart(cmd, {
    term = true,
    cwd = root,
    on_exit = function(_, code)
      vim.schedule(function()
        local msg = code == 0 and "설치 끝: 새로 설치한 Plugin은 Neovim을 다시 시작하면 적용됩니다"
          or ("설치 중 실패 항목 있음 (exit %d): 위 요약 참고"):format(code)
        vim.notify(msg, code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
        if vim.api.nvim_buf_is_valid(buf) then
          vim.keymap.set("n", "q", function()
            if #vim.api.nvim_list_tabpages() > 1 then
              vim.cmd.tabclose()
            else
              vim.cmd.bwipeout({ bang = true })
            end
          end, { buffer = buf, desc = "Close setup tab" })
        end
      end)
    end,
  })
  vim.cmd.startinsert()
end

return M

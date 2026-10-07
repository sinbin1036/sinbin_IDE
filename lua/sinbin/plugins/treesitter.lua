-- Treesitter (TASK-008): nvim-treesitter (main) installs parsers and queries,
-- highlighting is the built-in vim.treesitter. Indent and folding stay off (user choice).
-- Requires the tree-sitter CLI, a C compiler, tar and curl on PATH.

-- `c` is installed too although Neovim ships a C parser: the bundled queries lack
-- `locals`, which debug virtual text (nvim-dap-view, TASK-014) needs.
local parsers = {
  "c", "typescript", "tsx", "javascript", "python", "java", "dart",
  "json", "yaml", "toml",
}

-- Async, and a no-op for parsers that are already installed. Without the tree-sitter
-- CLI every missing parser fails to build on each startup, so warn once instead.
-- setup.ps1 (TASK-021) installs them itself with progress output, not at startup.
local installed = require("nvim-treesitter").get_installed("parsers")
local missing = vim.tbl_filter(function(p) return not vim.list_contains(installed, p) end, parsers)
if vim.env.SINBIN_SETUP then
  -- nothing: scripts/setup/nvim_setup.lua
elseif #missing == 0 or vim.fn.executable("tree-sitter") == 1 then
  require("nvim-treesitter").install(parsers)
else
  vim.notify(("tree-sitter CLI 없음: 구문 강조 parser %d개 설치 건너뜀 (%s)"):format(
    #missing, table.concat(missing, ", ")), vim.log.levels.WARN)
end

local group = vim.api.nvim_create_augroup("sinbin_treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  desc = "Start treesitter highlighting when a parser is available",
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and vim.treesitter.language.add(lang) then
      vim.treesitter.start(args.buf, lang)
    end
  end,
})

-- Parsers must match the plugin version, so update them whenever vim.pack updates it.
vim.api.nvim_create_autocmd("PackChanged", {
  group = group,
  desc = "Update treesitter parsers after nvim-treesitter update",
  callback = function(args)
    if args.data.spec.name == "nvim-treesitter" and args.data.kind == "update" then
      vim.schedule(function() vim.cmd("TSUpdate") end)
    end
  end,
})

return { parsers = parsers }

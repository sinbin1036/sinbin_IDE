-- Treesitter (TASK-008): nvim-treesitter (main) installs parsers and queries,
-- highlighting is the built-in vim.treesitter. Indent and folding stay off (user choice).
-- Requires the tree-sitter CLI, a C compiler, tar and curl on PATH.

-- `c` is not listed: its parser and queries ship with Neovim.
local parsers = {
  "typescript", "tsx", "javascript", "python", "java", "dart",
  "json", "yaml", "toml",
}

-- Async, and a no-op for parsers that are already installed.
require("nvim-treesitter").install(parsers)

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

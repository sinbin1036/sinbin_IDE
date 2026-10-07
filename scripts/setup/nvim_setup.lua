-- Headless helper for the setup scripts (TASK-021). OS neutral: setup.ps1 now, the
-- Linux/macOS script later. Runs inside the configured Neovim:
--
--   SINBIN_SETUP=1 SINBIN_SETUP_STEP=<step> nvim --headless -c "luafile nvim_setup.lua" -c "qa!"
--
-- and prints one line per real state change on stdout, which the script turns into UI:
--
--   @@sinbin|total|<n>              number of items in this step
--   @@sinbin|present|<name>|<info>  already installed, nothing done
--   @@sinbin|start|<name>           installation started
--   @@sinbin|done|<name>|<info>     installed
--   @@sinbin|fail|<name>|<reason>   failed
--
-- Steps:
--   plugins  vim.pack already installed missing plugins while the config loaded (its own
--            "vim.pack: n% ... (i/N)" progress goes to stderr); report each plugin.
--   parsers  Treesitter parsers from sinbin.plugins.treesitter, in parallel.
--   mason    Mason packages listed in SINBIN_SETUP_MASON (comma separated), in parallel.

local TIMEOUT = 30 * 60 * 1000

local function emit(event, name, info)
  local fields = { "@@sinbin", event, name or "", (tostring(info or ""):gsub("[|\r\n]+", " ")) }
  io.stdout:write(table.concat(fields, "|"), "\n")
  io.stdout:flush()
end

local steps = {}

function steps.plugins()
  local plugins = vim.pack.get(nil, { info = false })
  emit("total", nil, #plugins)
  for _, p in ipairs(plugins) do
    if p.path and vim.uv.fs_stat(p.path) then
      emit("present", p.spec.name, p.rev and p.rev:sub(1, 7))
    else
      emit("fail", p.spec.name, "not installed")
    end
  end
end

function steps.parsers()
  local ts = require("nvim-treesitter")
  local list = require("sinbin.plugins.treesitter").parsers
  local installed = ts.get_installed("parsers")
  emit("total", nil, #list)
  local pending = 0
  for _, lang in ipairs(list) do
    if vim.list_contains(installed, lang) then
      emit("present", lang)
    else
      pending = pending + 1
      emit("start", lang)
      ts.install(lang):await(function(err, ok)
        pending = pending - 1
        if err or not ok then
          emit("fail", lang, err or "build failed")
        else
          emit("done", lang)
        end
      end)
    end
  end
  vim.wait(TIMEOUT, function() return pending == 0 end, 50)
end

function steps.mason()
  local names = vim.split(vim.env.SINBIN_SETUP_MASON or "", ",", { trimempty = true })
  emit("total", nil, #names)
  if #names == 0 then
    return
  end
  local registry = require("mason-registry")
  local refreshed = false
  registry.refresh(function() refreshed = true end)
  vim.wait(TIMEOUT, function() return refreshed end, 50)

  local function version(pkg)
    local ok, v = pcall(pkg.get_installed_version, pkg)
    return ok and v or nil
  end

  local pending = 0
  for _, name in ipairs(names) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      emit("fail", name, "not in Mason registry")
    elseif pkg:is_installed() then
      emit("present", name, version(pkg))
    else
      pending = pending + 1
      emit("start", name)
      pkg:install({}, function(success, result)
        pending = pending - 1
        if success then
          emit("done", name, version(pkg))
        else
          emit("fail", name, result)
        end
      end)
    end
  end
  vim.wait(TIMEOUT, function() return pending == 0 end, 50)
end

local step = steps[vim.env.SINBIN_SETUP_STEP or ""]
if not step then
  emit("fail", vim.env.SINBIN_SETUP_STEP, "unknown step")
  return
end
local ok, err = pcall(step)
if not ok then
  emit("fail", vim.env.SINBIN_SETUP_STEP, err)
end

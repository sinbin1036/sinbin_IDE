-- Run / Build / Test (TASK-013), in two scopes:
--   file    (<Leader>rr, <Leader>rb, <Leader>xf) - the current source file
--   project (<Leader>rR, <Leader>rB, <Leader>xx) - the project the current file belongs to
-- Commands run in the "run" terminal (sinbin.terminal.exec) from the project root, or
-- from the file's directory when there is no project.
-- A project can override commands in <root>/.sinbin/run.json.

local terminal = require("sinbin.terminal")

local M = {}

local TERM_ID = "run"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.WARN)
end

-- Commands are shell command lines (bash on Windows, see Platform Layer), so quote
-- paths for sh and use forward slashes.
local function q(path)
  path = path:gsub("\\", "/")
  return "'" .. path:gsub("'", [['\'']]) .. "'"
end

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local text = f:read("*a")
  f:close()
  return text
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function python()
  return require("sinbin.platform").python or "python3"
end

--- @class sinbin.Project
--- @field kind string shown to the user, e.g. "node (pnpm)"
--- @field type string detector type: node, flutter, dart, maven, python, c, custom
--- @field root string
--- @field run? string
--- @field build? string
--- @field test? string
--- @field pm? string node package manager
--- @field has_test_script? boolean
--- @field extra? { name: string, cmd: string }[] more project commands for the picker
--- @field override? table contents of .sinbin/run.json

--- @type { type: string, markers: string[], build: fun(root: string): sinbin.Project }[]
local detectors = {
  {
    type = "node",
    markers = { "package.json" },
    build = function(root)
      local ok, pkg = pcall(vim.json.decode, read(root .. "/package.json") or "")
      local scripts = ok and type(pkg) == "table" and type(pkg.scripts) == "table" and pkg.scripts or {}
      -- Package manager: the packageManager field, else the first lock file whose tool is
      -- installed (projects often carry stale lock files of tools that are not), else npm.
      local pm, note = "npm", nil
      local declared = ok and type(pkg) == "table" and type(pkg.packageManager) == "string"
        and pkg.packageManager:match("^(%a+)@")
      local skipped = {}
      if declared and vim.fn.executable(declared) == 1 then
        pm = declared
      else
        if declared then
          skipped[#skipped + 1] = "packageManager " .. declared
        end
        for _, c in ipairs({
          { "pnpm", { "pnpm-lock.yaml" } },
          { "yarn", { "yarn.lock" } },
          { "bun", { "bun.lockb", "bun.lock" } },
          { "npm", { "package-lock.json" } },
        }) do
          local has_lock = exists(root .. "/" .. c[2][1]) or (c[2][2] and exists(root .. "/" .. c[2][2]))
          if has_lock then
            if vim.fn.executable(c[1]) == 1 then
              pm = c[1]
              break
            end
            skipped[#skipped + 1] = c[2][1]
          end
        end
      end
      if #skipped > 0 then
        note = table.concat(skipped, ", ") .. " 있지만 도구 미설치"
      end
      local function script(name)
        return scripts[name] and (pm .. " run " .. name) or nil
      end
      local extra = {}
      for name in pairs(scripts) do
        extra[#extra + 1] = { name = pm .. " run " .. name, cmd = pm .. " run " .. name }
      end
      table.sort(extra, function(a, b) return a.name < b.name end)
      return {
        kind = "node (" .. pm .. (note and ("; " .. note) or "") .. ")",
        root = root,
        run = script("dev") or script("start"),
        build = script("build"),
        test = script("test"),
        pm = pm,
        has_test_script = scripts.test ~= nil,
        extra = extra,
      }
    end,
  },
  {
    type = "dart",
    markers = { "pubspec.yaml" },
    build = function(root)
      if (read(root .. "/pubspec.yaml") or ""):find("sdk:%s*flutter") then
        return {
          kind = "flutter",
          type = "flutter",
          root = root,
          run = "flutter run",
          -- `flutter build` needs a target; pick one with <Leader>rt.
          test = "flutter test",
          extra = {
            { name = "flutter build windows", cmd = "flutter build windows" },
            { name = "flutter build web", cmd = "flutter build web" },
            { name = "flutter build apk", cmd = "flutter build apk" },
            { name = "flutter pub get", cmd = "flutter pub get" },
          },
        }
      end
      return {
        kind = "dart",
        root = root,
        run = "dart run",
        test = "dart test",
        extra = { { name = "dart pub get", cmd = "dart pub get" } },
      }
    end,
  },
  {
    type = "maven",
    markers = { "pom.xml" },
    build = function(root)
      local spring = (read(root .. "/pom.xml") or ""):find("spring%-boot") ~= nil
      return {
        kind = spring and "maven (spring boot)" or "maven",
        root = root,
        run = spring and "mvn spring-boot:run" or nil,
        build = "mvn package",
        test = "mvn test",
        extra = { { name = "mvn clean", cmd = "mvn clean" }, { name = "mvn compile", cmd = "mvn compile" } },
      }
    end,
  },
  {
    type = "python",
    markers = { "pyproject.toml", "requirements.txt", "setup.py" },
    build = function(root)
      local run
      for _, entry in ipairs({ "main.py", "app.py", "manage.py" }) do
        if exists(root .. "/" .. entry) then
          run = python() .. " " .. entry .. (entry == "manage.py" and " runserver" or "")
          break
        end
      end
      return { kind = "python", root = root, run = run, test = python() .. " -m pytest" }
    end,
  },
  {
    type = "c",
    markers = { "Makefile", "makefile", "CMakeLists.txt" },
    build = function(root)
      if exists(root .. "/CMakeLists.txt") and not exists(root .. "/Makefile") then
        return { kind = "c (cmake)", root = root, build = "cmake -S . -B build && cmake --build build" }
      end
      return { kind = "c (make)", root = root, build = "make", test = "make test" }
    end,
  },
}

--- <root>/.sinbin/run.json. Keys run/build/test (project) and
--- run_file/build_file/test_file (file, "{file}" is replaced by the current file).
local function read_override(root)
  local text = read(root .. "/.sinbin/run.json")
  if not text then
    return nil
  end
  local ok, conf = pcall(vim.json.decode, text)
  if not ok or type(conf) ~= "table" then
    notify(".sinbin/run.json 형식 오류: " .. tostring(conf))
    return nil
  end
  return conf
end

--- Project of a file or directory: the nearest marker among all detectors.
--- @param source string file or directory
--- @return sinbin.Project?
local function project_at(source)
  local best, best_root
  for _, d in ipairs(detectors) do
    local root = vim.fs.root(source, d.markers)
    if root and (not best_root or #root > #best_root) then
      best, best_root = d, root
    end
  end
  -- A .sinbin/run.json can define a project on its own.
  local custom_root = vim.fs.root(source, ".sinbin")
  if custom_root and (not best_root or #custom_root > #best_root) then
    best, best_root = nil, custom_root
  end
  if not best_root then
    return nil
  end
  best_root = vim.fs.normalize(best_root)
  local proj = best and best.build(best_root) or { kind = "custom", root = best_root }
  proj.type = proj.type or (best and best.type or "custom")

  local conf = read_override(best_root)
  if conf then
    proj.override = conf
    proj.kind = proj.kind .. " + run.json"
    for _, key in ipairs({ "run", "build", "test" }) do
      if type(conf[key]) == "string" then
        proj[key] = conf[key]
      end
    end
  end
  return proj
end

--- Projects one level below `dir` (e.g. front/ and back/ of a monorepo).
--- @return sinbin.Project[]
local function subprojects(dir)
  local found = {}
  for name, t in vim.fs.dir(dir) do
    if t == "directory" and not name:match("^%.") and name ~= "node_modules" then
      local proj = project_at(dir .. "/" .. name)
      if proj and proj.root == dir .. "/" .. name then
        found[#found + 1] = proj
      end
    end
  end
  table.sort(found, function(a, b) return a.root < b.root end)
  return found
end

--- Current source file, or nil outside a file buffer.
local function current_file()
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or name == "" then
    return nil
  end
  return vim.fs.normalize(name)
end

--- Fully qualified Java class name of the current buffer.
local function java_class(file)
  local class = vim.fn.fnamemodify(file, ":t:r")
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 50, false)) do
    local pkg = line:match("^%s*package%s+([%w_.]+)%s*;")
    if pkg then
      return pkg .. "." .. class
    end
  end
  return class
end

--- Commands for the current file. A missing command has its reason in `why`.
--- @param file string
--- @param proj? sinbin.Project
--- @return { run?: string, build?: string, test?: string, why: table<string, string> }
local function file_tasks(file, proj)
  local ft = vim.bo.filetype
  local f = q(file)
  local t = { why = {} }
  local ptype = proj and proj.type

  if ft == "python" then
    t.run = python() .. " " .. f
    t.test = python() .. " -m pytest " .. f
    t.why.build = "Python은 빌드 없음 (실행: <Space>rr)"
  elseif ft == "c" then
    local out = q(vim.fn.fnamemodify(file, ":r"))
    t.build = "gcc -Wall -g " .. f .. " -o " .. out
    t.run = t.build .. " && " .. out
    t.why.test = "C 파일 테스트 없음"
  elseif ft == "javascript" or ft == "typescript" then
    -- Node 22 runs TypeScript itself; transform-types also covers enums. Imports of
    -- other .ts files need the extension, so larger code runs via project scripts.
    t.run = ft == "typescript" and ("node --experimental-transform-types --no-warnings " .. f) or ("node " .. f)
    t.why.build = "TS/JS 파일 빌드 없음 (타입 검사는 LSP, 프로젝트 빌드: <Space>rB)"
    if ptype == "node" and proj.has_test_script then
      -- jest and vitest both take file paths after `--`.
      t.test = proj.pm .. " run test -- " .. f
    else
      t.why.test = "package.json에 test script 없음"
    end
  elseif ft == "typescriptreact" or ft == "javascriptreact" then
    t.why.run = "JSX 파일은 단독 실행 안 됨 (프로젝트 실행: <Space>rR)"
    t.why.build = t.why.run
    if ptype == "node" and proj.has_test_script then
      t.test = proj.pm .. " run test -- " .. f
    else
      t.why.test = "package.json에 test script 없음"
    end
  elseif ft == "dart" then
    if ptype == "flutter" then
      t.run = "flutter run -t " .. f
      t.test = "flutter test " .. f
      t.why.build = "Flutter는 파일 빌드 없음 (프로젝트 빌드 대상: <Space>rt)"
    else
      t.run = "dart run " .. f
      t.build = "dart compile exe " .. f
      t.test = "dart test " .. f
    end
  elseif ft == "java" then
    if ptype == "maven" then
      -- exec:java resolves without plugin config; the class needs a main method.
      t.run = "mvn -q compile exec:java -Dexec.mainClass=" .. java_class(file)
      t.test = "mvn test -Dtest=" .. vim.fn.fnamemodify(file, ":t:r")
    else
      -- Single-file source launcher (JDK 11+).
      t.run = "java " .. f
      t.why.test = "Maven 프로젝트가 아니라 테스트 명령 없음"
    end
    t.why.build = "Java 파일 빌드 없음 (프로젝트 빌드: <Space>rB)"
  end

  -- run.json file commands win.
  local conf = proj and proj.override
  if conf then
    for key, conf_key in pairs({ run = "run_file", build = "build_file", test = "test_file" }) do
      if type(conf[conf_key]) == "string" then
        t[key] = conf[conf_key]:gsub("{file}", function() return f end)
      end
    end
  end
  return t
end

local function relative_label(dir)
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  if dir == cwd then
    return "./"
  end
  local rel = dir:sub(1, #cwd + 1) == cwd .. "/" and dir:sub(#cwd + 2) or dir
  return rel .. "/"
end

local last -- { cmd, cwd }

--- @param focus? boolean move into the terminal for input (file commands)
local function exec(cmd, cwd, focus)
  local label = ("%s  (%s)"):format(cmd, relative_label(cwd))
  last = { cmd = cmd, cwd = cwd, focus = focus }
  notify("▶ " .. label, vim.log.levels.INFO)
  terminal.exec(TERM_ID, cmd, { cwd = cwd, name = "run: " .. label, focus = focus })
end

local NAMES = { run = "실행", build = "빌드", test = "테스트" }
local PROJECT_KEYS = { run = "rR", build = "rB", test = "xx" }

--- Runs `key` ("run", "build", "test") for the current file.
function M.file(key)
  local file = current_file()
  if not file then
    notify(("파일 버퍼 아님 (소스 파일을 연 상태에서. 프로젝트 %s: <Space>%s)"):format(NAMES[key], PROJECT_KEYS[key]))
    return
  end
  local proj = project_at(file)
  local tasks = file_tasks(file, proj)
  local cmd = tasks[key]
  if not cmd then
    notify(tasks.why[key] or ("%s 파일 %s 명령 없음 (.sinbin/run.json의 %s_file로 지정 가능)"):format(
      vim.bo.filetype ~= "" and vim.bo.filetype or "이", NAMES[key], key))
    return
  end
  -- Scripts often read input (e.g. input()), so go straight into the terminal.
  exec(cmd, proj and proj.root or vim.fs.dirname(file), true)
end

--- Calls `cb(project)` for the current context: the current file's project, the
--- working directory's project, or one picked from its subprojects.
local function with_project(cb)
  local file = current_file()
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  local proj = project_at(file or cwd)
  if proj then
    return cb(proj)
  end
  if file then
    notify("프로젝트 감지 안 됨 (파일 실행: <Space>rr)")
    return
  end
  local subs = subprojects(cwd)
  if #subs == 0 then
    notify("프로젝트 감지 안 됨 (현재 폴더: " .. cwd .. ")")
  elseif #subs == 1 then
    cb(subs[1])
  else
    vim.ui.select(subs, {
      prompt = "어느 프로젝트?",
      format_item = function(p) return ("%-20s %s"):format(relative_label(p.root), p.kind) end,
    }, function(p)
      if p then
        cb(p)
      end
    end)
  end
end

--- Project of the current file or working directory (no subproject prompt).
--- @return sinbin.Project?
function M.current_project()
  return project_at(current_file() or vim.fs.normalize(vim.fn.getcwd()))
end

--- Runs `key` ("run", "build", "test") for the current project.
function M.project(key)
  with_project(function(proj)
    local cmd = proj[key]
    if not cmd then
      notify(("%s: 프로젝트 %s 명령 없음 (<Space>rt에서 선택하거나 .sinbin/run.json의 %s로 지정)"):format(
        proj.kind, NAMES[key], key))
      return
    end
    exec(cmd, proj.root)
  end)
end

function M.rerun()
  if not last then
    notify("다시 실행할 명령 없음")
    return
  end
  exec(last.cmd, last.cwd, last.focus)
end

function M.stop()
  if not terminal.stop(TERM_ID) then
    notify("실행 중인 명령 없음", vim.log.levels.INFO)
  end
end

--- All commands for the current context, labelled [파일] / [프로젝트], for a picker.
--- @param cb fun(items: { text: string, cmd: string, cwd: string }[])
function M.commands(cb)
  local file = current_file()
  local function collect(proj)
    local items, seen = {}, {}
    local function add(scope, cmd, cwd)
      if cmd and not seen[cmd] then
        seen[cmd] = true
        items[#items + 1] = { text = ("[%s] %s"):format(scope, cmd), cmd = cmd, cwd = cwd, focus = scope == "파일" }
      end
    end
    if file then
      local tasks = file_tasks(file, proj)
      local cwd = proj and proj.root or vim.fs.dirname(file)
      add("파일", tasks.run, cwd)
      add("파일", tasks.build, cwd)
      add("파일", tasks.test, cwd)
    end
    if proj then
      for _, key in ipairs({ "run", "build", "test" }) do
        add("프로젝트", proj[key], proj.root)
      end
      for _, e in ipairs(proj.extra or {}) do
        add("프로젝트", e.cmd, proj.root)
      end
    end
    if #items == 0 then
      notify("실행할 명령 없음")
      return
    end
    cb(items)
  end
  if file then
    collect(project_at(file))
  else
    with_project(collect)
  end
end

--- Runs a command picked from M.commands().
function M.run_item(item)
  exec(item.cmd, item.cwd, item.focus)
end

local map = vim.keymap.set
map("n", "<Leader>rr", function() M.file("run") end, { desc = "Run file" })
map("n", "<Leader>rb", function() M.file("build") end, { desc = "Build file" })
map("n", "<Leader>xf", function() M.file("test") end, { desc = "Test file" })
map("n", "<Leader>rR", function() M.project("run") end, { desc = "Run project" })
map("n", "<Leader>rB", function() M.project("build") end, { desc = "Build project" })
map("n", "<Leader>xx", function() M.project("test") end, { desc = "Test project" })
map("n", "<Leader>rl", M.rerun, { desc = "Run last command again" })
map("n", "<Leader>rs", M.stop, { desc = "Stop running command" })

return M

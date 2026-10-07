# TASK-023: Phase 14 안정화 및 최적화

- **Status:** In Progress (2026-10-07) — 1번 checkhealth 정리 완료, 2번 시작 속도 구현·검증 완료(사용자 확인 대기), 3번 업데이트 구현·검증 완료, 4번 안내 메시지·문서 완료 — 사용자 확인 대기
- **Goal:** 매일 쓰는 데 거슬리는 부분을 줄인다. 시작을 빠르게, 업데이트를 명령 하나로, checkhealth를 의미 있는 경고만 남게, 도구가 없거나 실패할 때 안내를 분명하게, 문서를 현재 상태에 맞게.

## Background
- 사용자 결정 (2026-10-07): Phase 13은 Windows 설치 스크립트(TASK-021)까지로 마치고 Linux / macOS 설치 스크립트는 하지 않음(Deferred, `nvim_setup.lua`는 재사용 가능하게 남아 있음) → Phase 14로
- 범위: [PROJECT.md](../../PROJECT.md) "남은 Phase 계획" 14번. 사용자가 4개 항목 모두 선택

## 기준 측정 (2026-10-07, 이 PC, `main` 87cd1c6)
- 시작 시간: `nvim --headless --startuptime <log> +qa` 3회 → `NVIM STARTED` 306.7 / 294.7 / 316.7ms. `init.lua` 205ms 중 `require('sinbin.plugins')` 179ms
  - 큰 항목(자기 시간 포함 누적): `plugins.ui` 42ms, `plugins.debug` 26ms(`dap-view` 20ms), `plugins.lsp` 22ms, `vim._core.defaults` 20ms(Neovim 내장), `plugins.git` 16ms(`diffview` 11ms), `plugins.sidebar` 15ms, `mason` 14ms
  - headless라 UI 그리기·시작 화면은 빠져 있음. 실제 화면 시간은 시작 화면 아래 표시값으로 따로 확인 필요
- checkhealth (`nvim --headless +checkhealth`): ERROR 0, WARNING 17
  - Mason 미사용 언어 도구 9개 (wget, 7z, cargo, luarocks, Ruby, RubyGem, Composer, PHP, julia)
  - provider 6개 (node `neovim` 패키지, perl, python `neovim` 모듈, ruby) — 이 Config는 원격 plugin을 쓰지 않음
  - `vim.lsp`(clangd 설정)의 `c.doxygen`·`cpp.doxygen` "Unknown filetype" 경고 2개
- 문서: README "현재 상태"가 "Phase 1 완료, Phase 2 준비"로 남아 있음

## 범위와 순서 (제안)
1. **checkhealth 정리** — 안 쓰는 provider 끄기(`vim.g.loaded_*_provider = 0`, 시작 시간에도 도움), 남는 WARNING은 원인과 무시 이유를 기록
2. **시작 속도** — 무거운 모듈(dap·dap-view, diffview, mason, LSP 설정 등)을 처음 쓸 때(키·명령·filetype) 로드하도록 미룸. `vim.pack`에 lazy loading이 없으므로 자체 처리. 목표치는 측정 후 확정
3. **업데이트 명령** — 새 명령 대신 기존 `:Setup`을 넓힘: `:Setup update` / `setup.ps1 -Update` (사용자 제안 2026-10-07, 같은 화면·helper `nvim_setup.lua` 재사용). 대상 제안: Plugin(`vim.pack.update`, 확인 화면 없이 적용 후 요약, lock 변경 → 커밋 필요·재시작 필요)·Treesitter parser·Mason. 외부 도구(`winget upgrade`)는 UAC·실행 중 Neovim 충돌 때문에 제외. lock 파일은 안내만 하고 커밋은 사용자가 확인 후 직접 (사용자 결정 2026-10-07, 추천안)
4. **에러·안내 메시지·문서** — 외부 도구(rg, fd, lazygit, claude, codex, tree-sitter CLI 등)가 없을 때 안내 문구 점검, README 현재 상태 갱신, USAGE 정리

각 항목은 시작 전에 구체 방법을 사용자와 확인한다.

## 1. checkhealth 정리 (2026-10-07)
- 안 쓰는 원격 plugin provider 끔: `options.lua`에서 `vim.g.loaded_{python3,node,ruby,perl}_provider = 0` (이 Config의 Plugin은 모두 Lua, 원격 plugin 없음). clipboard provider는 그대로
- clangd `filetypes`에서 `c.doxygen`·`cpp.doxygen` 제외 (`plugins/lsp.lua`): nvim-lspconfig 기본값에 있는 복합 filetype으로 `g:load_doxygen_syntax`를 켤 때만 쓰임, checkhealth가 "Unknown filetype" 경고
- 남는 WARNING 9개: Mason `[Languages]`·`[Core utils]`의 선택 도구 확인(wget·7z·cargo·luarocks·Ruby·RubyGem·Composer·PHP·julia). Mason 설정으로 끌 수 없고, 이 Config의 Mason 패키지(clangd·vtsls·basedpyright·ruff·jdtls·debugpy·js-debug-adapter·java-debug-adapter)는 필요 없음. 다운로드·압축은 curl·unzip·tar·gzip·powershell로 OK → 무시하고 [VERIFICATION.md](../../VERIFICATION.md)에 기록
- 검증: checkhealth ERROR 0 / WARNING 17 → ERROR 0 / WARNING 9, `vim.provider`는 4개 모두 `Disabled (loaded_*_provider=0)`·clipboard OK(win32yank) / C 파일(`int main`)에서 filetype `c`, clangd 연결 / 일반 시작 에러 없음
- 시작 시간: 정리 후 headless 345~406ms로 기준(295~317ms)보다 오히려 크게 나옴 → 측정 시점 PC 부하 차이로 보임(provider 끄기는 확인 작업을 줄이는 쪽). 2번에서 같은 조건 반복 측정으로 다시 비교

## 2. 시작 속도 (2026-10-07)
### 측정 방법
- 이 PC는 다른 프로그램 부하가 커서(측정 중 CPU 63%) 한 번씩 재면 같은 코드도 272~600ms로 흔들림 → 변경 전(`main` worktree, `XDG_CONFIG_HOME`으로 지정)과 변경 후를 **번갈아** 20번씩 실행해 쌍별 차이로 비교 (`nvim --headless --startuptime`, 첫 실행 1회는 버림)
- 단계별 원인은 `--startuptime`의 self 시간 + 시작 중 autocmd callback 시간 측정(`nvim_create_autocmd`를 감싸 callback마다 시간 기록)
### 원인 (변경 전, 부하 낮을 때 기준 약 295ms)
- 상태줄 git 상태 갱신(`statusline.lua`, VimEnter/BufEnter): 약 22ms — git 프로세스 3개 시작이 Windows에서 동기로 오래 걸림
- `vim.pack.add` 자체 약 30ms, `locale set` 약 18ms·`vim._core.defaults` 약 20ms·내장 plugin(matchit·netrw) 약 9ms는 Neovim 쪽
- 영역 모듈: ui 34ms, debug 28ms(dap-view 21ms), lsp 24ms(mason 14ms), git 16ms(diffview 11ms), sidebar 13ms
- provider 끄기(1번)는 차이 없음 (번갈아 15회: 293.5 / 300.7ms, 오차 범위)
### 변경
- 상태줄 git 갱신을 `vim.defer_fn(..., 0)`로 미룸: 첫 화면과 버퍼 전환을 막지 않음 (3초 throttle은 그대로)
- nvim-dap·nvim-dap-view·diffview-plus 지연 로드 (D-007 "lazy loading 없음 → packadd/autocmd로 직접"에 따름)
  - `plugins/init.lua`: `vim.pack.add(..., { load = fn })`로 세 Plugin은 시작 시 `packadd!` 안 함, 나머지는 기본과 같게 `packadd!`
  - `plugins/debug.lua` → Keymap만 남기고 설정은 `plugins/debug_config.lua`로 이동(내용 그대로, `start_or_continue`를 모듈 함수로). 디버그 키를 처음 누를 때 `packadd` 2개 + `debug_config` 로드
  - `plugins/git.lua`: `<Leader>gv`/`<Leader>gl` 전에 `load_diffview()`(packadd + setup). 직접 입력용 `:DiffviewOpen`·`:DiffviewFileHistory`·`:DiffviewClose`·`:DiffviewToggle` 대체 명령 → 로드 후 같은 명령 실행 (diffview 자체 plugin 파일이 같은 이름으로 다시 정의)
  - `statusline.lua`: 디버그 상태는 `package.loaded.dap`이 있을 때만 확인 (`pcall(require, "dap")`이면 dap을 로드해 버림)
- 하지 않음: mason 지연 로드(약 14ms) — PATH·`$MASON` 직접 설정, `:Mason*` 명령 6개 대체·패키지 이름 완성, 설치 helper(`nvim_setup.lua`)의 registry 설정까지 바꿔야 해서 효과 대비 위험이 큼
### 같이 고친 문제: 남는 `.git/index.lock`
- 상태줄·mini.files git 표시의 `git status`가 index를 갱신하려고 `.git/index.lock`을 잡는데, 그 사이 Neovim이 끝나면 git이 강제 종료되어 lock이 남음 → 이후 git commit 등이 "index.lock: File exists"로 실패 (이 세션에서 2번 발생, 측정용 연속 실행 중 재현)
- `git --no-optional-locks status` (git 공식 권장, 백그라운드 status용)로 변경: `statusline.lua`, `files_git.lua`. 연속 21회 실행 후 lock 없음 확인
### 검증
- 번갈아 20회(같은 부하): 변경 전 중앙값 471.8ms / 변경 후 384.4ms, **쌍별 차이 중앙값 -75.0ms** (부하가 커서 절대값은 큼, 줄어든 폭은 예상 합계 약 65ms와 비슷)
- 시작 시 `dap`·`dap-view`·`diffview` 미로드, 상태줄에 브랜치 표시됨(지연 후)
- `pynvim` UI attach: `<Space>db` → dap·dap-view 로드, breakpoint sign 1개 / `<Space>du` → 디버그 패널 창 / `<Space>gv` → diffview 로드, 탭 페이지 2개, `q` → 1개 / 처음부터 `:DiffviewOpen` → 열림, `:DiffviewClose` → 닫힘
- Python 실제 디버그(`x = 1; y = x + 2; print(y)`, 2번째 줄 breakpoint): `F5` → 설정 선택 창(mini.pick, 설정 2개) → `<CR>` → session 정지(`stopped_thread_id` 1). 변경 전 `main`에서도 같은 흐름
- 일반 시작 `nvim --headless +qa` 에러 없음
- 미검증: 실제 화면에서 시작 화면 아래 시작 시간 표시값, C·Java·Node·Dart 디버그(로드 경로는 같음)

## 3. 업데이트 `:Setup update` / `setup.ps1 -Update` (2026-10-07)
### 결정 (사용자, 추천안 선택)
- 새 명령 대신 `:Setup` 확장 (사용자 제안)
- 대상: Plugin·Treesitter parser·Mason만. 외부 도구(Neovim·Git 등)는 제외 — 실행 중인 Neovim을 winget으로 바꾸면 충돌, UAC 창. 요약에 `winget upgrade --all`(Neovim 끈 뒤) 안내만
- `nvim-pack-lock.json`: 자동 커밋 안 함. Plugin이 바뀌면 요약에 "재시작해 확인 후 커밋" + 되돌리기 방법 안내 (RULES: commit은 사용자 요청 시에만)
### 구현
- `setup.ps1 -Update`: 설치 단계는 그대로(없는 것은 설치), Plugin·parser·Mason 단계만 helper의 업데이트 단계로. `-CheckOnly`와 같이 주면 `-Update` 무시
  - `Update-Plugins`: `Install-Plugins`처럼 vim.pack 진행률(`Updating (i/N)`) bar, 끝에 업데이트된 Plugin만 `이전 → 새` revision 줄로
  - `Install-Group -Updating`: 행 문구 `최신` / `업데이트됨`, 결과 상태 `updated`
  - 요약: `SINBIN IDE UPDATED`, `업데이트 N` 수, Plugin이 바뀌었으면 lock 안내, 외부 도구 안내
- `scripts/setup/nvim_setup.lua` 업데이트 단계
  - `update_plugins`: `vim.pack.update(nil, { force = true })`(확인 buffer 없이 적용, 끝날 때까지 대기) 전후 `vim.pack.get()` revision 비교
  - `update_parsers`: `parser-info/<lang>.revision`과 nvim-treesitter `parsers` 고정 revision 비교, 다르면 `install(lang, { force = true })`. 없으면 설치
  - `update_mason`: registry refresh 후 `get_installed_version()` ≠ `get_latest_version()`이면 `pkg:install()`
- Neovim: `:Setup update`(인자 완성 `update`, 다른 인자는 안내) → `setup.run(true)` → Platform `setup_cmd(root, update)`가 `-Update` 추가. 끝 알림 문구도 업데이트용
### 검증 (임시 `XDG_DATA_HOME`/`STATE`/`CACHE`, `-NoPrompt`)
- 새 설치 후 `-Update`: Plugin 3개 실제 업데이트(gitsigns `070a5d7→851a051`, nvim-lspconfig `3e8d598→33497f4`, nvim-treesitter `910fdf6→e289100`) → `nvim-pack-lock.json` 3줄 변경, 요약 `업데이트 3`·lock 안내·외부 도구 안내 / parser 10개·Mason 6개 `최신`
- 강제로 오래된 상태를 만든 뒤 다시 `-Update`: `c.revision`을 다른 값으로 → `c deadbee → b780e47 업데이트됨`(다시 빌드, 파일 revision 복원) / clangd receipt를 `22.0.0`으로 → `clangd 22.0.0 → 23.1.0 업데이트됨` / Plugin `모두 최신`이면 lock 안내 없음
- 두 실행 모두 basedpyright·debugpy 실패: `WinError 206 파일 이름이 너무 깁니다` — 시험용 임시 경로가 길어서 Python venv 경로 한도 초과(실제 `%LOCALAPPDATA%\nvim-data`에서는 TASK-021에서 52/52 성공). 실패 표시·요약은 정상 동작
- 시험이 바꾼 저장소 `nvim-pack-lock.json`은 `git checkout`으로 되돌림 (사용자 실제 Plugin 폴더는 건드리지 않음)
- `setup_cmd(root, true)` = `powershell ... -File <root>/setup.ps1 -Update`, `:Setup ` 인자 완성 `{ "update" }`, `setup.ps1` 문법 오류 0, UTF-8 BOM 유지
- 미검증: Neovim 안에서 실제 `:Setup update` 실행 화면(사용자 Plugin이 실제로 업데이트되므로 사용자 확인 때)

## 4. 안내 메시지·문서 (2026-10-07)
### 점검 (외부 도구가 없을 때)
- 이미 안내 있음: tree-sitter CLI(시작 시 경고), Agent CLI, lazygit, git 저장소 아님·커밋 이력 없음(diffview), 디버그 adapter 없음(F5), Run 명령 없음, 한/영 전환 도우미 빌드 실패
- 안내 없음 → 추가: **LSP Server 미설치**. `vim.lsp`는 실행 파일이 없으면 Server를 시작하지 않고 자체 로그에만 남김 → 자동완성·진단이 왜 안 되는지 알 수 없음
- ripgrep·fd 없음: mini.pick이 git / 기본 도구로 대체해 동작 → 안내 추가 안 함
### 변경
- `plugins/lsp.lua`: FileType마다 그 filetype을 담당하는 Server의 실행 파일(`vim.lsp.config[name].cmd[1]`, jdtls는 cmd가 함수라 `jdtls`)이 없으면 Server마다 한 번 `Python 언어 서버(basedpyright) 없음: 자동완성·진단·이동 꺼짐. 설치: :MasonInstall basedpyright (Python 필요) 또는 :Setup`. OS 분기 없음 (dartls 실행 파일은 Platform Layer가 정한 cmd)
- 문구 고침: Agent CLI 없음 → 실제 설치 명령(`npm install -g @anthropic-ai/claude-code` / `@openai/codex`, Node.js 필요). lazygit 없음 → 영어 문구를 한국어로, 설치 방법(Windows `:Setup`, Linux/macOS 패키지 관리자). tree-sitter CLI 없음 → `설치: :Setup` 추가. C 디버그 gdb 없음 → `MSYS2 gdb 설치 필요`(지금은 WinLibs) 대신 `설치: :Setup (WinLibs gcc·gdb)`. 오른쪽 영역 비었을 때 → `<Space>at Terminal` 대신 `<Space>at Agent Shell`(TASK-022 탭 이름)
- README "현재 상태": "Phase 1 완료, Phase 2 준비" → Phase 0~13 완료·Phase 14 진행 중 + 주요 기능 4줄, 설치 절에 `-Update`, Linux/macOS 스크립트 "보류"
- USAGE: C 디버그 필요한 것(MSYS2 → gcc·gdb, `:Setup`), Mason 절에 업데이트 행·`:Setup` 언급·Server 없을 때 안내, AI Agent 절에 설치 명령
- 하지 않음: USAGE 전체 재구성(약 880줄, 튜토리얼 + 기능별 참고). 사용자 결정(2026-10-07): 틀린 내용만 고치고 지금 구조 유지 (튜토리얼 분리 안 함)
### 검증
- Server 없음 흉내(`vim.fn.executable`을 basedpyright-langserver·jdtls에 0 반환하도록 바꿔 시작): `.py` → Python 안내, `.java` → Java 안내, `.dart` → 안내 없음(dart.bat 있음) / 같은 파일을 여러 번 열어도 Server마다 1번(알림 2개) / 실제 환경(모두 설치)에서는 `.py`·`.java` 안내 없음
- CLI 없음 흉내(claude·codex·lazygit): `Claude Code 없음 (설치: npm install -g @anthropic-ai/claude-code, Node.js 필요)`, `Codex 없음 (설치: npm install -g @openai/codex, Node.js 필요)`, lazygit 안내
- 일반 시작 `nvim --headless +qa` 에러 없음

## Related Files
`lua/sinbin/options.lua`, `lua/sinbin/plugins/{lsp,init,debug,debug_config,git}.lua`, `lua/sinbin/statusline.lua`, `lua/sinbin/files_git.lua`, `setup.ps1`, `scripts/setup/nvim_setup.lua`, `lua/sinbin/{setup,commands}.lua`, `lua/sinbin/platform/windows.lua`, `lua/sinbin/{agent,lazygit,terminal}.lua`, `lua/sinbin/plugins/treesitter.lua`, `README.md`, `docs/USAGE.md`, `docs/VERIFICATION.md`

# DECISIONS

중요한 Architecture / 기술 결정만 기록한다. 미확정 사항은 기록하지 않는다.
Status: `Proposed` / `Accepted` / `Superseded`

## Format

```
### D-XXX: <제목>
- Date / Status / Context / Decision / Reason / Alternatives / Consequences / Related Task / Evidence
```

## Decisions

### D-001: 완성형 IDE 대신 Neovim 기반 개인 개발환경
- Date: 2026-10-01
- Status: Accepted
- Context: AI Agent 활용으로 주 작업이 코드 작성에서 Diff·Diagnostic·Build/Test·Terminal 확인으로 이동
- Decision: VS Code/JetBrains를 쓰지 않고 Neovim으로 필요한 기능만 직접 구성
- Reason: CLI·Agent 중심 Workflow 최적화, 경량화, 자유로운 UI/Keymap 커스터마이징
- Alternatives: VS Code, JetBrains 계열 IDE
- Consequences: 기능을 직접 구성·유지해야 함. IDE 전체 기능 복제는 Out of Scope
- Related Task: TASK-001
- Evidence: 사용자 프로젝트 설명 (2026-10-01)

### D-002: AI Agent는 독립 CLI로 유지
- Date: 2026-10-01
- Status: Accepted
- Context: Claude Code, Codex CLI 등 여러 Agent 사용 예정
- Decision: Agent를 Neovim Core에 내장하지 않고 Terminal/Panel에서 독립 CLI로 실행
- Reason: Agent 교체 가능성, Neovim Config와의 결합 최소화
- Alternatives: Neovim 내장형 AI Plugin
- Consequences: Neovim 쪽 책임은 Agent 실행 위치·결과 확인 UX로 한정
- Related Task: TASK-001
- Evidence: 사용자 프로젝트 설명 (2026-10-01)

### D-003: OS 차이는 Platform Layer로 격리
- Date: 2026-10-01
- Status: Accepted
- Context: Windows / Linux / macOS / WSL / SSH에서 동일 Config 사용 목표
- Decision: Shell, Path, Package Manager 등 OS 분기는 별도 Platform Layer에만 둠 (정확한 파일 구조는 구현 시 확정)
- Reason: OS 차이가 Config 전체로 퍼지는 것 방지
- Alternatives: OS별 별도 Config, 각 모듈 내부 분기
- Consequences: 공통 Config는 OS 중립적으로 작성해야 함
- Related Task: TASK-001
- Evidence: 사용자 프로젝트 설명 (2026-10-01)

### D-004: Config 전체를 Git Repository로 관리
- Date: 2026-10-01
- Status: Accepted
- Context: 새 장비에서 동일 환경을 빠르게 재구성해야 함
- Decision: Neovim Config 전체를 이 Repository에서 관리. 장기 목표는 `git clone` → install script → `nvim`
- Reason: 환경 재현성, 변경 이력 관리
- Alternatives: 수동 설정, 범용 dotfiles Repository의 일부로 관리
- Consequences: Config 경로 연결 방식(D-005)과 install script(Phase 13)가 필요
- Related Task: TASK-001
- Evidence: 사용자 프로젝트 설명 (2026-10-01)

### D-005: Windows에서 Junction으로 Repository를 config 경로에 연결
- Date: 2026-10-01
- Status: Accepted
- Context: Repository 위치(`Desktop\sb_git\sinbin_IDE`)와 Neovim 기본 config 경로(`%LOCALAPPDATA%\nvim`)가 다름
- Decision: `%LOCALAPPDATA%\nvim` → Repository Junction
- Reason: 관리자 권한 불필요, Repository 위치 유지, install script로 자동화 용이
- Alternatives: Repository를 config 경로로 이동/clone, `NVIM_APPNAME`
- Consequences: Junction 생성은 현재 수동. Linux/macOS 연결 방식은 Phase 12/13에서 결정
- Related Task: TASK-002
- Evidence: 사용자 선택 (2026-10-01), `stdpath('config')` 확인

### D-006: Config 모듈을 `lua/sinbin/` Namespace 아래 역할별로 분리
- Date: 2026-10-01
- Status: Accepted
- Context: Phase 1에서 `init.lua` → `lua/` 모듈 구조 결정 필요. 이후 Plugin이 추가되면 `lua/` 최상위 모듈명이 runtimepath 상 Plugin 모듈과 충돌할 수 있음
- Decision: 모든 Config 모듈을 `lua/sinbin/` 아래에 둠. 역할별 파일(`keymaps`, `options`, `platform/`)로 나누고, `init.lua`는 `require`만 수행. 내용 없는 모듈은 만들지 않음(Platform OS별 stub 제외 — 진입점이 로드하므로 필요)
- Reason: `config`, `options`, `platform` 같은 일반명의 Plugin 모듈과 충돌 방지. 진입점이 짧아 로드 순서가 한눈에 보임
- Alternatives: `lua/` 최상위에 직접 배치, `init.lua` 단일 파일
- Consequences: 새 모듈은 `require("sinbin.<name>")`. Leader는 Keymap/Plugin보다 먼저 설정되도록 `keymaps`를 가장 먼저 로드
- Related Task: TASK-003
- Evidence: `nvim --headless` 검증 (2026-10-01, TASK-003)

### D-007: Plugin Manager로 Neovim 내장 `vim.pack` 사용
- Date: 2026-10-01
- Status: Accepted
- Context: Phase 2 이후 Plugin 도입을 위해 Plugin Manager 필요. RULES Plugin 원칙(기본 기능 우선, 특정 Plugin 종속 금지)
- Decision: Neovim 0.12 내장 `vim.pack` 사용. Plugin 목록은 `lua/sinbin/plugins.lua`의 `vim.pack.add()` 한 곳에 두고, lock 파일 `nvim-pack-lock.json`(Repository Root)을 git으로 관리
- Reason: 추가 의존성 없음(git만 필요), Config가 `vim.pack.add()` 목록뿐이라 다른 Manager로 이전 쉬움, lock 파일이 Repository Root에 생겨 재현성(D-004) 확보
- Alternatives: lazy.nvim (성숙·Lazy loading·전용 UI, 단 bootstrap 필요하고 spec 형식에 Config가 묶이기 쉬움), mini.deps
- Consequences: 공식 문서상 experimental — Neovim 업데이트 시 API 변경 확인 필요. Lazy loading 내장 없음 → 필요 시 `:packadd`/autocmd로 직접 처리. 첫 설치 시 확인 prompt 표시(`confirm` 기본값 유지)
- Related Task: TASK-004
- Evidence: 사용자 선택 (2026-10-01), `:h vim.pack` (v0.12.5), 테스트 Plugin 설치·제거 검증 (TASK-004)

### D-008: 편집 보조 Plugin으로 mini 계열 개별 모듈 사용, Surround는 vim-surround 키
- Date: 2026-10-01
- Status: Accepted
- Context: Phase 2에서 괄호 자동 닫기와 Surround는 Neovim 내장 기능이 없어 Plugin 필요
- Decision: `nvim-mini/mini.pairs`, `nvim-mini/mini.surround`를 개별 repo로 `stable` branch 기준 설치. Surround 키는 `ys`/`ds`/`cs`(+ Visual `S`, `yss`)로 재매핑 (`:h MiniSurround-vim-surround-config`)
- Reason: 의존성 없음, 필요한 모듈만 설치 가능(`mini.nvim` 전체 묶음 불필요), 같은 계열이라 설정 방식 일관. `ys`/`ds`/`cs`는 가장 널리 쓰이는 키이고 내장 `s`를 덮어쓰지 않음
- Alternatives: `nvim-autopairs` + `nvim-surround` (기능 충분, 단 제작자·설정 방식이 각각 다름), mini.surround 기본 키 `sa`/`sd`/`sr` (내장 `s` 덮어씀)
- Consequences: 다른 mini 모듈(`mini.ai` 등)도 같은 방식으로 추가 가능. `stable` branch는 release 시점에만 갱신되므로 최신 기능은 늦게 반영됨. Surround 동작은 vim-surround와 완전히 같지는 않음(문서상 "closest, not identical")
- Related Task: TASK-005
- Evidence: 사용자 선택 (2026-10-01), mini.surround 문서, headless 동작 검증 (TASK-005)

### D-009: Search/Navigation과 기본 UI를 mini 계열 + tokyonight로 구성, Plugin 설정은 영역별 파일로 분리
- Date: 2026-10-01
- Status: Accepted
- Context: Phase 3 시작. 사용자는 직접 구성을 유지하되 UI를 빠르게 갖추길 원함. NvChad 등 설정 프레임워크는 lazy.nvim 전제·덮어쓰기 구조라 D-001/D-006/D-007과 충돌하여 채택 안 함
- Decision: 검색·탐색기는 `mini.pick`/`mini.extra`/`mini.files`, 기본 UI는 `mini.icons`/`mini.statusline`/`mini.clue`/`mini.notify`/`mini.starter` (모두 `stable`). Colorscheme은 `folke/tokyonight.nvim` `moon` style. 내용 검색은 ripgrep. Plugin 목록은 `lua/sinbin/plugins/init.lua` 한 곳에 유지하고 설정은 `plugins/{ui,editing,search}.lua`로 분리. 기본 UI는 Phase 11에서 Phase 3으로 앞당김
- Reason: D-008과 같은 계열로 설정 방식 일관, 의존성 없음, 모듈 단위로 교체 가능. tokyonight moon은 사용자 요구(너무 어둡지 않은 네온 계열 다크, 눈 편안함)에 부합. 설정 파일 분리로 `plugins.lua` 비대화 방지, 목록은 한 곳이라 D-007 유지
- Alternatives: snacks.nvim (화려하나 큰 Plugin 하나에 기능 집중), fzf-lua/telescope, NvChad/LazyVim 등 프레임워크, 내장 `:find`/`:grep`만 사용. Colorscheme: catppuccin macchiato, nightfox duskfox, tokyonight storm
- Consequences: 아이콘 표시에 Nerd Font 필요. ripgrep은 외부 의존성 (설치 자동화는 Phase 13). Mode별 Layout 등 세부 UI는 Phase 11에 남음
- Related Task: TASK-006
- Evidence: 사용자 선택 (2026-10-01), headless 검증 (TASK-006)

### D-010: LSP는 내장 `vim.lsp` + nvim-lspconfig 설정, Server 설치는 mason.nvim, 자동완성은 mini.completion
- Date: 2026-10-02
- Status: Accepted
- Context: Phase 4. 대상 언어 TypeScript, Python, Java, Dart/Flutter, C. Neovim 0.12는 `vim.lsp.config` / `vim.lsp.enable`로 LSP Client를 내장
- Decision: LSP Client는 내장 기능을 쓰고, Server별 설정(cmd, root marker)은 `neovim/nvim-lspconfig`의 `lsp/*.lua`를 그대로 사용. Server 설치는 `mason-org/mason.nvim` (`:MasonInstall`), Dart는 SDK 포함 Server 사용. 자동완성은 `mini.completion` (snippet은 내장 `vim.snippet`). Server: `vtsls`, `basedpyright` + `ruff`(ruff hover 비활성), `jdtls`, `dartls`, `clangd`. LSP Keymap은 내장 기본값 + `gd`, `<Leader>cf`(+Code 그룹 신설)
- Reason: 내장 우선(RULES), 설정 데이터만 쓰므로 lspconfig 제거 시 `lsp/*.lua` 직접 작성으로 대체 가능. Mason은 OS 공통 설치 방식이라 Phase 12/13에 유리. mini.completion은 D-008/D-009와 일관
- Alternatives: Server 직접 설치(npm/pip/winget), 내장 `vim.lsp.completion`, blink.cmp, ts_ls, pyright 단독, nvim-jdtls
- Consequences: Mason Server는 lock 파일 밖 (버전 고정 안 됨, Phase 13에서 설치 목록 자동화 필요). Windows에서 Flutter SDK의 확장자 없는 `dart` 스크립트 때문에 Platform Layer에서 `dart.bat` 지정. jdtls는 JDK 21+ 필요
- Related Task: TASK-007
- Evidence: 사용자 선택 (2026-10-02), 5개 언어 headless 검증 (TASK-007)

### D-011: Treesitter는 nvim-treesitter `main`으로 parser만 관리하고 강조는 내장 기능 사용
- Date: 2026-10-02
- Status: Accepted
- Context: Neovim 0.12.5 내장 parser는 c, lua, markdown, vim 등뿐이라 TypeScript, Python, Java, Dart 구문 강조에 parser 필요. nvim-treesitter `master`는 잠김(0.11 호환용), `main`은 Neovim 0.12+, `tree-sitter` CLI 0.26.1+, C compiler, tar, curl 필요
- Decision: `nvim-treesitter` `main` branch로 parser·query 설치 (`typescript`, `tsx`, `javascript`, `python`, `java`, `dart`, `json`, `yaml`, `toml`. `c`는 처음엔 내장 사용, TASK-014에서 추가 — 내장 query에 `locals`가 없어 디버그 virtual text가 안 됨). 강조는 FileType autocmd에서 parser가 있을 때만 내장 `vim.treesitter.start()`. Treesitter indent(experimental)와 folding은 사용 안 함. `tree-sitter` CLI는 winget 설치. vim.pack `PackChanged`(update) 시 `:TSUpdate`
- Reason: parser 빌드·버전 관리를 직접 하지 않기 위함. 강조 자체는 내장 기능이라 Plugin 의존이 parser 관리로 한정됨. indent는 공식 문서상 experimental이고 현재 내장 indent에 문제 없음
- Alternatives: Plugin 없이 `tree-sitter` CLI로 parser 수동 빌드, `master` branch, Treesitter indent/folding 사용
- Consequences: parser는 lock 파일 밖 (`stdpath('data')/site/parser`). 새 장비에 `tree-sitter` CLI와 C compiler 필요 (Phase 12/13). Plugin 업데이트 시 parser도 갱신해야 함 (autocmd로 처리)
- Related Task: TASK-008
- Evidence: 사용자 선택 (2026-10-02), nvim-treesitter README (main), headless 검증 (TASK-008)

### D-012: 진단 메시지는 표시 단계에서 규칙 기반 혼합 번역
- Date: 2026-10-02
- Status: Accepted
- Context: 언어 서버 한국어 번역은 vtsls·basedpyright만 지원하고 전체 번역이며, jdtls·clangd·dartls·ruff는 영어만. 사용자는 "쉬운 용어는 영어, 어려운 말은 한국어, 짧은 끝맺음" 혼합 스타일을 5개 언어 공통으로 원함
- Decision: 모든 서버에서 영어 원문을 받고, `vim.diagnostic.config()`의 `virtual_text.format` / `float.format`에서 첫 줄을 Lua pattern 규칙(`diagnostics/rules_ko.lua`)으로 치환. 줄 끝은 번역만, 메시지 창은 번역 + 원문. 규칙에 없으면 원문. picker·quickfix는 원문 유지. 이름 뒤에 고정 명사를 붙여 조사 오류 방지
- Reason: 서버와 무관하게 일관된 스타일, 진단 데이터 불변이라 다른 기능(quickfix, picker, code action)에 영향 없음, 원문 병기로 검색 가능. 외부 서비스 없음
- Alternatives: 서버 locale 설정(전체 번역, 2개 서버만), 한국어 번역 결과에 용어 치환, AI 번역, `publishDiagnostics` handler에서 메시지 자체 변경
- Consequences: 규칙에 등록된 메시지만 번역되므로 자주 보는 메시지를 계속 추가해야 함. 서버 업데이트로 원문이 바뀌면 해당 규칙은 원문으로 fallback (에러 아님)
- Related Task: TASK-010
- Evidence: 사용자 결정 (2026-10-02), 실제 수집 메시지 104개 전부 번역 확인 (TASK-010)

### D-013: Git은 gitsigns.nvim(버퍼 안) + diffview-plus(전체 변경 검토) + lazygit(전체 Git 작업)
- Date: 2026-10-02
- Status: Accepted
- Context: Phase 6. 주 작업이 Agent가 바꾼 코드의 Diff 확인(D-001). Neovim 내장 git 변경 표시 없음. 초안은 D-008/D-009 일관성을 위해 `mini.diff` + `mini.git`이었으나 사용자가 "최대한 사용자 친화적인 방법"을 기준으로 재검토 요청
- Decision: 버퍼 안 변경 표시·hunk 이동/미리보기 창/stage/reset·inline blame은 `lewis6991/gitsigns.nvim`. commit·push·브랜치·전체 변경 검토는 외부 CLI `lazygit`(winget)을 floating terminal로 실행(`<Leader>gg`). hunk·commit·branch 목록은 기존 `mini.extra` picker. 외부 수정은 내장 `checktime` autocmd로 반영. 여러 파일 변경 검토·파일 이력은 `dlyongemallo/diffview-plus.nvim`(sindrets/diffview.nvim의 유지보수 fork, 기본 branch)
- Reason: hunk 미리보기 창, 자동 inline blame, 메뉴·`?` 도움말·마우스가 있는 lazygit이 명령어 기반(`:Git ...`)보다 초보자에게 쉬움. `mini.statusline`은 `mini.git`이 없으면 gitsigns 정보를 사용하므로 상태바 연동 유지
- Alternatives: `mini.diff` + `mini.git` (일관성·최소 구성), vim-fugitive, sindrets/diffview.nvim (원본, 마지막 commit 2024-06으로 사실상 유지보수 중단)
- Consequences: mini 계열 일관성 일부 포기(제작자·설정 방식이 다른 Plugin 1개). lazygit은 외부 의존성 (설치 자동화는 Phase 13). Terminal 일반 UX는 Phase 7. diffview-plus의 tag(`v0.38`)는 semver가 아니라 vim.pack 버전 지정 불가 → 기본 branch 추적 (lock 파일로 revision 고정)
- Related Task: TASK-011
- Evidence: 사용자 선택 (2026-10-02), 임시 git 저장소 검증 (TASK-011)

### D-014: Terminal은 내장 `jobstart(term = true)` 기반 자체 모듈, Windows Terminal Shell은 Git Bash
- Date: 2026-10-02
- Status: Accepted
- Context: Phase 7. 하단 패널에서 dev server·test·git 명령을 실행하고, Phase 10에서 AI Agent CLI를 같은 방식으로 띄울 기반 필요. 'shell'이 nvim 실행 방법에 따라 달라짐 (Git Bash에서 실행 시 `$SHELL`의 bash, PowerShell/Windows Terminal에서 실행 시 `cmd.exe`)
- Decision: `lua/sinbin/terminal.lua` 자체 모듈 (약 150줄, Plugin 없음). 번호별 하단 split Terminal(`<Leader>tt`, `N<Leader>tt`), floating Terminal(`<Leader>tf`), 명령 실행용 floating(`run_float`, lazygit이 사용), 숨겨도 프로세스 유지. Terminal 모드 탈출은 `<C-q>` (`<Esc>`는 Claude Code·lazygit이 쓰므로 매핑 안 함). Windows Terminal Shell은 Platform Layer에서 Git Bash(`bash --login -i`, git.exe 위치에서 탐색)로 지정하고 전역 'shell'은 변경하지 않음
- Reason: 기능이 단순해 내장 API로 충분, lazygit floating 코드 공통화, Phase 10 Agent 실행에 재사용. Git Bash는 Linux/macOS와 같은 명령을 쓸 수 있어 "어떤 PC에서도 같은 조작" 목표에 맞음. 'shell'을 바꾸면 `:!`·`system()` 인용 규칙이 바뀌어 Plugin 동작에 영향 → Terminal에만 적용
- Alternatives: toggleterm.nvim, snacks.nvim terminal, PowerShell 5.1/7, cmd, 전역 'shell' 변경
- Consequences: Git이 없으면 'shell'로 fallback. `exepath("bash")`는 WSL launcher(`WindowsApps\bash.exe`)를 찾을 수 있어 git.exe 기준으로 탐색. Linux/macOS Terminal Shell 지정은 Phase 12
- Related Task: TASK-012
- Evidence: 사용자 선택 (2026-10-02), UI attach한 `nvim --embed` 시나리오 검증 (TASK-012)

### D-015: Run/Test는 자체 모듈로 프로젝트 감지 후 "run" Terminal에서 실행
- Date: 2026-10-02
- Status: Accepted
- Context: Phase 8. 언어(TypeScript/Node, Flutter/Dart, Java/Maven, Python, C)와 무관하게 같은 키로 실행·빌드·테스트. Windows에서 npm·mvn·flutter는 확장자 없는 shell script와 `.cmd`/`.bat`이 함께 있어 직접 spawn 시 dartls와 같은 문제 가능
- Decision: `lua/sinbin/run.lua` 자체 모듈. **파일 범위**(소문자 `<Leader>rr`/`rb`/`xf`, filetype별 명령)와 **프로젝트 범위**(대문자 `<Leader>rR`/`rB`, `<Leader>xx`, 현재 파일에서 가장 가까운 marker)를 키로 분리. 파일이 아닌 화면은 작업 폴더 기준, 작업 폴더에 marker가 없으면 한 단계 아래 하위 프로젝트를 `vim.ui.select`로 선택. mini.files `g.`로 작업 폴더 변경 (`gc`는 내장 주석 키·`<Leader>gc`와 혼동되어 변경). 실행 시 `▶ 명령 (폴더/)` 알림. 명령은 shell command line으로 만들어 `terminal.exec("run")`(전용 하단 Terminal, 출력 유지, 재실행 시 교체)에서 실행. Windows는 Platform Layer의 `terminal_exec`(`bash -c`)로 실행. 프로젝트별 덮어쓰기는 `<root>/.sinbin/run.json`(프로젝트 `run`/`build`/`test`, 파일 `run_file`/`build_file`/`test_file`, `{file}` 치환). Node 도구는 `packageManager` 필드 → lock 파일 중 설치된 도구 → npm 순. 빌드 에러 quickfix 연동은 보류
- Reason: Terminal 모듈(D-014)에 감지·명령 선택만 추가하면 됨. overseer.nvim은 현재 필요(단일 실행·재실행·중지)보다 큼. bash 경유로 OS·도구별 실행 파일 차이를 Platform Layer에 격리
- Alternatives: overseer.nvim, 내장 `:make` + `:compiler` + quickfix, neotest (테스트 단위 UI), 범위 구분 없는 단일 `<Leader>rr` (초기 구현, 사용자가 "모호하다"고 보고해 분리)
- Consequences: 감지 규칙은 run.lua에 직접 추가해야 함. `.sinbin/run.json`은 저장소의 명령을 키 입력 시 실행하므로 신뢰하는 저장소에서만 사용. Git Bash가 없으면 'shell'(cmd.exe)로 실행되어 sh 인용이 맞지 않을 수 있음 (Phase 12)
- Related Task: TASK-013
- Evidence: 사용자 선택 (2026-10-02), 샘플 프로젝트 감지·실행 검증 (TASK-013)

### D-016: Debug는 nvim-dap + nvim-dap-view, adapter는 실제 실행 파일로 직접 실행
- Date: 2026-10-02
- Status: Accepted
- Context: Phase 9. Neovim에 디버거 내장 없음. 5개 언어(C, Python, TypeScript/Node, Dart/Flutter, Java) 디버깅. Windows에서 Mason의 `.cmd` shim과 Flutter SDK의 `.bat`/확장자 없는 script는 nvim-dap(libuv spawn)에서 이름으로 찾지 못하거나, 찾아도 cmd.exe를 거치며 DAP stdio 통신이 되지 않음(`initialize` 응답 없음)
- Decision: DAP client `mfussenegger/nvim-dap`, UI `igorlfs/nvim-dap-view`(하단 패널 하나, `auto_toggle`, 내장 virtual text를 줄 끝 `eol`로 사용 → nvim-dap-virtual-text 미사용). Adapter: C `gdb -i dap`(MSYS2 gdb 16.2 내장 DAP, 현재 파일을 `gcc -g -O0`로 컴파일), Python debugpy(Mason venv의 python으로 `-m debugpy.adapter`), Node js-debug(`node dapDebugServer.js`), Dart `dart.exe debug_adapter`, Flutter `dart.exe --packages=... flutter_tools.snapshot debug_adapter`, Java java-debug bundle을 jdtls `init_options.bundles`에 넣고 jdtls 명령(`startDebugSession`, `resolveMainClass`, `resolveClasspath`)으로 실행. OS별 경로(`exe_suffix`, `venv_bin`, `dart_exe`, `flutter_cmd`)는 Platform Layer. `.vscode/launch.json`은 nvim-dap 기본 지원. Keymap `<Leader>d*` + F5/F10/F11/F12
- Reason: nvim-dap이 사실상 표준이고 adapter 선택이 자유로움. dap-view는 하단 패널 하나라 Terminal Layout과 맞고 virtual text까지 포함(중복 Plugin 회피, RULES). 실제 실행 파일 직접 실행이 Windows에서 유일하게 안정적으로 동작. gdb 내장 DAP와 SDK adapter는 추가 설치 불필요
- Alternatives: nvim-dap-ui(+nvim-nio), nvim-dap-virtual-text, codelldb/cpptools(C), nvim-jdtls(Java), Mason shim을 그대로 adapter command로 사용(동작 안 함)
- Consequences: Mason 패키지 내부 경로(debugpy venv, js-debug `dapDebugServer.js`, java-debug jar)와 Flutter SDK 내부 구조(`flutter_tools.snapshot`)에 의존 → 패키지·SDK 구조가 바뀌면 경로 수정 필요. Java는 jdtls가 프로젝트를 불러온 뒤에만 시작 가능. java-debug bundle은 jdtls 시작 시 적용되므로 설치 후 nvim 재시작 필요. 브라우저(Chrome) 프론트엔드 디버깅은 범위 밖
- Related Task: TASK-014
- Evidence: 사용자 선택 (2026-10-02), 5개 언어 + Flutter Windows 앱 디버그 검증 (TASK-014)

### D-017: AI Agent는 오른쪽 세로 Terminal에서 CLI 그대로 실행, 파일 위치는 `@경로#L` 텍스트로 전달
- Date: 2026-10-02
- Status: Accepted
- Context: Phase 10. Claude Code와 Codex CLI를 함께 사용. D-002에 따라 Agent를 Neovim Core에 내장하지 않음. Claude Code 공식 IDE 연동의 Neovim 구현(`coder/claudecode.nvim`, 선택 공유·diff 수락)이 있으나 Claude 전용
- Decision: `lua/sinbin/agent.lua`가 `terminal.lua`의 오른쪽 세로 창(화면 40%, 최소 60열)으로 `claude` / `codex`를 실행·토글(숨겨도 세션 유지, 현재 파일의 git root에서 시작). 현재 파일·선택 줄은 `@상대경로#L10-20 `을 입력창에 키 입력으로 넣고 Enter는 누르지 않음(질문을 이어서 입력). 결과 검토는 기존 `checktime`·`<Leader>gv`·hunk 기능 사용. claudecode.nvim은 보류
- Reason: 두 Agent를 같은 방식으로 다룸, Agent 교체·추가가 명령 이름 한 줄. 하단은 run Terminal·디버그 패널이 쓰고 Agent 화면은 폭이 필요. `@`는 두 Agent 모두 파일 참조 표기
- Alternatives: claudecode.nvim (Claude 전용 IDE 프로토콜), avante.nvim·codecompanion 등 Neovim 내장형 (D-002 위반), 하단·floating 배치, `경로:10-20` 형식
- Consequences: Agent가 제안하는 수정을 diff로 수락/거절하는 IDE식 기능은 없음 (Agent CLI 자체 확인 흐름 사용). Claude 전용 기능이 필요하면 claudecode.nvim을 추가 검토. Codex는 폴더별 첫 실행 시 신뢰 확인 화면이 나옴
- Related Task: TASK-015
- Evidence: 사용자 선택 (2026-10-02), Claude Code·Codex 실제 실행 검증 (TASK-015)

### D-018: VS Code식 배치를 자체 layout 모듈로 — 탭 bufferline, Outline aerial, 탐색기는 mini.files 유지
- Date: 2026-10-06
- Status: Accepted
- Context: Phase 11. 사용자 방향 "VS Code와 비슷한 배치, 키는 Vim 방식". 오른쪽 Agent 창(40%)이 이미 폭을 씀. 검토 후보: 상시 파일 트리 nvim-tree·neo-tree, 탭 mini.tabline·bufferline, 창마다 탭 바(VS Code editor group), 패널 고정 edgy.nvim, Outline aerial.nvim·outline.nvim·자체 구현
- Decision: 배치 = 왼쪽 Outline(필요할 때) / 위쪽 탭 바 하나 / 코드 창(내장 분할, 창마다 winbar 경로) / 하단 패널(코드 아래에만, Terminal·Run 탭 한 창 + 디버그 패널 옆) / 오른쪽 Agent / 화면 전체 상태바 한 줄. 자체 `layout.lua`가 새 창 뒤 양쪽 열을 `<C-w>H`/`L`로 보정. 탭은 `akinsho/bufferline.nvim`(진단·닫기 버튼·순서 이동·고정·글자 선택), 탭 닫기는 창을 유지하는 자체 함수. 탐색기는 상시 트리 없이 mini.files 유지 + 자체 Git 상태 표시. Outline은 `stevearc/aerial.nvim`(LSP + Treesitter fallback, 모든 symbol kind, 현재 창 따라감), mini.files와 같은 왼쪽 영역을 번갈아 씀. 프로젝트 전체 심볼은 별도 picker
- Reason: 상시 트리는 Agent 창과 함께면 코드 창이 좁고 `<Leader>ff`/`fr`과 역할 중복 (사용자 결정). 창마다 탭 바는 검토 후 사용자가 위쪽 한 줄 선택. bufferline은 mini.tabline에 없는 VS Code식 기능 (사용자 결정). aerial은 요구 조작(`j`/`k`, `h`/`l`, `<CR>`)이 기본값, 최근까지 유지보수, 의존성 없음. edgy.nvim 없이 기존 `terminal.lua` 규칙 확장으로 충분
- Alternatives: nvim-tree(설치 후 되돌림), neo-tree(nui·plenary 필요), mini.tabline(bufferline 실패 시 대안), 창마다 탭 바 자체 구현, edgy.nvim, outline.nvim, Outline 자체 구현
- Consequences: bufferline 마지막 push 2025-01-14(v4.9.1) — 고쳐지지 않는 버그 위험 (2026-10-06 Neovim 0.12.5 동작 확인, 깨지면 mini.tabline으로 교체). mini 계열 예외 2개 추가(bufferline, aerial). mini.files는 floating이라 Outline과 진짜 sidebar 창을 공유하지 않음(같은 왼쪽 자리에 번갈아). `MiniIcons.tweak_lsp_kind()`가 SymbolKind 이름에 아이콘을 붙여 aerial highlight 이름 에러(E5248) → SymbolKind만 원래 이름으로 되돌림. aerial 내부 함수 2개를 감쌈 (`aerial.window.get_symbol_position`: 강조·커서를 커서가 든 가장 안쪽 심볼로 — 기본값은 커서 위쪽 마지막 심볼이고 `def` 줄 이름 왼쪽은 이전 심볼로 계산됨, `aerial.util.render_centered_text`: 심볼 없음 안내를 한 줄로) → aerial 업데이트 시 동작 재확인 필요
- Related Task: TASK-016
- Evidence: 사용자 결정 (2026-10-06), UI attach한 `nvim --embed` RPC 검증 (TASK-016)

### D-019: 창 이동은 "열기 / 이동 / 숨기기" 한 키 규칙 + Alt+h/j/k/l, VS Code 단축키는 Terminal이 전달하는 것만
- Date: 2026-10-06
- Status: Accepted
- Context: Phase 11 2·3단계. TASK-015 인계: 토글 키가 보이는 창을 숨김, Terminal에 `<C-w>`·마우스로 들어가면 입력 모드가 아님, 임시 `Alt+a`. Windows Terminal 1.24 기본 key binding 확인: `Ctrl+Shift+P`(명령 팔레트), `Ctrl+Shift+F`(찾기, 사용자 설정에도 있음), `Alt+화살표`(pane 이동). `Ctrl+P`/`Ctrl+B`/`` Ctrl+` ``/`Alt+h/j/k/l`은 미지정
- Decision: 영역 키(`<Leader>tt`/`tp`/`ac`/`ax`/`co`/`du`)는 숨김 → 열고 이동, 다른 창에서 → 이동, 그 창에서 → 숨김. Terminal 창에 들어가면(WinEnter/BufEnter, schedule) 입력 모드, 끝난 Run 결과는 제외. 창 이동은 Normal·Terminal 모드 `Alt+h/j/k/l`. `Alt+a`(코드 ↔ Agent) 유지. VS Code 키: `Ctrl+P` 파일 찾기, `Ctrl+B` 왼쪽 영역(마지막 사용) 채택, 하단 패널은 `` Alt+` `` (`` Ctrl+` ``는 Windows Terminal이 아무것도 보내지 않음, 2026-10-06 사용자 확인). `Ctrl+Shift+P`/`Ctrl+Shift+F`는 Windows Terminal이 가져가므로 채택 안 함 (Leader 키 `<Leader>sc`/`sg` 사용)
- Reason: 보이는 창을 숨기지 않아 "다시 누르기"가 필요 없음. `Ctrl+h/j/k/l`은 Terminal 안 프로그램(shell backspace·clear, lazygit)이 써서 Alt 사용. Windows Terminal 설정 변경 없이 동작하는 키만
- Alternatives: `<C-h/j/k/l>` 창 이동, Windows Terminal에서 `Ctrl+Shift+P/F` binding 해제(사용자 Terminal 설정 변경 필요), 영역 키 단순 토글 유지
- Consequences: Normal `<C-p>`(=k)·`<C-b>`(한 화면 위로) 대체. Terminal 입력 중에는 Leader 키가 프로그램에 입력되므로 숨기기는 `<C-q>` 후 또는 `` Alt+` `` / `Alt+a`
- Related Task: TASK-016
- Evidence: Windows Terminal `defaults.json`·`settings.json` 확인, UI attach한 `nvim --embed` RPC 검증 (2026-10-06)

### D-020: 상태바는 VS Code식 색 구역 + pull/push, 오른쪽 영역은 탭 창 하나로 시작 시 일반 Terminal
- Date: 2026-10-06
- Status: Accepted
- Context: 사용자 테스트 피드백 — 상태바가 이전과 달라 보이지 않음(내용만 바뀌고 모양은 mini.statusline 기본), pull/push 표시 없음, 시작 시 오른쪽 창을 Agent가 아닌 Terminal로
- Decision: 상태바는 VS Code 상태바 형식 (2026-10-06 사용자 피드백 2차: 색 구역 방식은 가시성 낮음): 한 배경에 codicon 아이콘 항목을 넓게 띄움 — 모드(진한 배경 + 흰 굵은 글자) · 브랜치(`*` = 커밋 안 한 변경, `git status --porcelain`) · pull/push `0↓ 1↑`(`git rev-list --left-right --count @{upstream}...HEAD`, 로컬 ref 기준, 자동 fetch 안 함, upstream 없으면 `publish`) · 에러/경고(항상, 0 포함) · 작업 폴더 / 실행 중 배지 Run·Debug·Agent · `Ln, Col` · 파일 타입. 디버그 중 상태바 전체 주황. 변경 줄 수는 뺌. 오른쪽 영역은 하단 패널처럼 창 하나 + winbar 탭(Terminal·Claude Code·Codex), 시작 시(VimEnter, UI 있을 때) 일반 Terminal을 커서 이동 없이 엶. `Alt+a`는 오른쪽 영역 왕복, `<Leader>at` 오른쪽 Terminal
- Reason: 사용자 결정. VS Code 상태바의 색 구역·동기화 표시와 같은 구성. Agent를 자동 실행하지 않아 시작 비용·세션 생성 없음. 오른쪽 영역도 하단 패널과 같은 탭 규칙이라 창이 늘지 않음
- Alternatives: 테마(tokyonight) 모드 색 유지, 구역마다 배경색(1차 구현, 가시성 낮아 교체), powerline 구분 기호, 자동 fetch(원격 접속 발생), Agent 창 여러 개 나란히, 시작 시 Agent 자동 실행
- Consequences: 상태바 색이 colorscheme을 바꿔도 따라가지 않음 (`statusline.lua`의 색 표). 받을 commit 수는 fetch/pull 전까지 갱신 안 됨. 시작할 때마다 오른쪽 Terminal(40%)이 열려 코드 창이 좁아짐 (`<Space>at`/`<C-q>` 후 숨김)
- Related Task: TASK-016
- Evidence: UI attach한 `nvim --embed`(시작 확인은 `--headless` 없이) RPC 검증 (2026-10-06)

### D-021: Terminal 영역에는 Terminal만, 탭 페이지는 배치에서 쓰지 않음
- Date: 2026-10-07
- Status: Accepted
- Context: 사용자 화면에서 오른쪽 영역(Terminal 자리)에 소스 파일이 들어가 배치가 깨짐, 탭 페이지 3개가 생겨 있었음. 재현: 커서가 오른쪽 Terminal·하단 패널(Normal 모드)에 있을 때 탭 클릭·`<Leader>ff`·mini.files·`<C-o>`로 파일이 그 창에 열림. 검색 창 `<C-t>` 한 번으로 탭 페이지가 생기고, 새 탭 페이지에는 시작 배치가 없음
- Decision: 하단 패널·오른쪽 영역 창에 Terminal이 아닌 버퍼가 들어오면(BufWinEnter) 그 버퍼를 마지막 코드 창(없으면 새 코드 창)으로 옮기고 영역에는 마지막 Terminal을 되돌림, 커서 위치 유지. mini.pick의 `<C-t>`(새 탭 페이지로 열기) 끔. 탭 페이지 표시·`:tabnew`·`<C-w>T`·diffview 탭 페이지는 그대로
- Reason: 사용자 결정 (검토 후 1·2번 대책). 경로마다 막는 대신 들어온 뒤 옮기면 모든 경로(Plugin 포함)에 적용됨. `'winfixbuf'`는 파일 열기가 에러로 끝나서 사용하지 않음
- Alternatives: `'winfixbuf'`(열기 실패 에러), 탭 페이지 번호 숨기기(존재를 알 수 없음), 새 탭 페이지마다 같은 배치(복잡, 이득 적음)
- Consequences: Terminal 영역에서 `<C-o>`는 코드 창의 이동처럼 동작. 명시적으로 만드는 탭 페이지(`:tabnew`, `<C-w>T`)에는 여전히 시작 배치 없음
- Related Task: TASK-016
- Evidence: UI attach한 `nvim --embed` RPC 재현·검증 (2026-10-07)

### D-022: 한/영 자동 전환은 IME 변환 모드를 직접 설정하는 컴파일된 도우미로
- Date: 2026-10-07
- Status: Accepted
- Context: TASK-017. 코드 창 진입 시 한글이면 영어로. 조건: Microsoft Korean IME 유지(키보드 레이아웃 전환 금지), polling 없음. Neovim은 Windows Terminal 안에서 실행되어 IME는 다른 프로세스(Windows Terminal) 소속
- Decision: 전경 창의 기본 IME 창에 `WM_IME_CONTROL`로 변환 모드를 읽고 한글(`IME_CMODE_NATIVE`)일 때만 그 비트를 끔. C# 도우미를 처음 쓸 때 Windows 기본 `.NET Framework csc.exe`로 빌드. 코드 창 진입(WinEnter/BufEnter)에 비동기 실행, Neovim focus 중·터미널 UI·전경 프로세스가 터미널일 때만
- Reason: 사용자 선택 A. `VK_HANGUL` 키 흉내는 키가 두 번 들어가거나 그 사이 바뀐 전경 창으로 갈 수 있음. 매번 PowerShell(`Add-Type`) 실행은 0.5~1초, 도우미 exe는 약 0.1초
- Alternatives: `VK_HANGUL` 입력(사용자 B안), ENG 레이아웃 전환(im-select 류, 요구사항 위반), PowerShell 상주 프로세스, 미리 빌드한 exe를 저장소에 포함
- Consequences: Windows 전용 (Platform Layer, 다른 OS는 동작 없음). 도우미 빌드 산출물은 저장소 밖(`stdpath("data")`). 터미널 목록 밖 프로그램(예: 다른 GUI 터미널)에서는 동작 안 함. 새 장비 설치(Phase 13)에서 첫 실행 시 자동 빌드
- Related Task: TASK-017
- Evidence: 빌드·상태 읽기·전경 프로세스 제한 확인 (2026-10-07), 실제 전환은 사용자 확인 필요


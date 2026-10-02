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
- Decision: `nvim-treesitter` `main` branch로 parser·query 설치 (`typescript`, `tsx`, `javascript`, `python`, `java`, `dart`, `json`, `yaml`, `toml`. `c`는 내장 사용). 강조는 FileType autocmd에서 parser가 있을 때만 내장 `vim.treesitter.start()`. Treesitter indent(experimental)와 folding은 사용 안 함. `tree-sitter` CLI는 winget 설치. vim.pack `PackChanged`(update) 시 `:TSUpdate`
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

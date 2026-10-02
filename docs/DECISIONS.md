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

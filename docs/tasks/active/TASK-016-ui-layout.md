# TASK-016: Phase 11 Custom UI / Layout — VS Code식 기본 배치

- **Status:** Active (2026-10-02)
- **Goal:** VS Code와 비슷한 화면 배치(왼쪽 파일 트리, 위쪽 탭, 하단 통합 패널, 오른쪽 Agent, 경로 표시)를 기본으로 만들고, 사용자가 써 보며 커스터마이징할 출발점을 만든다. 조작 키는 기존 Vim 방식(`<Space>` Leader)을 유지한다.

## Background
PROGRESS Next Action. 사용자 방향 (2026-10-02): "UI를 VS Code와 유사하게 만든 다음 거기서 커스터마이징". 의견 검토 후 합의: **배치는 VS Code식, 키는 Vim 방식 유지 + 충돌 없는 VS Code 단축키 몇 개만**.
PROJECT 목표 Layout(탐색기 / 코드 / 진단·심볼·Git / 하단 Terminal·Agent·Test)이 원래 VS Code 배치와 거의 같음.

### TASK-015에서 넘겨받은 것
- 창 이동 체계 재설계: 임시 `Alt+a` 왕복 키, `<Leader>a*` 토글이 보이는 창을 숨기는 문제, 마우스·`<C-w>`로 Terminal에 들어가면 입력 모드가 아닌 문제

### 현재 상태 (2026-10-02 확인)

| VS Code | 지금 |
|---|---|
| 왼쪽 파일 트리 (항상 보임) | `mini.files` — floating, 열고 닫는 방식 |
| 위쪽 파일 탭 | 없음 (`<Leader>fb` 버퍼 picker) |
| 하단 패널 (Terminal·Problems·Output·Debug) | Terminal(`<Leader>tt`), run Terminal, 디버그 패널(dap-view)이 각자 하단에 열림 |
| 오른쪽 보조 사이드바 | Agent 창 (TASK-015) |
| 경로 표시 (breadcrumbs) | 없음 |
| 명령 팔레트 | mini.pick (명령 목록 picker 없음) |
| 상태바 | mini.statusline |

### Plugin 후보 상태 (2026-10-02, GitHub)

| 용도 | 후보 | 최근 push | 비고 |
|---|---|---|---|
| 파일 트리 | `nvim-tree/nvim-tree.lua` | 2026-10-02 | 의존성 없음 (아이콘은 mini.icons로 대체 가능) |
| 파일 트리 | `nvim-neo-tree/neo-tree.nvim` | 2026-09-27 | nui.nvim·plenary.nvim 필요, Git·버퍼 보기 등 기능 많음 |
| 탭 | `nvim-mini/mini.tabline` | 2026-07-07 | mini 계열(D-008/D-009)과 일관, 가벼움 |
| 탭 | `akinsho/bufferline.nvim` | 2025-01-14 | 기능 많음, 최근 1년 넘게 push 없음 |
| 패널 고정 | `folke/edgy.nvim` | 2025-10-28 | 창 위치·크기 고정 관리 |

## Scope

### 1단계: VS Code식 기본 배치
| 영역 | 내용 |
|---|---|
| 왼쪽 사이드바 | 파일 트리 (Decisions 1). 파일 열기·만들기·이름 바꾸기·삭제, Git 상태 표시, 현재 파일 위치 따라가기, 작업 폴더 변경(`g.` 대응) |
| 위쪽 탭 | 열린 파일(버퍼) 탭 (Decisions 2) |
| 하단 패널 | Terminal·run·디버그 패널이 같은 하단 영역을 쓰도록 정리 (Decisions 3) |
| 오른쪽 | Agent 창 (기존 유지) |
| 경로 표시 | 코드 창 위 winbar에 파일 경로 (내장 기능) |
| 명령 팔레트 | 명령·Keymap 검색 picker |

### 2단계: 창 이동 체계 (TASK-015 인계)
- 사이드바·패널·Agent를 키 하나로 열기/닫기/이동하는 규칙 통일 (보이는 창은 숨기지 않고 이동, 그 창에 있을 때만 숨김)
- Terminal 창에 들어가면 자동으로 입력 모드
- 임시 `Alt+a` 정리 (유지 / 새 체계로 대체)

### 3단계: VS Code 단축키 일부 (Decisions 4)
- 충돌이 없고 Terminal이 전달하는 것만. 각 키는 Windows Terminal에서 실제로 Neovim까지 오는지 확인 후 채택

## Out of Scope (이 Task 이후)
- 목적별 Mode 전환 (Coding / Debug / Git / AI / Focus) → 기본 배치가 자리 잡은 뒤 별도 Task
- 색 테마·아이콘 세부 커스터마이징 → 사용자가 써 보며 요청
- 심볼 기반 breadcrumbs (LSP 심볼 경로) → 필요 시

## Prerequisites
- TASK-006 (mini 계열 UI), TASK-012 (`terminal.lua`), TASK-014 (dap-view), TASK-015 (Agent 창)

## Decisions (2026-10-02 사용자 확인 — 추천안)
1. **파일 트리:** `nvim-tree/nvim-tree.lua` (의존성 없음, 아이콘은 mini.icons의 `mock_nvim_web_devicons()`로). **`mini.files`는 제거** (탐색기 중복, RULES). 탐색기의 작업 폴더 변경(`g.`)·`<Leader>fe` 기능은 nvim-tree로 옮김
2. **탭:** `mini.tabline` (mini 계열 일관, bufferline은 2025-01 이후 push 없음)
3. **패널 고정 방식:** 자체 layout 모듈 (`terminal.lua` 확장 또는 `lua/sinbin/layout.lua`). edgy.nvim은 사용 안 함
4. **VS Code 단축키:** 후보 5개 모두 시도하되 **Windows Terminal에서 Neovim까지 실제로 전달되는 것만 채택** — `Ctrl+P` 파일 찾기, `Ctrl+B` 왼쪽 사이드바, ``Ctrl+` `` 하단 패널, `Ctrl+Shift+P` 명령 팔레트, `Ctrl+Shift+F` 내용 검색. 전달 안 되는 키는 채택하지 않고 기록
5. **시작 화면:** 파일 트리 자동으로 열기 (VS Code처럼). 시작 화면(mini.starter)과의 관계는 구현 시 확인 (트리 + 시작 화면 / 트리 + 빈 편집 창)
6. **진행 순서:** 1단계(기본 배치) → 2단계(창 이동 체계) → 3단계(VS Code 단축키). **단계마다 사용자 화면 확인** 후 다음 단계

### 다음 세션 시작 지점
- 브랜치: `feat/ui-layout` (main `ce89052` 기준, 이 Task 문서와 PROGRESS 변경만 있음)
- 1단계부터:
  1. `nvim-tree.lua`, `mini.tabline` 추가 (`plugins/init.lua`, 한 줄 이유), 설치 출력 전체 확인 (`tail`로 자르지 말 것)
  2. `mini.files` 제거: `plugins/init.lua` 목록 + `vim.pack.del({"mini.files"})`, `plugins/search.lua`의 mini.files 설정·`g.` autocmd·`<Leader>fe`를 nvim-tree로 이전, USAGE 탐색기 섹션 갱신
  3. 하단 영역 정리: Terminal(`<Leader>tt`)·run Terminal·dap-view가 같은 하단 위치·높이를 쓰도록 (`terminal.lua` `open_window`의 split 규칙 공통화)
  4. winbar 경로 표시, 명령 팔레트(명령·Keymap picker: mini.extra `commands`/`keymaps` picker 후보)
  5. 시작 시 트리 자동 열기
- 검증 방식: UI attach한 `nvim --embed --headless -n` RPC (VERIFICATION 주의사항), 창 배치(위치·크기) 확인, 기존 기능 회귀(검색·LSP·Git·Run·Debug·Agent)
- 주의: Nerd Font 아이콘을 코드에 직접 쓸 때는 Python `\u` escape (Write 도구가 Private Use Area 문자를 지움)

## Steps
1. Decisions 확인
2. 1단계 구현·검증 → 사용자 화면 확인
3. 2단계 구현·검증 → 사용자 화면 확인
4. 3단계 (단축키 전달 확인 포함)
5. 문서 갱신: USAGE(배치·조작법 전면 갱신), ARCHITECTURE, DECISIONS(D-018~), PROJECT, PROGRESS

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- 사이드바·탭·하단 패널·Agent·경로 표시가 정해진 자리에 열리고, 열고 닫아도 배치가 흐트러지지 않음
- 기존 기능(검색, LSP, Git, Run, Debug, Agent) 회귀 없음
- 새 단축키는 Windows Terminal에서 실제 동작 확인된 것만, 기존 Keymap과 충돌 없음
- 사용자 화면 확인

## Related Files
`lua/sinbin/plugins/init.lua`, `lua/sinbin/plugins/ui.lua`, `lua/sinbin/plugins/search.lua`, `lua/sinbin/terminal.lua`, `lua/sinbin/agent.lua`, `lua/sinbin/plugins/debug.lua`, `lua/sinbin/layout.lua`(신규 예정), `nvim-pack-lock.json`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/PROJECT.md`

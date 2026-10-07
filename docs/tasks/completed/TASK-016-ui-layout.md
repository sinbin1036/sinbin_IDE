# TASK-016: Phase 11 Custom UI / Layout — VS Code식 기본 배치

- **Status:** Done (2026-10-07) — PR #15 merge, 남은 화면 항목 사용자 확인 완료 (2026-10-07)
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
| 파일 탐색 | mini.files 유지 + Git 상태 표시 (Decisions 1) |
| 위쪽 탭 | 열린 파일(버퍼) 탭 (Decisions 2) |
| 하단 패널 | Terminal·run·디버그 패널이 같은 하단 영역을 쓰도록 정리 (Decisions 3) |
| 오른쪽 | Agent 창 (기존 유지) |
| 경로 표시 | 코드 창 위 winbar에 파일 경로 (내장 기능) |
| 명령 팔레트 | 명령·Keymap 검색 picker |

### 2단계: 창 이동 체계 (TASK-015 인계)
- 패널·Agent를 키 하나로 열기/닫기/이동하는 규칙 통일 (보이는 창은 숨기지 않고 이동, 그 창에 있을 때만 숨김)
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

## Decisions (2026-10-02 사용자 확인 — 추천안, 2026-10-06 1·2·5 변경)
1. **파일 탐색:** ~~nvim-tree~~ → **`mini.files` 유지, 상시 트리 없음** (2026-10-06 사용자 결정). 이유: 오른쪽 Agent(40%)와 상시 트리가 함께 있으면 코드 창이 좁음, `<Leader>ff`/`fr`과 역할 중복. 대신 **mini.files에 Git 상태 표시** 추가 (`lua/sinbin/files_git.lua`, 구현됨): 이름 색 + 오른쪽 끝 글자 `M`/`A`/`U`/`R`/`!`, 변경을 포함한 폴더는 `•`. 상시 트리는 나중에 필요하면 왼쪽 열만 추가
2. **탭:** **위쪽 탭 바 하나, `akinsho/bufferline.nvim` 먼저 시도 → 0.12.5에서 에러가 나고 해결이 안 되면 `mini.tabline`으로** (2026-10-06 사용자 결정). 채택 이유: 탭별 진단 표시, 닫기 버튼, 순서 이동·고정, 글자로 탭 고르기 (mini.tabline에 없음). 위험: 마지막 push 2025-01-14 (v4.9.1, 2026-10-06 확인, archived 아님, open issue 105) → Neovim 0.12.5 동작이 구현 첫 검증 항목. 아이콘은 mini.icons `mock_nvim_web_devicons()`. mini 계열 예외 1개 추가 (구현 시 DECISIONS 기록). 창마다 탭 바(B)는 검토 후 기각. 코드 창 여러 개는 내장 창 분할, 경로 표시는 코드 창 winbar
3. **패널 고정 방식:** 자체 layout 모듈 (`lua/sinbin/layout.lua`). edgy.nvim은 사용 안 함
4. **VS Code 단축키:** 후보 5개 모두 시도하되 **Windows Terminal에서 Neovim까지 실제로 전달되는 것만 채택** — `Ctrl+P` 파일 찾기, ~~`Ctrl+B` 왼쪽 사이드바~~ (트리 없음 → 재검토), ``Ctrl+` `` 하단 패널, `Ctrl+Shift+P` 명령 팔레트, `Ctrl+Shift+F` 내용 검색. 전달 안 되는 키는 채택하지 않고 기록
5. **시작 화면:** ~~트리 자동 열기~~ → 트리가 없으므로 **기존 시작 화면(mini.starter) 유지**
6. **진행 순서:** (2026-10-06 사용자 지시: 단계별 확인 없이 1~3단계 전체 개발 후 사용자가 전체 테스트) **설계 확정 → 사용자가 "구현" 지시 → 구현** (2026-10-06 사용자 지시: 구현 지시 전까지 설계만). 구현은 1단계(기본 배치) → 2단계(창 이동 체계) → 3단계(VS Code 단축키), 단계마다 사용자 화면 확인

## 레이아웃 설계 (2026-10-06 확정 — 구현 전)

```
┌─────────────────────────────────────┬──────────┐
│ a.lua  b.lua  c.lua  d.lua          │          │ ← 위쪽 탭 바 하나 (bufferline)
├──────────────────┬──────────────────┤          │
│ lua > a.lua      │ lua > c.lua      │  Agent   │ ← 창마다 경로 (winbar)
│ 코드 창 1        │ 코드 창 2        │ (오른쪽, │
│                  │                  │ 위아래   │
├──────────────────┴──────────────────┤  전체)   │
│ 하단 패널: Terminal / Run / Debug   │          │
└─────────────────────────────────────┴──────────┘
 상태바: mini.statusline       + 왼쪽 영역 (필요할 때): Files(mini.files floating) / Outline(split)
```

| 영역 | 내용 |
|---|---|
| 탭 바 | 위쪽 한 줄, 열린 파일(listed buffer) 전체. 모든 창 공유 |
| 코드 창 | 내장 창 분할로 여러 개 (`<C-w>v` / `<C-w>s`). 창마다 winbar에 파일 경로 |
| 하단 패널 | Terminal·Run·디버그 패널이 같은 자리·높이(화면 30%, 최소 8줄) |
| 오른쪽 | Agent 창 (너비 40%, 최소 60칸), 위아래 전체 |
| 파일 탐색 | mini.files floating (`<Leader>fe`) + Git 상태 |
| 명령 팔레트 | 명령·Keymap picker (mini.extra `commands`/`keymaps` 후보) |

### 왼쪽 영역: Files / Outline (2026-10-06 사용자 요청, 설계 — 플러그인 선택 확인 대기)
- **Outline:** 현재 파일의 LSP `textDocument/documentSymbol`을 계층(클래스 > 메서드 > 변수…)으로 보여 주는 **왼쪽 sidebar 창** (split, 위아래 전체, 너비 35칸 후보). 기본은 닫힘, 필요할 때 엶. 현재 파일이 바뀌면 따라 바뀌고, 커서 위치의 심볼 강조
  - 조작: `j`/`k` 이동, `h` 접기 / `l` 펼치기 (mini.files의 `h`/`l`과 같은 느낌), `<CR>` 그 위치로 점프 (코드 창으로)
  - LSP가 없는 파일은 "심볼 없음" 표시 (Treesitter fallback은 플러그인 선택에 따라)
- **Files:** mini.files 유지. **제약: mini.files는 floating이라 진짜 sidebar 창을 공유할 수 없음** → "왼쪽 영역"을 같은 자리로 맞춤: Files는 왼쪽 위에 뜨는 floating, Outline은 왼쪽 split
- **전환:** 왼쪽 영역에는 한 번에 하나만. `<Leader>fe` Files / `<Leader>co` Outline — 다른 쪽이 열려 있으면 닫고 같은 자리에 엶. 패널 안에서 바로 전환하는 키(`<Tab>` 후보)는 구현 시 mini.files·Outline 기본 키와 충돌 확인
- **배치 규칙:** Outline 열은 Agent처럼 위아래 전체, 하단 패널은 코드 아래에만 (layout 모듈이 `<C-w>H`로 보정)
- **프로젝트 전체 심볼은 별도 검색:** `<Leader>ss` workspace symbol picker (mini.extra `lsp` picker). Outline 패널에는 넣지 않음. 내장 `gO`(현재 파일 심볼 → location list)는 그대로
- Keymap 확인 (2026-10-06): `<Space>co`, `<Space>ss` 비어 있음 (`<Leader>c`에는 LSP attach 시 `cf`만)
- **플러그인 후보 (2026-10-06 GitHub):**

| 후보 | 최근 push | 비고 |
|---|---|---|
| `stevearc/aerial.nvim` (추천) | 2026-06-02 | LSP + Treesitter fallback, 계층·접기·커서 따라가기, 기본 키에 `h`/`l`/`<CR>` 있음, 의존성 없음 |
| `hedyhli/outline.nvim` | 2026-05-29 | LSP 중심, 기능 비슷 |
| 자체 구현 (`layout.lua` 옆 모듈) | — | 의존성 없음, documentSymbol 요청 → 트리 렌더·접기·점프 직접 작성 (200줄 이상 예상) |

### 하단 패널 · 탭 Keymap (Q1~Q3 확정, 2026-10-06 사용자 결정 — 추천안)
- **Q1 하단 패널 폭:** Agent 왼쪽, 코드 아래에만 (VS Code 기본). Agent 열은 위아래 전체
- **Q2 하단 패널 내용:** 한 자리(창 하나)에서 탭으로 전환 — Terminal 1·2…·Run. 패널 탭 바는 그 창 winbar. 디버그 패널(dap-view)은 자체 섹션 탭이 있어 디버그 중에만 하단 패널 옆에 따로
- **Q3 탭 Keymap:** 새 Leader 그룹 `<Leader>b` Buffer/Tab (2026-10-06 확인: `<Space>b*` 비어 있음 → PROJECT "Keymap 방향"에 추가)

| 키 | 동작 | 비고 |
|---|---|---|
| `]b` / `[b` | 다음 / 이전 탭 | 내장 `:bnext`/`:bprevious` 기본 매핑을 탭 바 순서로 대체 |
| `<Leader>bd` | 탭 닫기 (창 배치 유지) | 내장 `:bd`는 창까지 닫음 |
| `<Leader>bo` | 다른 탭 모두 닫기 | |
| `<Leader>bp` | 글자로 탭 고르기 | bufferline pick |
| `<Leader>bP` | 탭 고정 / 해제 | bufferline pin |
| `<Leader>b]` / `<Leader>b[` | 탭 순서 오른쪽 / 왼쪽으로 이동 | |
| 마우스 | 클릭 전환, `×` 클릭 닫기 | |

### 상태바 (Q4 확정, 2026-10-06 사용자 결정 — 정보는 적게, 가시성은 높게)
`laststatus=3` 화면 전체 한 줄, mini.statusline 유지·섹션 조정. (아래 `[아이콘]`은 Nerd Font 아이콘 자리)

```
 NORMAL │ [git] main +3 ~1 │ [err] 2 [warn] 1 │ [dir] sinbin_IDE        ▶ Run │ [agent] Claude │ python │ 12:5
```

| 위치 | 항목 | 표시 |
|---|---|---|
| 왼쪽 | 모드 · Git 브랜치+변경량 · 에러/경고 | 항상 |
| 왼쪽 끝 | 작업 폴더 이름 | 항상 |
| 오른쪽 | Run/Debug 상태 · Agent 상태 | 실행 중일 때만 |
| 오른쪽 | 파일 타입 · 커서 위치 | 항상 |
| 제거 | 파일 이름(winbar와 중복), LSP 이름·개수, 인코딩, 줄바꿈, 들여쓰기, 검색 결과 수 | — |

## 가시성 방향 (2026-10-06 사용자 결정)
- **아이콘:** 상태바의 Git 브랜치·에러·경고에 Nerd Font 아이콘 (코드에는 Python `\u` escape로 씀)
- **모드 색:** NORMAL / INSERT / VISUAL / REPLACE / COMMAND / TERMINAL마다 서로 확실히 구분되는 배경색. tokyonight의 mini.statusline 모드 색을 화면에서 확인 후, 구분이 약하면 직접 지정
- **mini.files Git 색:** 오른쪽 끝 글자(`M`/`U`…)만이 아니라 **파일 이름·폴더 이름 자체**에 상태 색 (현재 구현도 이름 전체에 색을 칠함 — 화면 확인 후 색이 약하면 `Changed`/`Added` 링크 대신 tokyonight 팔레트의 진한 색 직접 지정)

### 1단계 구현 결과 (2026-10-06)
- 추가: `bufferline.nvim`, `aerial.nvim` (기본 branch, lock 고정). 제거: `mini.tabline`(bufferline 동작 확인 후 `vim.pack.del`), nvim-tree(설치 후 되돌림)
- 새 파일: `layout.lua`, `statusline.lua`, `files_git.lua`, `plugins/sidebar.lua`(mini.files를 `search.lua`에서 이동 + aerial). 변경: `terminal.lua`(하단 패널 공유·탭·`job_running`), `ui.lua`, `search.lua`, `lsp.lua`, `debug.lua`, `agent.lua`(`running()`), `options.lua`(`laststatus=3`)
- 결정 (Outline): `stevearc/aerial.nvim` (2026-10-06 사용자 결정), 프로젝트 심볼 `<Leader>ss`는 `workspace_symbol_live` (빈 질의에 basedpyright가 결과를 안 줘서 `workspace_symbol`로는 picker가 안 열림)

### 검증 (2026-10-06, UI attach한 `nvim --embed --headless -n` + pynvim, 임시 Python 프로젝트)
- Startup 에러 없음, checkhealth ERROR 0, lock 파일 diff = aerial·bufferline 추가만, 새 Keymap 각 1개 정의 (`]b`/`[b`는 내장 `:bnext`/`:bprevious` 대체)
- **bufferline이 Neovim 0.12.5에서 동작** (탭 표시·진단 개수·`]b`·`<Space>bd`) → mini.tabline 대안 불필요
- winbar 경로 `src > app.py`, 상태바 `Normal | master +1 | proj | python | 1:1`, Run 실행 중 `▶ Run`·끝나면 사라짐, 디버그 정지 중 `Debug`
- 하단 패널: `<Space>tt` → `2<Space>tt`가 같은 창에서 탭 `Terminal 1  Terminal 2`, Run 결과도 같은 창 탭 `run: ...`
- 배치: Agent(오른쪽) + 하단 패널 → `row{ col{코드, 패널}, Agent }` (패널은 코드 아래에만). Outline 추가 → `row{ Outline, col{코드, 패널}, Agent }`
- Outline: LSP(basedpyright) 계층 `App > run > x, stop / main`, `h` 접기, `<CR>` 코드 이동, `<Tab>` Files↔Outline 양방향 전환
- 디버그(Python debugpy): breakpoint 정지 → dap-view가 하단 패널 오른쪽 절반(30/31열), 종료 시 dap-view만 닫힘. 하단 패널 없을 때는 코드 아래 전체 폭, Agent는 위아래 전체 유지
- 탭 닫기: 창 2개에서 `<Space>bd` → 창 2개 유지, 직전 파일 표시
- `<Space>sc` 명령 665개, `<Space>sk` Keymap, `<Space>ss` 입력 `ma` → `main` (Function), `<Space>fe` 탐색기
- mini.files Git: `M`/`U`/폴더 `•`, 이름 색 (headless)

### 구현 중 발견·수정
- `MiniIcons.tweak_lsp_kind()`(TASK-007)가 SymbolKind 이름에 아이콘을 붙여 aerial highlight 이름이 깨짐(E5248 반복, 기본 filter도 불일치) → `lsp.lua`에서 SymbolKind만 원래 이름으로 (완성 목록 아이콘은 유지)
- 상태바에서 `jobwait()`로 Run 상태를 보면 상태바 그리는 중에 TermClose autocmd가 실행돼 `checktime` E565 → exec 종료 flag로 변경
- dap-view를 하단 패널 옆에 열면 화면 너비 절반을 잡아 패널·Outline이 찌그러짐 → `terminal.size`를 패널 절반이 되게 계산

### 남은 것 (1단계)
- 사용자 화면 확인: 탭 바·상태바 색·아이콘, 모드 색 구분, mini.files Git 색 진하기, Outline 폭(35)
- 미검증: 실제 Agent(Claude/Codex) 실행 상태 표시 (테스트는 오른쪽 Terminal로 대신), 마우스 클릭(탭·패널 탭), 저장 안 된 파일 닫기 확인 창

### 2·3단계 구현 결과 (2026-10-06, [D-019](../../DECISIONS.md))
- 영역 키 규칙 "숨김 → 열고 이동 / 다른 창에서 → 이동 / 그 창에서 → 숨김": `<Leader>tt`·`ac`/`ax`/`aa`(`terminal.toggle`), `<Leader>tp`(새, 하단 패널 전체 — 다시 열면 마지막에 보던 Terminal), `<Leader>co`, `<Leader>du`
- Terminal 창에 들어가면 자동 입력 모드 (`terminal.lua` WinEnter/BufEnter, schedule, 끝난 Run 결과 제외)
- 창 이동 `Alt+h/j/k/l` (Normal·Terminal, `keymaps.lua`). `Alt+a` 유지 (임시 표기 삭제)
- VS Code 키: `Ctrl+P` 파일 찾기, `Ctrl+B` 왼쪽 영역(마지막 사용 Files/Outline), `` Ctrl+` `` 하단 패널. `Ctrl+Shift+P`·`Ctrl+Shift+F`는 Windows Terminal 1.24 기본 binding(명령 팔레트·찾기, `Ctrl+Shift+F`는 사용자 settings.json에도)이라 **채택 안 함**. `Alt+화살표`도 Windows Terminal pane 이동

### 2·3단계 검증 (2026-10-06, 같은 방식)
- `<Space>tt`: 열기(mode `t`) → `Alt+k` 코드로(mode `n`) → `<Space>tt` 패널로 이동(mode `t`) → `<C-q>` `<Space>tt` 숨김
- `2<Space>tt` → `<Space>tp`(보임) 이동 → `` Ctrl+` ``(Terminal 안) 숨김 → `<Space>tp` 다시 열림. `<C-w>j`로 Terminal에 들어가면 mode `t`, 끝난 Run 결과 창은 `nt` 유지
- 오른쪽 Terminal: `Alt+h`로 코드로, toggle(보임) → 이동. `<Space>co`: 열기 → 이동 → 닫기. `Ctrl+B`: 마지막 Outline 다시 열기 / 숨기기, Files 쓴 뒤에는 Files. `Ctrl+P` → Files picker. `<Space>du`: 이동 → 닫기. Outline `<Tab>` ↔ Files 양방향
- 회귀: 1단계 시나리오(배치·탭 닫기·Run 상태·디버그 정지·dap-view 위치) 재실행 통과, Startup 에러 없음, checkhealth ERROR 0
- **미검증 (사용자 확인 필요):** 실제 Windows Terminal에서 `` Ctrl+` ``(→ 안 옴, `` Alt+` ``로 교체)·`Alt+h/j/k/l`·`Ctrl+B`·`Ctrl+P`가 Neovim까지 오는지 (headless 검증은 Neovim 입력 단계부터), 마우스 클릭(탭·패널 탭·창 진입), 실제 Claude/Codex 상태바 표시, 저장 안 된 탭 닫기 확인 창

### QA (2026-10-06, 사용자 요청 — 같은 방식, 임시 git 프로젝트: 수정·추가·새 파일·새 폴더·이름 바뀜·삭제·에러 파일·Markdown·`%` 이름, git 밖 폴더)
34개 경우 (시작 방식 5, 탭 7, winbar 1, 하단 패널 3, 배치 7, Outline 3, mini.files 3, 상태바 2, 창 이동 1, 실제 Claude Code 1, lazygit 1) + 이전 시나리오 재실행. 최종 실행에서 에러·예외 0, Startup 에러 없음, checkhealth ERROR 0.

발견·수정:
| 문제 | 원인 | 수정 |
|---|---|---|
| Outline 강조가 커서를 따라가지 않음 (`def stop` 줄 → `x`) | aerial이 열까지 비교 + 이름 위치(selection_range) 기준 + 강조 행이 "커서 위쪽 마지막 심볼" | `post_parse_symbol`로 시작 열 0, `highlight_closest = false`, `get_symbol_position`을 감싸 가장 안쪽 심볼로. `<CR>` 이동은 이름 위치 그대로 |
| mini.files 이름에 Git 색이 안 보임 (글자만 색) | mini.files 이름 강조(우선순위 4096)가 Git 색(200)을 덮음, 수정 색 `Changed`가 기본 글자색과 비슷 | 우선순위 4200, 색을 테마의 진한 색으로 (수정 노랑 `DiagnosticWarn`, 추가·새 파일 초록 `String`, 충돌 빨강 `GitSignsDelete`), 글자는 굵게 |
| 저장 안 된 탭 닫기 확인에서 키 선택 불가 | 단축키가 한글(`&저장`) | `저장(&S)` / `버리기(&D)` / `취소(&C)` |
| `nvim .`에서 폴더 버퍼에 긴 경로 winbar·폴더 탭 | 폴더 버퍼도 일반 파일로 취급 | winbar·탭(bufferline `custom_filter`)에서 폴더 제외 |
| `:copen` 시 하단 패널이 12줄 → 2줄 | 새 창이 바로 위 패널 줄을 가져감 | 패널 높이 기억(열 때·사용자가 바꿀 때), 새 창 뒤 복원 |
| 마지막 코드 창 `:q` → Terminal이 가운데를 차지 | 남은 창이 사이드·패널뿐 | 빈 코드 창을 패널 위(또는 Outline 오른쪽 / Agent 왼쪽)에 다시 만듦. 한 번에 여러 창이 닫히는 `:only` 등은 제외 |
| Run 패널 탭 이름이 전체 명령줄 | `run: python 'C:/...'` | 패널 탭은 `Run` (명령은 Terminal 안·`<Leader>tl`에) |
| 심볼 없는 파일의 Outline에 aerial 진단 여러 줄 | aerial 기본 문구 | `심볼 없음` 한 줄 |
| 변경 없는 파일 상태바에 `-` | mini.statusline diff 기본 | 변경 있을 때만 `+1 ~2 -3` |

문제 아님 (확인): `nvim -d` 두 창 폭 40/119는 `--clean`에서도 같음 (headless 테스트에서 UI 크기 적용 전 창 생성). 화면을 줄이면 Agent 폭(64)은 유지되어 코드 창이 좁아짐 (VS Code처럼 크기 유지, 비율 재조정 안 함).

### 사용자 피드백 반영 (2026-10-06, [D-020](../../DECISIONS.md))
- 요청: 상태바가 달라 보이지 않음 → VS Code식 색 구역·진한 모드 색, pull/push 표시, 시작 시 오른쪽 창을 Agent가 아닌 Terminal로
- 구현: `statusline.lua` 전면 개편(자체 색 표, pull/push 비동기), 오른쪽 영역을 하단 패널처럼 창 하나 + 탭(`terminal.lua` `area_terms`/`area_winbar`, `layout.right_win`), 시작 시 오른쪽 Shell(`agent.lua` VimEnter, `background`), `Alt+a` 오른쪽 영역 왕복, `<Leader>at`
- 검증 (시작 확인은 `--headless` 없이 UI attach — headless에서는 VimEnter 시점에 UI가 없어 건너뜀):
  - 시작: `python(95) + terminal(64)`, 커서 코드 창 mode `n`, 오른쪽 탭 `Terminal`. 시작 화면도 Terminal과 함께 가운데 정렬 다시 맞춤. gitcommit에서는 안 열림
  - `<Space>ac` → 같은 창 탭 `Terminal  Claude Code`, 탭 클릭 1/2 → Terminal / Claude Code, Claude 종료 → `Terminal`만 남음. `Alt+a` 왕복
  - 상태바: 모드 배경 `#1f6feb`(Normal)·`#2ea043`(Insert)·`#8957e5`(Visual) 굵게, Git 구역·폴더 구역·채움 배경 구분. pull/push: `󰓦 ↑1` → 원격에 commit 추가·fetch 후 `󰓦 ↓1 ↑1` → upstream 없는 브랜치 `publish`
  - QA 34개 재실행: 에러 0, 창 배치 결과 이전과 동일. Startup 에러 없음, checkhealth ERROR 0
- 발견 (이번 범위 밖): Git Bash에서 Neovim을 실행하면 `$SHELL`(bash)이 'shell'이 되는데 'shellcmdflag'는 Windows 기본(`/s /c`)이라 `:!`·`system()`이 깨짐 (테스트 환경에서 확인). Windows Terminal/PowerShell에서 실행하면 해당 없음 → Phase 12 Platform Layer

### 사용자 피드백 2차 (2026-10-06): 상태바 가시성
- 피드백: ` main 󰓦 ↑1  +3 ~1  2  1`이 한데 붙어 무엇인지 알아보기 어려움 → VS Code 상태바처럼
- 변경: 한 배경에 codicon 아이콘 항목을 넓게 띄움. 브랜치 `main*`(변경 있음) · `0↓ 1↑`(항상 두 수) · 에러/경고 항상(0 포함) · `Ln 1, Col 5`. 변경 줄 수 제거. 디버그 중 상태바 전체 주황(`#c2410c`), Debug 배지는 더 진한 색. Terminal에 있을 때도 브랜치 표시(`git branch --show-current`)
- 검증: 깨끗한 저장소 `main  0↓ 1↑  ⊗1 ⚠0` → 수정·저장 `main*` → 디버그 정지 중 모든 항목 배경 주황 + `Debug 정지` 배지 → 종료 후 원래 색 → 오른쪽 Terminal에서도 `main*  0↓ 1↑`. git 밖 폴더는 브랜치·pull/push 없이 에러/경고만. Startup 에러 없음, checkhealth ERROR 0

### 사용자 테스트 · Keymap 전체 검토 · 정리 (2026-10-06~07)
- 사용자 확인: `` Ctrl+` ``는 Windows Terminal에서 아무것도 오지 않음 (입력 모드 `Ctrl+Q` → `` Ctrl+` `` 결과 없음) → **`` Alt+` ``로 교체** (사용자 선택)
- Keymap 전체 검토 (전역 n/x/o/i/t/c/s + LSP·gitsigns·mini.files·aerial·Terminal 버퍼 전용, `--clean` 기본값과 비교):
  - 충돌 1건: Insert `<Tab>`/`<S-Tab>`(TASK-007 완성 목록 이동)가 내장 snippet 칸 이동을 덮어써서 USAGE의 "snippet `<Tab>` 다음 칸"이 실제로는 안 됐음 → 목록이 떠 있으면 목록 이동, snippet 안이면 다음/이전 칸, 아니면 보통 Tab (검증: `foo(alpha, beta)` → X → `<Tab>` → Y → `foo(X, Y)`, 목록 선택 -1 → 0 → -1, 보통 Tab 들여쓰기). 사용자 승인 전에 고친 것이라 사용자에게 보고 후 유지 결정
  - 같은 키를 두 기능이 덮어쓴 것 없음. 내장 기본값 변경은 의도된 것만 (`]b`/`[b`, Normal `<C-p>`/`<C-b>`, Visual `J`/`K`/`S`/`<`/`>`, `<Esc>`, LSP `gd`). 별칭(`Ctrl+P`=`<Leader>ff` 등)은 의도된 것. 영역별 같은 키(`<Tab>`, `q`, `h`/`l`, `[[`/`]]`)는 버퍼 전용. 사용자 명령 겹침 없음 (Plugin 명령은 접두어, 자체는 `:TrimWhitespace`)
  - Terminal 안 프로그램에는 `Alt+h/j/k/l`·`Alt+a`·`` Alt+` ``·`<C-q>`가 전달되지 않음 (bash `Alt+l` 정도)
- 경량화 (사용자 결정: 대부분 유지, 확실히 불필요한 것만): **`<Leader>aa`**(→ `Alt+a`, `<Leader>ac`/`ax`), **`<Leader>tl`**(→ 하단·오른쪽 영역 탭, `terminal.list()`도 함께 제거), **`<Leader>eq`**(→ `<Leader>eD`) 제거. 별칭·거의 안 쓸 키는 써 본 뒤 판단
- 검증: 세 키 없음, 대체 키 정상, 하단 패널·배치 시나리오(D1·D3·E1·E3) 이전과 같음, Startup 에러 없음, checkhealth ERROR 0
- 참고: 오른쪽 위 `1 2 3`은 Neovim tab page(화면 전체 작업 공간) 표시 (bufferline, tab page 2개 이상일 때). 사용자 화면에 tab page 3개가 있었음 (만든 경위는 미확인)

### Terminal 영역 보호 · 탭 페이지 (2026-10-07, [D-021](../../DECISIONS.md))
- 사용자 보고: 3번 탭 페이지에서 Terminal 자리에 소스 코드 창. 사용자 화면 확인(읽기만): 처음 탭 페이지(창 1000·1001)의 오른쪽 영역 창이 `keymaps.lua`를 보여 줌, `:messages`에 `E73: Tag stack empty`×5·`E78`
- 재현 (검토만 요청 → 원인·대책 보고 → 사용자 1·2번 선택): 오른쪽 Terminal·하단 패널(Normal 모드)에서 탭 클릭·`<Space>ff`·mini.files·`<C-o>` → 파일이 그 창에 열림 (`]b`는 영향 없음). 검색 창 `<C-t>`·`<C-w>T`·`:tabnew`로 탭 페이지 생성, 새 탭 페이지에는 시작 배치 없음
- 수정 1: Terminal 영역 창에 파일이 들어오면 마지막 코드 창으로 옮기고 Terminal 되돌림 (`layout.lua` `guard_area`). 새 Terminal이 빈 버퍼 → Terminal 순서로 열리는 경우는 실행 시점에 다시 확인해 제외
- 수정 2: mini.pick `choose_in_tabpage` 끔
- 검증: 위 재현 경우 모두 → 영역은 Terminal, 파일은 코드 창, 커서 코드 창. 검색 창 `<C-t>` → 탭 페이지 안 생김(검색 창 유지). QA 34개 재실행 에러 0·배치 결과 이전과 동일, 디버그 세션·오른쪽 영역(Claude) 정상, Startup 에러 없음, checkhealth ERROR 0

### `:q`로 종료 안 됨 (2026-10-07)
- 사용자 보고: `:q`해도 나가지지 않음. 재현: 코드 창 + 오른쪽 Terminal(시작 배치)에서 `:q` → 코드 창이 닫혔다가 빈 코드 창이 다시 생김 (오른쪽 폭도 64 → 79). 숨겨진 Terminal이 실행 중이어도 종료 자체는 됨, `:qa`도 됨
- 원인: `:q`는 창 하나만 닫음 + QA 때 넣은 "마지막 코드 창을 닫으면 빈 코드 창 다시 만들기"가 겹침. 시작 시 오른쪽 Terminal이 열리면서 항상 발생
- 수정 프롬프트를 사용자에게 먼저 제시 후 구현. 구현 중 한 가지 변경: "저장 안 된 파일이 있으면 아무것도 닫지 않고 알림"은 `:q`를 중간에 취소할 수 없어 파일이 숨겨지고 빈 창이 생기므로 → 다른 영역을 닫고 Neovim 기본 보호(`E37`/`E162`)로 종료 거부
- 수정: QuitPre — 현재 탭 페이지의 마지막 코드 창이면 다른 창을 모두 먼저 닫음. 빈 코드 창 다시 만들 때 양쪽 폭은 닫히기 직전 크기로 (WinClosed 시점에 기록), 패널 높이 유지
- 검증 11개: 시작 배치·Outline+패널+Agent에서 `:q` 종료 / `:wq`(저장됨)·`ZZ` 종료 / 다른 파일·현재 파일 저장 안 됨 → 종료 안 되고 `E162` / 오른쪽 Terminal에서 `:q` → 그 창만 / 탭 페이지 2개 → 그 탭 페이지만 / 코드 창 2개 → 하나만 / `<C-w>c`로 마지막 코드 창 → 빈 코드 창, Outline 32·오른쪽 50(사용자가 바꾼 폭) 유지. QA 34개 재실행: 에러 0, E3("`:q` 후 빈 코드 창")만 의도대로 종료로 바뀜
- 문서 사고: 상태바 설명을 고치던 이전 스크립트가 USAGE의 "탭 (bufferline)"·"창 이동" 절을 함께 지움 (미커밋 내용이라 git 복구 불가) → 현재 설정 기준으로 다시 작성

### 오른쪽 영역 전체 화면 (2026-10-07, 사용자 요청)
- `Alt+z`(Normal·Terminal) / `<Leader>az`: 오른쪽 영역(Terminal·Claude·Codex)을 편집 영역 전체 float로 (위쪽 탭 바·상태바 유지, 오른쪽 열은 닫음), 다시 누르면 원래 폭의 오른쪽 열로. 전체 화면도 오른쪽 영역으로 취급(탭 winbar, 파일 열기 보호, 영역 키). 전체 화면에서 `Alt+a`는 전체 화면을 끝내고 코드 창으로. 화면 크기 변경 시 따라감
- Keymap 확인: `<M-z>`, `<Space>az` 비어 있음 (n/t/i)
- 검증: 오른쪽 50열(사용자가 바꾼 폭) → `Alt+z` 160×37 전체 화면(탭 `Terminal`) → `<C-q>` `<Space>ac` → 같은 전체 화면에 탭 `Terminal  Claude Code` → `Alt+z` → 50열로 복귀 / 코드 창에서 `<Space>az` / 전체 화면에서 `Alt+a` → 복귀 + 코드 창 / 화면 120×30 → 120×27로 따라감 / 오른쪽 Terminal 없음 → 동작 없음(알림). checkhealth ERROR 0
- 구현 중 발견·수정: 전체 화면(float)에서 Agent로 바뀌면 탭 winbar가 사라짐 (floating 창은 winbar 제외) → 전체 화면 창만 예외

### 완료 (2026-10-07)
- PR #15 merge (`b84b580`, 기능별 15개 commit)
- 사용자 확인 (2026-10-07, merge 후): Windows Terminal에서 `Alt+z`·`` Alt+` ``·`Alt+h/j/k/l`·`Ctrl+B`·`Ctrl+P` 동작, 마우스(탭·패널 탭 클릭), Nerd Font·codicon 아이콘 표시 → 미검증 항목 없음
- 이후 별도 Task: 목적별 Mode 전환 (Deferred), Git Bash에서 `:!` 깨짐 (Phase 12)

## Steps
1. Decisions 확인 → 레이아웃 설계 확정 (Q1~Q4, 2026-10-06 완료)
2. ~~사용자 구현 지시 후 1단계 구현·검증~~ (2026-10-06 완료) → 사용자 화면 확인
3. ~~2단계 구현·검증~~ (2026-10-06)
4. ~~3단계~~ (2026-10-06, Windows Terminal binding 확인. 실제 키 전달은 사용자 테스트)
5. ~~문서 갱신~~ (2026-10-06: USAGE, ARCHITECTURE, DECISIONS D-018·D-019, PROJECT, VERIFICATION, PROGRESS)
6. 사용자 전체 테스트 → 피드백 반영 → 완료 처리

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- 사이드바·탭·하단 패널·Agent·경로 표시가 정해진 자리에 열리고, 열고 닫아도 배치가 흐트러지지 않음
- 기존 기능(검색, LSP, Git, Run, Debug, Agent) 회귀 없음
- 새 단축키는 Windows Terminal에서 실제 동작 확인된 것만, 기존 Keymap과 충돌 없음
- 사용자 화면 확인

## Related Files
`lua/sinbin/plugins/init.lua`, `lua/sinbin/plugins/ui.lua`, `lua/sinbin/plugins/search.lua`, `lua/sinbin/terminal.lua`, `lua/sinbin/agent.lua`, `lua/sinbin/plugins/debug.lua`, `lua/sinbin/layout.lua`(신규 예정), `nvim-pack-lock.json`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/PROJECT.md`

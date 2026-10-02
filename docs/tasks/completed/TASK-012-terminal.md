# TASK-012: Phase 7 Terminal

- **Status:** Completed (2026-10-02)
- **Goal:** Neovim 안에서 Terminal을 빠르게 열고 닫으며(dev server, test, docker, git 명령), Phase 10에서 AI Agent CLI를 같은 방식으로 띄울 수 있는 기반을 만든다.

## Background
PROGRESS Next Action. PROJECT 목표 Layout의 하단 패널(Terminal / Claude Code / Test / Server Logs).

### 현재 상태 (2026-10-02 확인)
- 내장: `:terminal`, `jobstart(cmd, { term = true })`. Terminal 모드 기본 탈출 키는 `<C-\><C-n>` (외우기 어려움)
- `lua/sinbin/lazygit.lua`(TASK-011)에 floating terminal 코드가 이미 있음 → 공통화 대상
- **'shell'이 실행 방법에 따라 달라짐**: Git Bash에서 nvim 실행 시 `$SHELL`을 이어받아 `C:\Program Files\Git\bin\bash.exe`, PowerShell/Windows Terminal에서 실행 시 기본값 `cmd.exe` → Platform Layer(D-003)에서 고정 필요
- 설치된 Shell: Windows PowerShell 5.1, cmd, Git Bash. PowerShell 7(`pwsh`) 미설치
- `<Leader>t` 그룹 비어 있음, Terminal 모드 Keymap 없음

## Scope (후보)

| 항목 | 방식 |
|---|---|
| Terminal 구현 | 자체 모듈 `lua/sinbin/terminal.lua` (내장 `jobstart term=true`) / toggleterm.nvim — Decisions 1 |
| 위치 | 하단 split 토글 (기본) + floating — Decisions 2 |
| 여러 Terminal | 번호로 구분 (`2<Space>tt` → 2번 Terminal) |
| Terminal 모드 탈출 | Decisions 3 |
| Shell | Platform Layer에서 OS별 지정 — Decisions 4 |
| lazygit | 공통 floating 함수로 이전 |
| Phase 10 대비 | 명령 지정 Terminal(`open({ cmd = "claude" })`)을 지원하는 구조 |

## Out of Scope
- AI Agent 실행 UX·Keymap (Phase 10)
- Run/Test 명령 자동 선택 (Phase 8)
- Mode별 Layout (Phase 11)

## Prerequisites
- TASK-011 (lazygit floating, PR #10 merge 후 main 기준)

## Decisions (2026-10-02 사용자 확인)
1. **구현:** 자체 모듈 `lua/sinbin/terminal.lua` ([D-014](../../DECISIONS.md))
2. **기본 위치:** 둘 다 (하단 split `<Leader>tt`, floating `<Leader>tf`)
3. **Terminal 모드 탈출:** `<C-q>` (`<Esc>`는 매핑 안 함)
4. **Shell (Windows):** Git Bash. 전역 'shell'은 바꾸지 않고 Terminal에만 적용 (`:!`·`system()` 인용 규칙 보호, 구현 중 판단)
5. **Keymap:** 초안대로

### Keymap (`<Leader>t` Terminal 그룹)

| 모드 | Key | 동작 |
|---|---|---|
| N | `<Leader>tt` | 하단 Terminal 열기/숨기기 (`2<Leader>tt`는 2번) |
| N | `<Leader>tf` | floating Terminal 열기/숨기기 |
| N | `<Leader>tl` | Terminal 목록 (picker) |
| T | `<C-q>` | Normal 모드로 |

## Steps
1. Decisions 확인
2. Platform Layer에 Shell 지정, `terminal.lua` 작성, lazygit 이전
3. 검증 (열기/숨기기/재사용, 여러 Terminal, Shell, lazygit 회귀)
4. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-014), PROJECT(Scope·Capabilities 현행화), PROGRESS

## Acceptance Criteria
- Startup 에러 없음
- Terminal 열기/숨기기 시 같은 Shell 세션 유지 (숨겨도 프로세스 종료 안 됨)
- 여러 Terminal 구분 동작
- 실행 방법(Git Bash / PowerShell)과 무관하게 같은 Shell
- lazygit `<Leader>gg` 기존 동작 유지
- Keymap 충돌은 의도한 것만 존재

## Related Files
`lua/sinbin/terminal.lua`(신규), `lua/sinbin/plugins/search.lua`(`<Leader>tl`), `lua/sinbin/lazygit.lua`, `lua/sinbin/platform/windows.lua`, `init.lua`, `lua/sinbin/plugins/ui.lua`(mini.clue 그룹), `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/PROJECT.md`

## Result
- `platform/windows.lua`: `platform.terminal_shell = { <Git>\bin\bash.exe, "--login", "-i" }` (git.exe 위치의 상위 폴더에서 `bin\bash.exe` 탐색)
- `terminal.lua`(신규): `toggle(id, kind)`, `run_float(cmd, opts)`, `list()`, `show(id)`, 하단 split(화면 30%, 최소 8줄)·floating(85%), 창마다 number/signcolumn 끔, `exit` 시 창·버퍼 정리, `<Leader>tt`/`tf`, Terminal 모드 `<C-q>`
- `lazygit.lua`: 자체 floating 코드 제거, `terminal.run_float` 사용
- `plugins/search.lua`: `<Leader>tl` Terminal 목록 picker (mini.pick)
- `plugins/ui.lua`: mini.clue `<Leader>t` +Terminal 그룹
- `init.lua`: terminal 모듈 로드 (lazygit 앞)
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-014), PROJECT(Scope·Capabilities·Plugin Manager 현행화)

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5)
UI를 attach한 `nvim --embed --headless -n`을 RPC로 조작 (Terminal은 UI가 없으면 bash가 즉시 logout).
- `<Space>tt` → 하단 split, terminal 모드, argv `C:/Program Files/Git/bin/bash.exe --login -i`, number/signcolumn 꺼짐
- Shell 출력 `echo SINBIN_$((40+2))` → `SINBIN_42`
- `<C-q>` → mode `nt`(Terminal Normal)
- 다시 `<Space>tt` → 창 숨김, job 살아 있음 / 다시 → 같은 버퍼로 표시
- `2<Space>tt` → 별도 Terminal 2, `<Space>tf` → floating Terminal, 목록 3개
- Terminal 1에서 `exit` → 목록에서 제거, 창 닫힘
- `<Space>gg` lazygit → `run_float`로 실행, `q` → 창 닫힘 (회귀 없음)
- `SHELL` 환경변수 없이 실행(PowerShell 실행 상황): 'shell'=`cmd.exe`이지만 Terminal은 같은 Git Bash
- `nvim --headless "+qa"` 출력 없음, exit 0
- 화면 확인 (사용자, 2026-10-02): Terminal 토글·여러 Terminal·floating·목록·`<C-q>`, `<Leader>fe` 토글

## 추가 변경 (사용자 요청, 2026-10-02)
- `<Leader>fe`(mini.files)를 열기/닫기 토글로 변경. 문서 예시(`if not MiniFiles.close() then open`)는 미적용 편집을 유지하고 닫기를 취소하면 `close()`가 false라 다시 열리므로 `get_explorer_state()`로 판단
- 검증: `<Space>fe` 열기(현재 파일 폴더) → 다시 누르면 닫힘 → 다시 열림 → `q` 닫힘

## Notes
- Git Bash 안에서는 `exepath("git")`이 `<Git>\mingw64\bin\git.exe` → 처음 구현(두 단계 위 + `bin\bash.exe`)이 bash를 못 찾고, fallback이 'shell'을 문자열로 넘겨 `cmd` 방식 flag(`/s /c`)가 붙어 Terminal이 바로 종료됨 → 상위 폴더 탐색 + fallback을 list로 전달하도록 수정
- `exepath("bash")`는 WSL launcher(`%LOCALAPPDATA%\Microsoft\WindowsApps\bash.exe`)를 찾을 수 있음 → git.exe 기준 탐색
- 테스트 중 이전 embed 자식이 남긴 swap 파일 때문에 다음 자식이 E325 prompt에서 멈춤 → 테스트용 자식은 `-n`(swap 없음)으로 실행

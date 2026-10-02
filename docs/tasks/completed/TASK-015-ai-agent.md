# TASK-015: Phase 10 AI Coding Agent Integration

- **Status:** Completed (2026-10-02)
- **Goal:** Claude Code와 Codex CLI를 Neovim 안에서 실행하고, 현재 파일·선택 위치를 Agent에 넘기며, Agent가 바꾼 코드를 바로 검토하는 흐름을 만든다.

## Background
PROGRESS Next Action. PROJECT 목표 Workflow: `nvim . → AI Agent 실행 → 코드 생성/수정 → Diff 확인 → Error/Diagnostic 확인 → Build/Test → Git Commit`.
[D-002](../../DECISIONS.md): Agent는 Neovim Core에 내장하지 않고 독립 CLI로 실행. Neovim은 실행 위치와 결과 확인만 담당.

### 현재 상태 (2026-10-02 확인)
- Claude Code 2.1.287, Codex CLI 0.158.0 설치됨 (npm 전역, `%APPDATA%\npm`)
- 이미 있는 기반: `terminal.lua`(D-014, `<Esc>`를 프로그램에 전달), 외부 수정 자동 반영(`checktime`, D-013), 전체 변경 검토 `<Leader>gv`, hunk 미리보기, 진단
- `<Leader>a` 그룹 비어 있음 (PROJECT Keymap 방향의 AI Agent 그룹)
- 선택지: `coder/claudecode.nvim` — Claude Code 공식 IDE 연동 프로토콜의 Neovim 구현 (VS Code 확장과 같은 방식: 선택 영역 자동 공유, Claude 수정안을 diff로 수락/거절). 2026-06 commit, ★3k. Claude Code 전용 (Codex 미지원)

## Scope (후보)

| 항목 | 방식 |
|---|---|
| Agent 실행 | `terminal.lua`로 `claude` / `codex` 실행. 숨겨도 세션 유지 |
| 창 위치 | 오른쪽 세로 창 / 하단 / floating — Decisions 2 |
| 위치 넘기기 | 현재 파일 경로·선택 줄 범위를 Agent 입력창에 텍스트로 입력 (`@상대경로#L10-20` 형식, Enter는 누르지 않음) |
| 결과 검토 | 기존 `<Leader>gv`(전체 변경 검토)·`]h`/`<Leader>gp`와 연결, Agent 창에서 바로 이동 |
| Claude 전용 IDE 연동 | claudecode.nvim — Decisions 1 |

### Keymap 초안 (`<Leader>a` AI Agent 그룹)

| Key | 동작 |
|---|---|
| `<Leader>aa` | 마지막으로 쓴 Agent 열기 / 숨기기 |
| `<Leader>ac` | Claude Code 열기 / 숨기기 |
| `<Leader>ax` | Codex 열기 / 숨기기 |
| `<Leader>af` | 현재 파일 경로를 Agent에 넣기 |
| `<Leader>as` (V) | 선택한 줄 범위를 Agent에 넣기 |

## Out of Scope
- Agent를 Neovim에 내장하는 Plugin (avante.nvim, codecompanion 등) — D-002
- Agent 대화 기록 관리, 여러 세션 병렬 관리 UI
- Mode별 Layout 전환 (Phase 11)

## Prerequisites
- TASK-012 (`terminal.lua`), TASK-011 (`<Leader>gv`, `checktime`)

## Decisions (2026-10-02 사용자 확인 — 추천안)
1. **claudecode.nvim:** 보류. Claude·Codex 같은 방식(자체 Terminal)으로 ([D-017](../../DECISIONS.md))
2. **Agent 창 위치:** 오른쪽 세로 창
3. **위치 넘기기 형식:** `@경로#L10-20`
4. **Keymap:** 초안대로

## Steps
1. Decisions 확인
2. Agent 실행·토글 모듈, Keymap, mini.clue 그룹
3. 위치 넘기기
4. Claude·Codex 실제 실행 확인 (Agent 입력·`<Esc>`·숨기기/다시 열기·파일 수정 반영)
5. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-017), PROGRESS

## Acceptance Criteria
- Startup 에러 없음
- Claude·Codex 각각 열기/숨기기, 숨겨도 세션 유지
- 파일 경로·선택 범위가 Agent 입력창에 들어감 (자동 전송 안 함)
- Agent가 파일을 바꾸면 열린 버퍼 반영, `<Leader>gv`로 검토 가능
- Agent CLI가 없으면 이유 안내
- Keymap 충돌은 의도한 것만 존재

## Related Files
`lua/sinbin/agent.lua`(신규), `lua/sinbin/terminal.lua`, `init.lua`, `lua/sinbin/plugins/ui.lua`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`

## Result
- `terminal.lua`: 오른쪽 세로 창 kind `right`(화면 40%, 최소 60열), `toggle(id, kind, { cmd, cwd, name })`로 프로그램 실행(Run과 같은 `terminal_exec` 경유 → Windows npm shim 문제 없음), `is_running`, `focus`, `send`
- `agent.lua`(신규): Claude Code(`claude`)·Codex(`codex`) 토글, 시작 위치 = 현재 파일의 git root(없으면 작업 폴더), `@상대경로#L10-20 ` 입력 후 Agent로 focus, 미설치·미실행·파일 아님 안내, Keymap `<Leader>aa/ac/ax/af`, Visual `<Leader>as`
- `plugins/ui.lua`: mini.clue `<Leader>a` +AI Agent
- `init.lua`: agent 모듈 로드
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-017), PROJECT(Run/Test·Debug·AI Agent → Current)

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5)
UI attach한 `nvim --embed --headless -n`을 RPC로 조작, 이 저장소에서 실제 Agent 실행. Enter는 보내지 않음(메시지 전송·코드 실행 없음).
- Claude Code 2.1.287: `<Space>ac` → 오른쪽 창(width 80 / 200열) 실행, 화면 표시 → `<Space>aa` 숨김(세션 유지) → 다시 표시 → Visual 1~2행 `<Space>as` → 입력창에 `@lua/sinbin/agent.lua#L1-2` 표시 (확인 후 `Ctrl-U`로 입력 지움)
- Codex 0.158.0: `<Space>ax` → 오른쪽 창 실행 → 숨김·다시 표시 동작. 이 폴더 첫 실행이라 "Trust this folder?" 화면 → 신뢰 여부는 사용자 결정이라 응답하지 않고 텍스트 전송 테스트 생략
- Agent 없이 `<Space>af` → `실행 중인 Agent 없음 (<Space>ac Claude Code, <Space>ax Codex)`
- Keymap desc 확인, 기존 매핑과 충돌 없음
- `nvim --headless "+qa"` 출력 없음, exit 0
- 화면 확인 (사용자, 2026-10-02): `Alt+a` 왕복 포함 동작 확인

## 추가: `Alt+a` 왕복 키 (사용자 요청, 2026-10-02)
- 보고: Agent 창 ↔ 코드 창 이동이 어려움 (`<C-q>` → `<C-w>h`, 돌아갈 때 `<C-w>l` 후 `i` 필요, 보이는 창에서 `<Leader>ac`를 누르면 숨겨짐)
- 결정: Phase 11에서 UI/UX를 전면 재설계할 예정이라 지금은 키 하나만 추가. `Alt+a`(Normal·Terminal 모드): 코드 → Agent(보이면 이동, 숨겨져 있으면 표시, 꺼져 있으면 마지막 Agent·처음엔 Claude 실행, Terminal 입력 모드), Agent → 들어오기 전 코드 창(Agent 창은 그대로 둠). `<Leader>ac` 토글 동작 등은 그대로 두고 Phase 11로 넘김
- 검증 (실제 Claude Code): 코드 → `Alt+a` → Agent(mode `t`, 창 2개) → 단어 입력 → `Alt+a` → 코드(mode `n`), 입력한 단어 Agent 입력창에 유지 → `Alt+a` → Agent → 코드에서 `<Space>aa`로 숨김 → `Alt+a` → 다시 표시·입력 모드. 테스트 단어는 `Ctrl-U`로 지움, Enter 보내지 않음
- Phase 11에 넘길 것: 창 이동 체계 전반 (`<Leader>a*` 토글이 보이는 창을 숨기는 문제, 마우스·`<C-w>`로 들어갔을 때 자동 입력 모드 등)

## Notes
- 테스트용 Neovim이 이 Claude Code 세션에서 실행되어 Agent 화면에 `inherited CLAUDE_CODE_CHILD_SESSION marker` 경고 표시 → 테스트 환경 탓, 일반 실행 시 없음
- Codex 테스트가 띄운 `app-server-daemon`(테스트 시각에 생성, 부모 종료)은 정리. VS Code 확장의 codex 프로세스와 현재 Claude Code 세션은 건드리지 않음
- 테스트 스크립트가 Terminal 버퍼를 이름으로 찾다 실패(버퍼 이름에 `bash.exe`만 표시) → terminal 모듈 id로 조회

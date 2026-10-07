# TASK-019: 설정 패널 (Settings)

- **Status:** In Progress (2026-10-07) — 구현·harness 검증 완료, 실제 화면 사용자 확인 대기
- **Goal:** 자주 바꾸는 설정을 코드 수정 없이 가운데 뜨는 패널에서 바꾸고, 다음 실행에도 유지한다.

## Background
사용자 요청 (2026-10-07). 시작 화면의 `c 설정 열기`가 config 폴더 파일 찾기라 "설정"으로 쓰기 어려움 → VS Code 설정 화면 같은 패널.

## Decisions (2026-10-07 사용자 결정)
1. 방식: 설정 패널 (floating 창, 항목·현재 값 표시, 키로 변경, 바로 적용 + 저장)
2. 저장: 저장소 밖 `stdpath("data")/sinbin/settings.json`, 기본값과 다른 값만. 기본값은 코드(`lua/sinbin/settings.lua`)
3. 열기: 시작 화면 `c`, `:Settings`, `<Space>,`
4. 제외: 배경 이미지(Windows Terminal 영역), Agent 패널 위치(오른쪽 영역 전제 배치, D-018·D-020)
5. 시작 화면(TASK-018)과 분리, Phase 12는 TASK-020

## 항목
| 분류 | 항목 | 값 | 적용 |
|---|---|---|---|
| 화면 | 색 테마 | moon / storm / night | 바로 |
| 화면 | 배경 투명 | on/off (tokyonight `transparent`) | 바로 |
| 화면 | 상대 줄 번호, 현재 줄 강조, 공백 문자 표시, 긴 줄 줄바꿈 | on/off | 바로 (코드 창) |
| 편집 | 들여쓰기 폭 | 2 / 4 / 8 | 새로 여는 파일부터 |
| 편집 | 들여쓰기 문자 | Spaces / Tab | 새로 여는 파일부터 |
| 편집 | 검색 대소문자 | 스마트 / 항상 무시 / 항상 구분 | 바로 |
| 편집 | 커서 위아래 여백 (scrolloff) | 0 / 4 / 8 / 15 / 가운데 고정 | 바로 |
| 편집 | 자동 저장 (새 기능) | on/off: Insert 벗어날 때·다른 버퍼로·포커스 잃을 때 | 바로 |
| IDE | 시작 시 Terminal / 시작 시 Agent | on/off | 재시작 |
| IDE | 줄 끝 Git blame, 진단 표시, 한/영 자동 전환 | on/off | 바로 |
| IDE | Outline 커서 이동 시 코드 따라가기 (aerial `autojump`) | on/off | Outline 다시 열 때 |
| 시작 화면 | 시작 화면 사용 | on/off | 재시작 |
| 시작 화면 | 로고 gradient, Tip 표시 | on/off | 바로 |
| 시작 화면 | 최근 프로젝트 개수 | 0~5 | 바로 |
| Agent | 기본 Agent | Claude Code / Codex | 바로 (`Alt+a`·시작 시 Agent) |
| Agent | 패널 폭 | 화면의 30 / 40 / 50% (최소 60칸) | 바로 |
| Agent | 이전 대화 이어서 시작 | on/off: `claude --continue` / `codex resume --last` | 다음 Agent 시작부터 |
| 고급 | 설정 파일 열기, Plugin / LSP / Treesitter 상태, 설정 초기화 | 동작 | — |

- "Outline 자동 따라가기"는 aerial이 Outline 커서를 코드 커서에 항상 맞추므로(끌 수 있는 옵션 없음), 반대 방향인 Outline에서 움직이면 코드가 따라가는 `autojump`로 구현

## 구현 (2026-10-07)
- `lua/sinbin/settings.lua` ([D-024](../../DECISIONS.md)): `list`(분류·이름·기본값·선택지·`apply`·`note`·고급 `run`), `get`/`set`/`apply`/`reset`/`apply_theme`/`edit_file`. 저장은 기본값과 다른 값만 패널 순서로 한 줄씩. 읽을 때 모르는 키·선택지 밖 값 무시, 깨진 JSON은 알림 후 기본값. `settings.json` 저장 시 다시 읽고 전부 적용
- `lua/sinbin/settings_ui.lua`: floating 창(제목·footer 도움말), 값 표시 `[x]`/`[ ]`·`‹ 값 ›`·`→`, 적용 시점 `(재시작)` 등. 패널 버퍼는 mini.clue 끔(`<Space>`를 Leader로 가로채지 않게), 창 옵션은 `vim.wo[win][0]`(setlocal). 다른 창으로 가면 닫힘. 고급 항목은 닫은 뒤 실행, 초기화 뒤 패널 다시 열기
- 읽는 곳: `options.lua`(줄 번호·강조·공백·줄바꿈·들여쓰기·검색·여백), `plugins/ui.lua`(테마), `plugins/git.lua`(blame), `diagnostics/init.lua`, `ime.lua`, `plugins/sidebar.lua`(aerial `autojump`), `layout.lua`(`right_width`, `resize_right`), `agent.lua`(기본 Agent `set_default`, 이어서 시작 인자, 시작 시 Terminal/Agent `open_right`, `toggle(agent, background)`), `starter.lua`(autoopen, gradient `set_hl`, Tip, 최근 프로젝트 개수, `refresh`, `c` = 패널), `autocmds.lua`(자동 저장)
- 열기: `keymaps.lua` `<Leader>,`, `commands.lua` `:Settings`, 시작 화면 `c`

## 검증 (2026-10-07)
UI attach한 `nvim --embed -n` RPC:
- 패널: `<Space>,`·`:Settings`·시작 화면 `c`로 열림 (63×39 floating), 항목 29개(설정 24 + 고급 동작 5) 분류별 표시, 커서 첫 항목, `q` 닫기. `<Leader>,` 충돌 없음 (`:verbose nmap`)
- 패널 안 `l` → 테마 storm 적용·저장, `jj<Space>` → 상대 줄 번호 끔 저장, 다시 `<Space>` → 기본값이라 파일에서 빠짐
- 재시작 후 저장 값 유지: 패널에서 테마 storm·상대 줄 번호 끔 → 재시작 → `tokyonight-storm`, 새 창 상대 줄 번호 꺼짐
- 바로 적용: 배경 투명(Normal bg 없음 ↔ 있음), list/wrap/cursorline, 들여쓰기 2·Tab, scrolloff 999, 검색 항상 구분, 진단 끔, blame 끔, 시작 화면 Tip·최근 프로젝트 숨김·gradient 끔(링크), autojump, 패널 폭 50%(=80칸)
- 자동 저장: 켜고 파일 편집 후 `<Esc>` → 파일에 저장됨
- `settings.json` 직접 편집 저장 → 다시 읽음 (theme night 적용, 잘못된 indent 7은 무시), 깨진 JSON → 기본값, 시작 시 깨진 JSON → 알림 + 기본값
- 시작 시: Terminal 끔 → 오른쪽 영역 없음 / Agent만 → 오른쪽 Claude Code, 커서 코드 창 / 둘 다 + 이어서 시작 → Shell·Claude 둘, Claude가 `--continue`로 이전 대화 표시 / 시작 화면 끔 → 빈 버퍼 + 시작 시 Terminal
- 고급: Plugin·LSP·Treesitter 상태 → `:checkhealth` 새 탭 페이지(ERROR 0), `q`로 닫힘 / 초기화(확인 함수 대체) → 파일 삭제, 기본값, 패널 다시 열림
- 주의: 시작 시 Agent 확인 중 PATH의 가짜 `claude` 대신 Git Bash가 실제 Claude Code를 실행함 (입력 없이 Neovim 종료와 함께 끝남, 남은 프로세스 없음 확인)
- 테스트로 만든 `settings.json` 삭제, `projects.txt` 변화 없음
- **사용자 확인 필요:** 실제 Windows Terminal에서 패널 모양, 배경 투명

## Acceptance Criteria
- `:Settings` / `<Space>,` / 시작 화면 `c`로 패널이 열림
- 각 항목 변경이 바로(또는 표시된 시점에) 적용되고 `settings.json`에 기본값과 다른 값만 저장됨
- 재시작 후 저장된 값 유지, 잘못된 값·깨진 JSON은 무시하고 기본값
- `settings.json` 직접 수정 후 저장 시 다시 읽어 적용
- 설정 초기화 시 확인 후 파일 삭제·기본값 적용
- Startup 에러 없음

## Related Files
`lua/sinbin/settings.lua`, `lua/sinbin/settings_ui.lua`, `init.lua`, `lua/sinbin/{options,autocmds,commands,keymaps,ime,agent,layout,starter}.lua`, `lua/sinbin/plugins/{ui,git,sidebar}.lua`, `lua/sinbin/diagnostics/init.lua`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`

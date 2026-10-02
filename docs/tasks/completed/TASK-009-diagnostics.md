# TASK-009: Phase 5 Diagnostics

- **Status:** Completed (2026-10-02)
- **Goal:** LSP가 보내는 에러·경고를 코드 위에서 바로 읽고, 목록으로 모아 보고, 빠르게 이동할 수 있게 한다.

## Background
PROGRESS Next Action. RULES Plugin 원칙에 따라 내장 `vim.diagnostic`을 먼저 검토한다.

### 현재 상태 (2026-10-02 확인, Neovim 0.12.5 기본값)

| 항목 | 기본값 | 의미 |
|---|---|---|
| `virtual_text` | `false` | 줄 끝 에러 메시지 **안 보임** |
| `virtual_lines` | `false` | 줄 아래 에러 메시지 안 보임 |
| `signs` | `true` | 줄 번호 옆 표시 (`E`, `W` 등 글자) |
| `underline` | `true` | 에러 위치 밑줄 |
| `severity_sort` | `false` | 심각도 순 정렬 안 함 |
| Keymap | `]d` / `[d` 다음·이전, `]D` / `[D` 마지막·처음, `<C-w>d` 커서 위치 메시지 창 | 내장 |

- 상태바(`mini.statusline`)는 이미 진단 개수 표시 (`section_diagnostics`)
- 목록: 내장 `vim.diagnostic.setqflist()` / `setloclist()`, 이미 설치된 `mini.extra`의 `MiniExtra.pickers.diagnostic()`
- → **새 Plugin 없이** 설정과 Keymap만으로 구성 가능

## Scope

| 항목 | 방식 |
|---|---|
| 메시지 표시 | `vim.diagnostic.config()` — Decisions 1 |
| 심각도 순 정렬 | `severity_sort = true` |
| Sign 아이콘 | Nerd Font 아이콘 (Error / Warn / Info / Hint) |
| 이동 후 메시지 창 | `jump.on_jump`로 이동 시 float 표시 — Decisions 2 |
| 목록 | `mini.extra` diagnostic picker + quickfix |
| Keymap | `<Leader>e` Error/Diagnostic 그룹 (PROJECT Keymap 방향) |

### Keymap 초안

| Key | 동작 |
|---|---|
| `<Leader>ee` | 커서 위치 진단 메시지 창 (내장 `<C-w>d`와 같음) |
| `<Leader>ed` | 현재 파일 진단 목록 (picker) |
| `<Leader>eD` | 전체(열린 파일) 진단 목록 (picker) |
| `<Leader>eq` | 진단을 quickfix 목록으로 (`]q` / `[q` 이동) |
| `<Leader>et` | 진단 표시 켜기/끄기 토글 |

## Out of Scope
- trouble.nvim 등 진단 전용 UI Plugin (내장 + mini.extra로 부족하면 별도 Task)
- 외부 Linter(eslint 등) 연동 → 필요 시 별도 Task
- 프로젝트 전체 진단 (열지 않은 파일): Server 기능 차이, 별도 검토

## Prerequisites
- TASK-007 (LSP), TASK-006 (mini.extra, mini.clue)

## Decisions (2026-10-02 사용자 확인)
1. **메시지 표시 방식:** 모든 줄 끝 `virtual_text`
2. **이동(`]d`) 시 메시지 창 자동 표시:** 사용
3. **Keymap 초안:** 표대로
4. **`update_in_insert`:** 기본값(끔) 유지
5. **Plugin 추가 없음:** 내장 `vim.diagnostic` + 기존 `mini.extra` picker. DECISIONS 기록 없음 (기술 선택 변경 없음)

## Steps
1. Decisions 확인
2. `lua/sinbin/diagnostics.lua` 추가 (Plugin과 무관한 내장 설정) 및 Keymap, mini.clue `+Error` 그룹
3. 샘플 코드로 표시·이동·목록 검증
4. 문서 갱신: USAGE, ARCHITECTURE, PROGRESS (Plugin 추가 없으면 DECISIONS는 필요 시)

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- 에러가 있는 샘플 파일에서 선택한 방식으로 메시지 표시, `]d` 이동, picker·quickfix 목록 동작
- Keymap 충돌은 의도한 것만 존재
- USAGE에 진단 조작법 반영

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Lua Config, Keymap 항목

## Related Files
`init.lua`, `lua/sinbin/diagnostics.lua`(신규), `lua/sinbin/plugins/search.lua`, `lua/sinbin/plugins/ui.lua`(mini.clue 그룹),
`docs/USAGE.md`, `docs/ARCHITECTURE.md`

## Result
- `lua/sinbin/diagnostics.lua`(신규): `severity_sort`, `virtual_text`(`●` prefix), sign Nerd Font 아이콘, float `rounded` 테두리, `jump.on_jump`에서 float 표시, `<Leader>ee`/`eq`/`et`
- `init.lua`: commands 다음에 diagnostics 로드
- `plugins/search.lua`: `<Leader>ed`(현재 파일) / `<Leader>eD`(전체) mini.extra diagnostic picker
- `plugins/ui.lua`: mini.clue `<Leader>e` +Error/Diagnostic 그룹
- 문서: USAGE, ARCHITECTURE

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5, headless)
에러 2개가 있는 TypeScript 샘플(`vtsls`)로 확인.
- 진단 2개 수신, `severity_sort=true`, virtual_text extmark 2개 생성, sign 아이콘 4종 설정
- `vim.diagnostic.jump({ count = 1 })` → 2행으로 이동, float 창 1개 유지
- `setqflist` → quickfix 2개, `enable(false)` 토글 동작
- Keymap: `<Space>ee/ed/eD/eq/et` 설정, 내장 `]d`/`[d`/`<C-w>d` 유지 (충돌 없음)
- `nvim --headless "+qa"` 출력 없음, exit 0. checkhealth(`vim.lsp`, `vim.pack`, `nvim-treesitter`) ERROR는 이 Shell의 PATH 미갱신으로 인한 `tree-sitter-cli not found` 1건뿐 (TASK-008 Notes와 동일)
- 화면 확인 (사용자, 2026-10-02): 줄 끝 메시지, sign 아이콘, `]d` 이동 시 창, 목록

## Notes
- `on_jump`에서 `open_float()`를 바로 호출하면 이동 자체의 `CursorMoved`로 float가 즉시 닫힘 → `vim.schedule`로 지연
- `vim.diagnostic`에는 checkhealth 섹션이 없음 (`:checkhealth vim.diagnostic`은 "No healthcheck found" ERROR)- 에러 메시지 한글화 검토 (2026-10-02): vtsls(`typescript.locale = "ko"`)와 basedpyright(`LC_ALL=ko_KR.UTF-8`)는 한국어 번역 지원 확인, jdtls·clangd·dartls·ruff는 영어만 (jdtls는 JVM locale ko에서도 영어 확인). 사용자는 완전 번역 대신 용어는 영어를 살린 혼합 스타일을 원함 → 영어 원문 패턴 번역 방식으로 TASK-010에서 진행

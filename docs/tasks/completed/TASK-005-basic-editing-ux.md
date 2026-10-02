# TASK-005: Phase 2 기본 Editing UX

- **Status:** Completed (2026-10-01)
- **Goal:** 일상 편집에 필요한 최소 UX를 Neovim 기본 기능 우선으로 구성하고, 기본 기능으로 부족한 항목만 Plugin으로 보완한다.

## Background
PROGRESS Next Action. 범위는 사용자와 확정 (2026-10-01).
RULES Plugin 원칙("기본 기능으로 충분하면 추가 안 함")에 따라 A(내장) → B(Plugin) 순으로 진행한다.

## Scope

### A. Neovim 기본 기능 (Plugin 없음)

| 기능 | 구현 방식 | 위치 |
|---|---|---|
| Yank 하이라이트 | `TextYankPost` autocmd + `vim.hl.on_yank()` | autocmds |
| 공백·탭 표시 | `list`, `listchars` (tab, trail, nbsp) | options |
| 현재 줄 강조 | `cursorline` | options |
| 긴 줄 처리 | `wrap`, `linebreak`, `breakindent` 값 결정 | options |
| 치환 미리보기 | `inccommand=split` | options |
| 검색 하이라이트 끄기 | Normal `<Esc>` → `:nohlsearch` | keymaps |
| Visual 줄/블록 이동 | Visual `J`/`K` → `:m` 후 재선택·재들여쓰기 | keymaps |
| 들여쓰기 후 선택 유지 | Visual `<`/`>` → `<gv`/`>gv` | keymaps |
| 커서 위치 복원 | `BufReadPost` autocmd, `'"` mark로 이동 (gitcommit 등 제외) | autocmds |
| 줄 끝 공백 제거 | 사용자 명령 `:TrimWhitespace` (저장 시 자동 실행 안 함, diff 최소화) | commands |

주석 토글(`gc`)은 0.10부터 내장되어 있으므로 작업 없음. 동작만 확인한다.

### B. Plugin

| 기능 | 후보 | 이유 |
|---|---|---|
| 괄호/따옴표 자동 닫기 | `mini.pairs` / `nvim-autopairs` | 내장 기능 없음 |
| Surround | `mini.surround` / `nvim-surround` | 내장 기능 없음 |

## Out of Scope
- 들여쓰기 가이드 Plugin (`listchars`로 부족하면 별도 Task)
- text object 확장(`mini.ai`), Treesitter (Phase 4 무렵)
- which-key 등 UI (Phase 11)
- Colorscheme

## Prerequisites
- TASK-004 (`vim.pack`)

## Decisions (2026-10-01 사용자 확인)
1. **Plugin:** `mini.pairs` + `mini.surround`, 개별 repo, `stable` branch ([D-008](../../DECISIONS.md))
2. **Surround Keymap:** tpope 스타일 `ys`/`ds`/`cs` + Visual `S`, `yss`. 내장 `s` 유지
3. **Visual `J`/`K`:** 사용. 내장 Visual `J`(줄 합치기), `K`(keywordprg)를 덮어씀
4. **긴 줄:** `wrap` 켬(Neovim 기본값) + `linebreak`, `breakindent`. 사용자 지정이 없어 기본값 유지로 진행
5. **사용자 명령 위치:** `lua/sinbin/commands.lua`로 분리

## Steps
1. Decisions 확인
2. A 구현
   - `lua/sinbin/autocmds.lua` 추가 (ARCHITECTURE Planned → Current)
   - 사용자 명령 위치 결정 (`autocmds.lua`에 같이 둘지, `commands.lua` 분리할지) 후 ARCHITECTURE 갱신
   - `options.lua`, `keymaps.lua` 항목 추가
3. A 검증
4. B Plugin 추가 (`plugins.lua`에 한 줄 이유와 함께) 및 설정, lock 파일 갱신
5. B 검증
6. 문서 갱신 (ARCHITECTURE, DECISIONS, PROGRESS)

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- Scope의 각 항목을 실제로 동작 확인
- `:TrimWhitespace` 실행 전에는 파일이 변경되지 않음 (저장만으로 공백 제거되지 않음)
- 새 Keymap이 기존/Plugin Keymap과 충돌하는 경우 의도한 것만 존재 (RULES Keymap)
- Plugin은 B의 2개만 추가, lock 파일 git 반영

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Lua Config, Keymap, Plugin 추가/제거 항목

## Related Files
`init.lua`, `lua/sinbin/options.lua`, `lua/sinbin/keymaps.lua`, `lua/sinbin/autocmds.lua`(신규),
`lua/sinbin/plugins.lua`, `nvim-pack-lock.json`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/USAGE.md`(신규)

## Result
- `options.lua`: `cursorline`, `list`/`listchars`, `wrap`/`linebreak`/`breakindent`, `inccommand=split`
- `keymaps.lua`: `<Esc>` nohlsearch, Visual `J`/`K`/`<`/`>`
- `autocmds.lua`(신규): Yank 하이라이트, 커서 위치 복원 (gitcommit/gitrebase 제외)
- `commands.lua`(신규): `:TrimWhitespace` (전체 또는 range, 커서·검색 패턴 보존)
- `plugins.lua`: mini.pairs, mini.surround 추가 및 설정. `nvim-pack-lock.json` 갱신
- `init.lua`: autocmds, commands 로드 추가

## Verification Result (2026-10-01, Windows 11 / Neovim 0.12.5, headless)
- `nvim --headless "+qa"` → 출력 없음, exit 0. checkhealth(`vim.pack`, `vim.health`) ERROR 0 (WARNING은 기존 ripgrep 1건)
- Option 값 적용 확인
- `:w`만으로는 줄 끝 공백 유지, `:TrimWhitespace` 전체 / `:2,2TrimWhitespace` range 동작 확인
- Visual `J`/`K` 줄 이동, `>` 후 Visual 유지, `<Esc>` 후 `v:hlsearch=0`, `gcc` 주석 토글(내장) 확인
- 커서 위치 복원: 일반 파일 30행 복원, `.git/COMMIT_EDITMSG`(gitcommit)는 1행 유지
- Surround: `ysiw"`, `ds"`, `cs"(` → `( hello )`, `cs")` → `(hello)`, `yss)`, Visual `S]`, `cs'"` 확인
- Pairs: `(`/`"` 자동 닫기, `(<BS>` 쌍 삭제 확인
- Keymap 충돌(`:verbose map`): 의도한 덮어쓰기(Visual `J`/`K`/`<`/`>`)만 존재, Normal `s` 매핑 없음, Visual `ys` 제거됨
- `confirm` 기본값 유지(D-007). 첫 설치는 headless에서 진행됨

## Notes
- 사용자 `BufReadPost`는 filetype 감지보다 먼저 실행되어 `vim.bo.filetype`이 비어 있음 → `vim.filetype.match({ buf })`로 판별
- 화면 확인 완료 (2026-10-01, 사용자): Yank 하이라이트 표시, `listchars` 문자 표시, `inccommand` 미리보기 창, `cursorline`

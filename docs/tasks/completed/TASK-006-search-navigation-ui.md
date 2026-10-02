# TASK-006: Phase 3 Search / Navigation + 기본 UI

- **Status:** Completed (2026-10-02)
- **Goal:** 파일·내용·버퍼 검색과 파일 탐색기를 갖추고, 매일 쓰기 편한 기본 UI(테마, 상태바, 아이콘, 키 힌트)를 mini 계열 Plugin으로 구성한다.

## Background
PROGRESS Next Action. 범위는 사용자와 확정 (2026-10-01).
- 사용자 의도: 직접 구성은 유지하되, 아직 직접 작성이 어려우므로 UI를 빠르게 갖추고 싶음
- NvChad 등 설정 프레임워크는 검토 후 채택 안 함 (lazy.nvim 전제, D-001/D-006/D-007과 충돌). 참고 자료로만 사용
- 방식: `vim.pack` + `lua/sinbin/` 구조 유지, [D-008](../../DECISIONS.md) mini 계열을 확장 (사용자 선택 A, snacks.nvim 대신)
- 기본 UI는 원래 Phase 11 범위였으나 이 Task로 당겨옴. 세부 Layout·Mode는 Phase 11에 남김 ([PROJECT.md](../../PROJECT.md) Roadmap)

## Scope

### A. 외부 도구 (Plugin 아님)

| 항목 | 내용 |
|---|---|
| ripgrep | 미설치 확인됨 (`where.exe rg`, `winget list` — 2026-10-01). 설치 후 checkhealth WARNING 해소 확인 |
| Nerd Font | 설치 여부 확인. 미설치 시 설치 또는 `mini.icons` ASCII 스타일로 대체 |

설치 방법(winget / scoop 등)은 Phase 13 자동화를 고려해 사용자와 결정. OS별 차이는 Platform Layer(D-003) 원칙에 맞춰 기록만 하고 자동화는 Phase 13.

### B. Search / Navigation (Plugin)

| 기능 | Plugin | 비고 |
|---|---|---|
| 파일 이름 검색 | `mini.pick` (`files`) | |
| 프로젝트 내용 검색 | `mini.pick` (`grep_live`, `grep`) | ripgrep 사용 |
| 열린 버퍼 전환 | `mini.pick` (`buffers`) | |
| 최근 파일 | `mini.extra` (`oldfiles`) | `mini.pick` 기본 picker에 없음. 필요성 확인 후 추가 |
| 도움말 검색 | `mini.pick` (`help`) | |
| 이전 검색 재개 | `mini.pick` (`resume`) | |
| 파일 탐색기 | `mini.files` | netrw는 비활성화하지 않고 유지할지 결정 |

### C. 기본 UI (Plugin)

| 기능 | Plugin | 비고 |
|---|---|---|
| 파일 아이콘 | `mini.icons` | 다른 mini 모듈이 사용. Nerd Font 필요 |
| 상태바 | `mini.statusline` | Git 정보는 Phase 6 |
| 키 힌트 | `mini.clue` | `<Leader>`, `g`, `z`, window(`<C-w>`) 등 trigger 지정 |
| 알림 창 | `mini.notify` | `vim.notify` 대체 |
| 시작 화면 | `mini.starter` | 최근 파일·검색 진입점 |
| Colorscheme | 후보 비교 후 1개 | 아래 Decisions 참조 |

### Keymap 초안 (PROJECT Keymap 방향의 `<leader>f` File / `<leader>s` Search 그룹)

| Key | 동작 |
|---|---|
| `<leader>ff` | 파일 검색 |
| `<leader>fb` | 버퍼 전환 |
| `<leader>fr` | 최근 파일 |
| `<leader>fe` | 파일 탐색기 (현재 파일 위치) |
| `<leader>sg` | 내용 검색 (live grep) |
| `<leader>sw` | 커서 단어 검색 |
| `<leader>sh` | 도움말 검색 |
| `<leader>sr` | 이전 검색 재개 |

`<leader>e`는 Error/Diagnostic 그룹으로 예약되어 있어 탐색기에 쓰지 않는다.

## Out of Scope
- LSP 심볼 이동, Diagnostic 목록 (Phase 4/5)
- 상태바 Git 정보, Git picker (Phase 6)
- 화면 안 빠른 이동 (flash.nvim, leap 등) — 필요해지면 별도 Task
- Mode별 Layout, 세부 UI 커스터마이징 (Phase 11)
- 외부 도구 설치 자동화 (Phase 13)

## Prerequisites
- TASK-004 (`vim.pack`), TASK-005 (mini 계열 설치 방식, D-008)

## Decisions (2026-10-01 사용자 확인)
1. **ripgrep 설치 방법:** winget (`BurntSushi.ripgrep.MSVC`)
2. **Colorscheme:** tokyonight `moon` (요구: 너무 어둡지 않은 네온 계열 다크, 눈 편안함). 비교 설치 없이 직접 선택
3. **Keymap 초안:** 표대로
4. **`mini.extra` (최근 파일):** 포함
5. **`mini.starter`, `mini.notify`:** 포함
6. **netrw:** 유지
7. **Plugin 설정 분리:** `plugins.lua` → `plugins/{init,ui,editing,search}.lua` ([D-009](../../DECISIONS.md))

## Steps
1. Decisions 확인
2. A: ripgrep 설치, Nerd Font 확인 → checkhealth 재확인
3. B: `mini.pick`, `mini.files`(+ `mini.extra`) 추가 및 Keymap 설정 → 검증
4. C: `mini.icons`, `mini.statusline`, `mini.clue`, (`mini.notify`, `mini.starter`), Colorscheme 추가 → 검증
5. Keymap 충돌 확인 (`:verbose map`)
6. 문서 갱신: USAGE(조작법·Plugin 목록), DECISIONS(D-009 Plugin 선택), ARCHITECTURE(구조 변경 시), PROJECT Roadmap, PROGRESS

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0, ripgrep WARNING 해소
- Scope의 각 picker·탐색기·UI 요소를 실제로 동작 확인 (화면 확인은 사용자)
- Keymap 충돌은 의도한 것만 존재 (RULES Keymap)
- Plugin은 Scope에 명시된 것만 추가, 각 Plugin에 한 줄 이유, lock 파일 git 반영
- USAGE.md에 새 Keymap·Plugin 사용법 반영

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Lua Config, Keymap, Plugin 추가/제거 항목

## Related Files
`lua/sinbin/plugins/{init,ui,editing,search}.lua` (`plugins.lua`에서 분리), `nvim-pack-lock.json`,
`docs/USAGE.md`, `docs/DECISIONS.md`, `docs/PROJECT.md`, `docs/ARCHITECTURE.md`(필요 시)

## Result
- ripgrep 15.2.0 설치 (winget)
- `plugins/init.lua`: Plugin 목록 + 영역별 모듈 로드 (ui → editing → search)
- `plugins/ui.lua`: tokyonight moon, mini.icons/statusline/notify/starter/clue (`<Leader>f` +File, `<Leader>s` +Search 그룹 이름)
- `plugins/search.lua`: mini.pick/extra/files + Keymap 8개
- `plugins/editing.lua`: 기존 `plugins.lua`의 mini.pairs/surround 설정 (내용 변경 없음)
- `nvim-pack-lock.json`: 9개 Plugin 추가 (총 11개)
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-009), VERIFICATION Environment, PROJECT Roadmap

## Verification Result (2026-10-01, Windows 11 / Neovim 0.12.5, headless)
- `nvim --headless "+qa"` → 출력 없음, exit 0
- checkhealth ERROR 0, `ripgrep 15.2.0` OK (기존 WARNING 해소). 단, 설치 전에 열린 Shell은 PATH 미갱신
- `colors_name=tokyonight-moon`, Normal bg `#222436`, `termguicolors=true`
- `<Leader>` Keymap은 추가한 8개뿐, 기존 편집 Keymap(`S`, `ys`/`ds`/`cs`/`yss`, `<Esc>`, Visual `J`) 유지
- `vim.notify` → mini.notify history에 기록됨, `MiniFiles.open()`/`close()` 동작, `MiniExtra.pickers.oldfiles` 존재
- picker 화면 동작: headless에서는 입력 대기로 block → 사용자 화면 확인으로 대체

## Remaining
- [x] Nerd Font: 설치로 결정 (2026-10-02). JetBrainsMono Nerd Font 3.3.0 winget 설치, 레지스트리에 `JetBrainsMono NF` 등록 확인
- [x] Windows Terminal 글꼴을 `JetBrainsMono NF`로 지정 (사용자)
- [x] 사용자 화면 확인 (2026-10-02): 색 테마, 상태바, 아이콘, 시작 화면, `<Space>` 키 힌트, picker, 탐색기
- [x] 완료 처리

## Notes
- 기존 PROGRESS의 "ripgrep WARNING 원인: Git Bash PATH로 추정"은 틀림. ripgrep 자체가 미설치였음 (2026-10-01 `where.exe`, `winget list`로 확인)
- Plugin 설치 명령이 사용자 중단으로 끊기면서 lock 파일이 불완전하게 남았으나, 다음 실행 시 `vim.pack`이 "Repaired corrupted lock data"로 자동 복구함
- 후보로 잠시 설치된 catppuccin, nightfox는 `vim.pack.del()`로 디스크에서 제거됨

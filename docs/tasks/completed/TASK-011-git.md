# TASK-011: Phase 6 Git

- **Status:** Completed (2026-10-02)
- **Goal:** AI Agent나 내가 바꾼 코드를 Neovim 안에서 바로 확인한다. 변경 줄 표시, 변경 묶음(hunk) 이동·미리보기·되돌리기·stage, 줄 단위 이력(blame), 브랜치 표시를 갖춘다.

## Background
PROGRESS Next Action. D-001 Context: 주 작업이 코드 작성에서 Diff 확인으로 이동 → 이 Phase가 핵심.

### 현재 상태 (2026-10-02 확인)
- Neovim에 git 변경 표시 기능 내장 없음. 내장은 `:diffthis` 등 두 버퍼 비교뿐
- Git 2.55.0 있음. lazygit, delta 미설치
- 이미 설치된 것: `mini.statusline`(`mini.git`/`mini.diff`가 있으면 브랜치·변경 수 표시), `mini.extra`(git branches/commits/files/hunks picker)
- `<Leader>g` 그룹 비어 있음, `]h`/`[h` 등 미사용

## Scope (후보)

| 기능 | 후보 | 비고 |
|---|---|---|
| 변경 줄 표시 (줄 번호 옆) | `mini.diff` | 추가/변경/삭제 표시, 상태바 변경 수 |
| hunk 이동 | `mini.diff` | `]h` / `[h` (기본값, 문서 확인 후 확정) |
| hunk 미리보기 (diff 겹쳐 보기) | `mini.diff` overlay 토글 | 바뀌기 전 줄을 겹쳐 표시 |
| hunk stage / 되돌리기 | `mini.diff` | apply·reset 동작 |
| 브랜치 표시, `:Git` 명령, 커서 줄 이력 | `mini.git` | 상태바 브랜치, `:Git blame` 등 |
| 커밋·브랜치·hunk 목록 | `mini.extra` git picker (설치됨) | |
| 외부 수정 자동 반영 | 내장 `checktime` autocmd | Agent가 파일을 바꾸면 버퍼 갱신 |
| 전체 Git UI | lazygit (외부 CLI) | Decisions 2 |

## Out of Scope
- Terminal 일반 UX (Phase 7). lazygit floating 창만 이번에 포함
- GitHub PR·이슈 연동
- merge conflict 전용 UI → 필요 시 별도 Task

## Prerequisites
- TASK-006 (mini 계열, `mini.extra`, `mini.statusline`, `mini.clue`)

## Decisions (2026-10-02 사용자 확인)
1. **Plugin:** gitsigns.nvim ([D-013](../../DECISIONS.md)). 초안 `mini.diff` + `mini.git`은 사용자가 "최대한 사용자 친화적인가" 재검토 요청 → hunk 미리보기 창·자동 inline blame·lazygit 메뉴 UI를 우선해 변경
2. **lazygit:** 이번에 설치 + `<Leader>gg` floating terminal (Terminal 일반 UX는 Phase 7)
3. **외부 수정 자동 반영(`checktime`):** 사용
4. **Keymap:** 아래 표 (초안에서 overlay → 미리보기 창 `<Leader>gp`, 파일 단위·diff·lazygit 추가)
5. **diffview:** 추가 (사용자 요청, 2026-10-02). 원본 sindrets/diffview.nvim은 마지막 commit 2024-06-13이라 유지보수 fork `dlyongemallo/diffview-plus.nvim`(2026-09-30 commit, "actively maintained fork") 사용
6. **현재 파일 변경 이력 `<Leader>gl`:** 추가 (사용자 요청). mini.extra commit picker 대신 diff까지 보이는 `:DiffviewFileHistory %` 사용
7. **diffview 사전 확인 메시지:** `<Leader>gl`이 이력 없는 파일에서 영어 에러(`No git history for the target(s)...`)를 내 원인을 알기 어려움 (사용자 보고) → `<Leader>gv`/`gl` 실행 전 확인 후 `git 저장소 아님` / `파일 버퍼 아님` / `커밋 이력 없음 (아직 commit 안 된 파일)` 알림

### Keymap (`<Leader>g` Git 그룹)

| Key | 동작 |
|---|---|
| `]h` / `[h` | 다음 / 이전 hunk |
| `<Leader>gp` | hunk 미리보기 창 |
| `<Leader>gs` / `<Leader>gr` | hunk stage(stage된 hunk는 unstage) / 되돌리기 (Visual: 선택 줄) |
| `<Leader>gS` / `<Leader>gR` | 파일 stage / 되돌리기 |
| `<Leader>gb` | blame 자세히 |
| `<Leader>gd` | 파일 diff 화면 |
| `<Leader>gv` | 전체 변경 검토 (diffview, `q` 닫기) |
| `<Leader>gl` | 현재 파일 변경 이력 (diffview) |
| `<Leader>gh` / `<Leader>gc` / `<Leader>gB` | hunk / commit / branch picker |
| `<Leader>gg` | lazygit |

## Steps
1. Decisions 확인
2. Plugin 추가·설정, Keymap, mini.clue `+Git` 그룹
3. 샘플 git 저장소에서 표시·이동·stage·되돌리기·blame 검증
4. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-013), PROGRESS

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- git 저장소 파일에서 변경 줄 표시, hunk 이동·미리보기·stage·되돌리기, blame 동작
- git 저장소가 아닌 파일에서 에러 없음
- Keymap 충돌은 의도한 것만 존재
- USAGE에 Git 조작법 반영

## Related Files
`lua/sinbin/plugins/init.lua`, `lua/sinbin/plugins/git.lua`(신규), `lua/sinbin/lazygit.lua`(신규), `init.lua`, `lua/sinbin/plugins/ui.lua`, `lua/sinbin/autocmds.lua`(checktime), `nvim-pack-lock.json`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`

## Result
- lazygit 0.65.1 설치 (winget)
- `plugins/init.lua`: gitsigns.nvim, diffview-plus.nvim 추가 (총 17개), git 모듈 로드
- `plugins/git.lua`(신규): `current_line_blame = true`, `on_attach`에서 버퍼 Keymap, diffview setup(`q` 닫기), `<Leader>gv`/`gl`, mini.extra git picker Keymap
- `lazygit.lua`(신규): floating terminal (`jobstart` `term = true`), 현재 파일의 git root에서 실행, 종료 시 창 닫기 + `checktime`
- `autocmds.lua`: `FocusGained`/`BufEnter`/`TermClose`/`TermLeave`에서 `checktime`
- `plugins/ui.lua`: mini.clue `<Leader>g` +Git 그룹
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-013), VERIFICATION

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5)
임시 git 저장소(커밋 후 2·11행 수정)에서 확인.
- gitsigns attach, head `master`, hunk 2개, sign `2:┃`, `11:┃`
- `nav_hunk("next")` → 2행, inline blame 표시(`Not Committed Yet`)
- `stage_hunk()` → `git diff --cached`에 반영, `reset_hunk()` → 버퍼 원복
- Keymap 13개(+ Visual 2개) desc 확인, 기존 Keymap과 충돌 없음 (`]h`/`[h`/`<Leader>g*` 미사용이었음)
- lazygit: floating 창 + terminal buffer + job 실행, `q` 입력 시 창 닫힘
- 외부 수정 반영: `nvim --embed`를 RPC로 조작 → 파일 외부 수정 후 `FocusGained` → 버퍼가 새 내용으로 갱신, modified 아님
- git 저장소 밖 파일: 에러 없이 열림, gitsigns 미attach
- diffview 사전 확인 (8개 상황): git 밖 파일 gl·gv → `git 저장소 아님`, 저장소 안 untracked 파일 gl → `커밋 이력 없음 (아직 commit 안 된 파일)`, 시작 화면 gl → `파일 버퍼 아님`, 시작 화면 gv(저장소 cwd)·commit된 파일 gl·gv → diffview 열림, gv 두 번 → 닫힘
- diffview (UI attach한 `nvim --embed`를 RPC로 조작): `<Space>gv` → 새 tab, 변경 파일 `a.txt`, `b.txt` → `q` 닫힘 / `<Space>gl` → 이력 `second commit`, `first commit` → `q` 닫힘
- `nvim --headless "+qa"` 출력 없음, exit 0. checkhealth `vim.pack` OK (gitsigns는 healthcheck 미제공 — `:checkhealth gitsigns`는 "No healthcheck found" ERROR, 설정 문제 아님)
- 화면 확인 (사용자, 2026-10-02): 변경 표시·hunk·blame·lazygit·diffview, `<Leader>gl` 이력 없는 파일 메시지 개선 후 승인

## Notes
- autocmd 안의 `:checktime`은 안전한 시점까지 미뤄짐 → headless 스크립트(`+lua`)에서는 재현 안 됨. `nvim --embed` + RPC로 검증 (VERIFICATION 주의사항 추가)
- diffview-plus 첫 설치 시 `version = vim.version.range("*")`로 지정했으나 tag(`v0.38`)가 semver가 아니라 "No versions fit constraint" → startup 에러. 기본 branch로 변경. (`tail -1`로 출력을 잘라 첫 확인에서 에러를 놓쳤음 — 설치 출력은 전체 확인)
- diffview를 headless 스크립트에서 열고 바로 닫으면 비동기 layout 중 "Invalid window id" 에러 → UI attach한 `nvim --embed`(+ `--headless`) RPC 조작에서는 재현 안 됨 (테스트 방식 문제)
- `v:errmsg`의 `E216: No such group or event: FileExplorer *`는 diffview와 무관. mini.files(TASK-006)가 netrw 디렉터리 autocmd를 `silent!`로 제거하며 남기는 값 (화면 메시지 없음, `nvim --clean`에서는 없음)

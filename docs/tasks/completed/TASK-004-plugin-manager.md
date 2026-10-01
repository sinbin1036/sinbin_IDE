# TASK-004: Plugin Manager 선택 및 도입

- **Status:** Completed (2026-10-01)
- **Goal:** Phase 2 이후 Plugin을 추가할 수 있도록 Plugin Manager를 하나 정하고 최소한으로 연결한다.

## Background
TASK-003 Out of Scope에서 분리된 항목. RULES Plugin 원칙("기본 기능으로 충분하면 추가 안 함",
"특정 Plugin 하나에 전체가 종속되지 않게")에 따라 Neovim 0.12 내장 `vim.pack`을 우선 검토한다.

## Scope
- 후보 비교 → 선택을 DECISIONS에 기록
- Plugin Manager 연결 코드 작성 (`lua/sinbin/` 아래, 확정 시 ARCHITECTURE 갱신)
- lock 파일을 git에 포함
- VERIFICATION "Plugin 추가/제거" 항목 구체화

## Out of Scope
- 실제 기능 Plugin 설치 (Phase 2 이후 각 Task)
- Colorscheme / UI

## Prerequisites
- TASK-003 (Core Config 구조)

## Comparison

| 기준 | `vim.pack` (0.12 내장) | lazy.nvim |
|---|---|---|
| 추가 의존성 | 없음 (git만 필요) | Plugin 자체를 bootstrap(git clone)해야 함 |
| 안정성 | 공식 문서상 "experimental, yet stable enough for daily use" | 성숙, 널리 사용 |
| lock 파일 | `nvim-pack-lock.json` (config 경로 = Repository Root) | `lazy-lock.json` |
| Lazy loading | 내장 없음 (`:packadd` 직접 호출) | event/cmd/ft/keys 기반 내장 |
| 설치 후 Build hook | `PackChanged` autocmd | spec의 `build` 필드 |
| 교체 용이성 | `vim.pack.add()` 호출 목록만 존재 → 이전 쉬움 | spec 형식(opts/config/keys)에 Config가 묶이기 쉬움 |
| UI | 업데이트 확인용 확인 buffer | 전용 UI (`:Lazy`) |

근거: `:h vim.pack` (Neovim v0.12.5 runtime `doc/pack.txt`), lazy.nvim 일반 사용 방식.

## Steps
1. 비교 및 선택 (사용자 확인)
2. 연결 코드 작성
3. 테스트 Plugin 추가 → lock 파일 생성 확인 → 제거 → 원상복구 확인
4. 문서 갱신 (DECISIONS, ARCHITECTURE, VERIFICATION)

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- Plugin 추가·제거 흐름과 lock 파일 갱신을 실제로 확인
- 실제 기능 Plugin은 설치되어 있지 않은 상태로 종료

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Plugin 추가/제거 항목

## Related Files
`init.lua`, `lua/sinbin/**`, `lua/sinbin/plugins.lua`, `nvim-pack-lock.json`, `docs/DECISIONS.md` (D-007)

## Result
- 선택: `vim.pack` (사용자 선택, [D-007](../../DECISIONS.md))
- `lua/sinbin/plugins.lua` 추가 (빈 `vim.pack.add({})`), `init.lua`에서 platform 다음에 로드
- `nvim-pack-lock.json` (`{"plugins": []}`) git 관리 시작

## Verification Result (2026-10-01, Windows 11 / Neovim 0.12.5, 임시 디렉터리에서 실행)
- 빈 목록 `vim.pack.add({})` → 에러 없음, lock 파일 미생성
- `nvim --headless "+qa"` → 출력 없음, exit 0
- 테스트 Plugin `tpope/vim-repeat` 설치(`confirm=false`) → `site/pack/core/opt/vim-repeat` 생성, lock 파일에 `rev`·`src` 기록
- `vim.pack.del({'vim-repeat'})` → 디스크에서 제거, lock 파일 `{"plugins": []}`
- checkhealth ERROR 0, `vim.pack` basics/lockfile/plugin directory OK. Lockfile 경로가 Junction 경유 Repository Root임을 확인
- 실제 기능 Plugin 설치 없음

## Notes
- 새 장비에서 lock 파일 기준 일괄 설치되는 동작은 문서상 동작만 확인 (미검증, Phase 13 Installer에서 확인)

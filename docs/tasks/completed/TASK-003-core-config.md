# TASK-003: Phase 1 — Core Config Skeleton

- **Status:** Ready
- **Goal:** Plugin 없이 Neovim 기본 기능만으로 Config 모듈 구조, 기본 Option, Leader Key를 세운다.

## Background
Phase 0 완료. `init.lua`는 비어 있고 Junction으로 로드됨 (ARCHITECTURE Current).
Platform Layer(D-003)와 Plugin 원칙(RULES Plugin)을 고려한 구조가 필요하다.

## Scope
- `init.lua` → `lua/` 모듈 구조 결정 (Option / Keymap / Autocmd 분리 수준)
- 기본 Option (번호, indent, search, clipboard, undo 등 — 실제로 쓸 것만)
- Leader Key 설정 (PROJECT Keymap 방향의 그룹 체계 전제)
- Platform Layer 진입점 위치만 확보 (OS 감지 후 해당 모듈 로드). 내용 구현은 Phase 12

## Out of Scope
- Plugin Manager 선택 및 Plugin 설치 (별도 Task — Neovim 0.12 내장 `vim.pack` 포함 비교)
- 기능별 Keymap (각 Phase에서)
- Colorscheme / UI 커스터마이징

## Prerequisites
- 없음

## Steps
1. 모듈 구조 설계 → 확정 시 ARCHITECTURE Current 갱신 (구조가 중요한 선택이면 DECISIONS)
2. Option, Leader 작성
3. Platform 감지 진입점 작성 (`vim.uv.os_uname()` 등, Windows만 실제 검증)
4. 검증

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- Leader Key와 Option이 실제 적용됨 (`:set <option>?`, `:echo mapleader`)
- OS 분기 코드가 Platform Layer 밖에 없음

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Lua Config 항목

## Related Files
`init.lua`, `lua/**` (생성 예정), `docs/ARCHITECTURE.md`

## Notes
—

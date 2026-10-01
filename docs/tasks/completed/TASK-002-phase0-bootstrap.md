# TASK-002: Phase 0 — Neovim Bootstrap

- **Status:** Completed (2026-10-01) — (A) Junction 채택 ([D-005](../../DECISIONS.md)). 검증: startup exit 0·출력 없음, `stdpath('config')`·`$MYVIMRC`가 Junction 경로, checkhealth ERROR 0
- **Goal:** 이 Repository가 Neovim config로 로드되고, 최소 `init.lua`가 에러 없이 시작되는 상태를 만든다.

## Background
Neovim v0.12.5는 설치되어 있고 기본 config 경로(`%LOCALAPPDATA%\nvim`)는 비어 있다 (VERIFICATION Environment).
Repository는 아직 Git Repository가 아니다. D-004에 따라 Config 전체를 이 Repository에서 관리한다.

## Scope
- Repository ↔ Neovim config 경로 연결 방식 결정 및 적용
- `git init`, `.gitignore`, Git Rule 정의
- 동작 확인용 최소 `init.lua`

## Out of Scope
- Option, Keymap, Plugin Manager, Plugin (Phase 1 이후)
- Platform Layer 구현 (Phase 12)
- Install script (Phase 13)

## Prerequisites
- 연결 방식 결정 (사용자 확인)

## Steps
1. 연결 방식 결정. 후보:
   - (A) Junction: `%LOCALAPPDATA%\nvim` → 이 Repository (관리자 권한 불필요, Repository 위치 유지)
   - (B) Repository를 `%LOCALAPPDATA%\nvim`로 이동/clone
   - (C) `NVIM_APPNAME` 사용 (기존 config와 병행 가능. 단 해당 경로에 여전히 연결 필요)
   결정 결과 → DECISIONS
2. `git init`, `.gitignore` 작성, RULES Git 섹션 정의
3. 최소 `init.lua` 작성
4. 연결 적용
5. 검증 후 README "실행 / 개발", ARCHITECTURE Current, PROGRESS 갱신

## Acceptance Criteria
- `nvim --headless "+qa"`가 출력 없이 exit 0 (이 Repository의 `init.lua`가 로드된 상태에서)
- 이 Repository의 `init.lua`가 실제로 로드됨을 확인 (예: `:echo stdpath('config')` 결과가 연결 경로)
- Git Repository 초기화됨, `.agent/`는 생성하지 않음

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Startup 에러 확인, checkhealth

## Related Files
`init.lua` (생성 예정), `.gitignore` (생성 예정), `README.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/RULES.md`

## Notes
- Repository Root에 `docs/`, `AGENTS.md` 등이 있어도 Neovim은 `init.lua`, `lua/`, `plugin/` 등 정해진 경로만 로드하므로 공존 가능.
- Neovim 0.12에는 내장 Plugin Manager(`vim.pack`)가 있다. Plugin Manager 선택은 Phase 1에서 RULES Plugin 원칙에 따라 결정.

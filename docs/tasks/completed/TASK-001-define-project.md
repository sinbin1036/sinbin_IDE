# TASK-001: Define Project

- **Status:** Completed (2026-10-01)
- **Goal:** 사용자 설명을 바탕으로 Project Context의 TBD 항목을 사실 기반으로 채운다.

## Background
Bootstrap으로 Context 구조만 생성됨. Repository는 비어 있고 Git Repository도 아님.

## Scope
- PROJECT.md 작성 (Current / Planned 구분)
- README.md 한 줄 설명·목적·주요 기술 갱신
- 확정된 기술 선택이 있으면 DECISIONS 기록
- 필요 시 다음 구현 Task(TASK-002) 정의

## Out of Scope
- Feature 구현, Source 코드 작성
- 미확정 Architecture를 Current로 기록
- `.agent/` 생성·수정

## Prerequisites
- 사용자의 프로젝트 설명

## Steps
1. 사용자 설명 수집 (불명확한 점만 질문)
2. PROJECT.md 작성
3. README.md 갱신
4. 확정된 결정 → DECISIONS.md
5. ARCHITECTURE.md `Planned`, RULES.md, VERIFICATION.md 중 확정된 부분만 갱신
6. TASK-002 정의, PROGRESS.md 갱신

## Acceptance Criteria
- PROJECT.md에 TBD가 남아 있다면 이유가 명시됨
- 계획과 현재 구현이 섞여 있지 않음
- PROGRESS의 Next Action이 TASK-002를 가리킴

## Verification
VERIFICATION.md의 Docs 항목 (링크·중복 검사)

## Related Files
`README.md`, `docs/PROJECT.md`, `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/PROGRESS.md`

## Notes
PROJECT, README, ARCHITECTURE(Planned), RULES, DECISIONS(D-001~004), VERIFICATION 작성. 후속: TASK-002.

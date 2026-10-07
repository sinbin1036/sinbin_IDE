# AGENTS.md

AI Coding Agent 최상위 작업 규약. 짧고 안정적으로 유지한다.

## Session Start

1. 이 파일(AGENTS.md) 확인
2. [docs/PROGRESS.md](docs/PROGRESS.md) — 현재 위치 파악
3. [docs/tasks/active/](docs/tasks/active/) — 현재 Active Task 확인
4. [docs/README.md](docs/README.md) — Router로 사용
5. 현재 Task에 필요한 문서만 선택적으로 확인
6. 필요한 Source만 확인
7. 작업 시작

Session 시작마다 하지 않는다: Repository 전체 Scan, docs 전체 읽기,
Architecture 재분석, 기록된 결정 재결정, dependency 전체 재조사.

## Session End

1. 변경 내용 확인
2. 필요한 Verification 수행 ([docs/VERIFICATION.md](docs/VERIFICATION.md))
3. Active Task 상태 갱신 (완료 시 `docs/tasks/completed/`로 이동)
4. [docs/PROGRESS.md](docs/PROGRESS.md) 갱신
5. 새 Architecture Decision → [docs/DECISIONS.md](docs/DECISIONS.md)
6. 실제 Architecture 변경 → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
7. Rule 변경 → [docs/RULES.md](docs/RULES.md)
8. 다음 Action을 PROGRESS에 명확히 남김

실제로 상태가 변경된 문서만 갱신한다.

## 언어

- 사용자에게 하는 답변·보고는 항상 한국어로 한다. (코드 주석·식별자는 기존 코드 관례를 따른다)

## 금지사항

- 근거 없는 Architecture 추론
- DECISIONS 확인 없이 동일 문제 재결정
- 불필요한 전체 Repository Scan / 문서 전체 재독해
- 검증 없이 완료 처리
- 미래 계획을 현재 구현처럼 기록
- 확인하지 않은 환경을 사실로 기록
- `.agent/` 생성·수정 (외부 Observer가 관리하는 Machine-derived State 영역)
- Machine-derived State를 Human Source of Truth(`docs/`)보다 우선시

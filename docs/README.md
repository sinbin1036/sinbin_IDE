# docs — Context Router

모든 문서를 읽지 않는다. 필요한 질문에 해당하는 문서만 연다.

| 질문 | 문서 | 읽을 때 | 읽지 않아도 될 때 |
|---|---|---|---|
| 지금 어디까지 왔나? | [PROGRESS.md](PROGRESS.md) | 매 Session 시작 | — |
| 지금 무엇을 하나? | [tasks/active/](tasks/active/) | 매 Session 시작 | — |
| 프로젝트 목적·범위·용어 | [PROJECT.md](PROJECT.md) | 범위 판단, 신규 기능 기획, 용어 불명확 | Task에 범위가 명시된 일반 구현 |
| 전체 구조·Component·Data Flow | [ARCHITECTURE.md](ARCHITECTURE.md) | Component 경계를 넘는 변경, 새 모듈 추가 | 단일 파일 내부 수정 |
| 개발 규칙 | [RULES.md](RULES.md) | 코드 작성·커밋 전 (해당 섹션만) | 문서만 수정 |
| 과거 기술 선택 이유 | [DECISIONS.md](DECISIONS.md) | 기술/구조 선택을 하려 할 때 (재결정 방지) | 기존 패턴을 따르는 변경 |
| 변경 후 검증 방법 | [VERIFICATION.md](VERIFICATION.md) | 작업 완료 처리 전 | — |
| 특정 Domain 지식 | `domain/` | Task가 해당 Domain을 참조할 때 | 그 외 |
| 완료된 작업 기록 | [tasks/completed/](tasks/completed/) | 과거 작업 맥락이 필요할 때만 | 대부분 |

## 규칙

- 정보는 한 문서에만 둔다. 다른 곳에서는 링크한다.
- `domain/`은 반복적으로 재사용되는 Domain 지식이 생길 때만 만든다.
- `.agent/`는 문서 영역이 아니다 (외부 Observer 관리, 수정 금지).

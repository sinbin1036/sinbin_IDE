# RULES

이 프로젝트에 실제로 적용되는 규칙만 기록한다. (Rule / Reason / Scope)

## Plugin

| Rule | Reason | Scope |
|---|---|---|
| 실제로 사용하는 기능만 추가 | 경량 유지 | 모든 Plugin |
| 동일 기능 Plugin 중복 금지 | 충돌·유지비 방지 | 모든 Plugin |
| Neovim 기본 기능으로 충분하면 Plugin 추가 안 함 | 의존성 최소화 | 모든 Plugin |
| 추가 시 선택 이유를 남김 (중요한 선택은 DECISIONS) | 재검토·제거 판단 근거 | 모든 Plugin |
| 언제든 제거 가능하게, 특정 Plugin 하나에 전체가 종속되지 않게 | 교체 가능성 | Config 전체 |

## Architecture

| Rule | Reason | Scope |
|---|---|---|
| OS 분기(Shell, Path, Package Manager)는 Platform Layer에만 둠 | OS 차이가 Config 전체로 퍼지는 것 방지 | Config 전체 |
| AI Agent를 Neovim Core에 종속시키지 않음 | Agent는 독립 CLI로 교체 가능해야 함 | AI 연동 코드 |

## Keymap

| Rule | Reason | Scope |
|---|---|---|
| [PROJECT.md](PROJECT.md) "Keymap 방향"의 Leader 그룹을 따름 | 일관된 조작 | 모든 Keymap |
| 새 Keymap 추가 전 기존/Plugin Keymap 충돌 확인 | 무음 덮어쓰기 방지 | 모든 Keymap |
| Keymap·Plugin·사용자 명령 변경 시 [USAGE.md](USAGE.md) 갱신 | 조작법 문서와 실제 설정 불일치 방지 | 모든 Keymap, Plugin, 명령 |

## Documentation

| Rule | Reason | Scope |
|---|---|---|
| 정보는 한 문서에만 두고 나머지는 링크 | 불일치 방지 | `docs/` |
| 현재 사실과 계획을 Label로 분리 | 계획을 구현으로 오인 방지 | PROJECT, ARCHITECTURE |
| PROGRESS는 Snapshot, History 누적 금지 | Session 시작 Context 비용 최소화 | PROGRESS.md |
| 확정된 선택만 DECISIONS에 기록 | 미확정 사항의 사실화 방지 | DECISIONS.md |

## AI Agent

| Rule | Reason | Scope |
|---|---|---|
| Session Start/End 절차는 AGENTS.md를 따름 | 일관된 Context 복원 | 모든 Session |
| `.agent/` 생성·수정 금지 | 외부 Observer의 Machine-derived State 영역 | Repository 전체 |
| Observer/연구를 위해 구조·Workflow를 바꾸지 않음 | 프로젝트는 Observer와 독립 | Repository 전체 |

## Git

| Rule | Reason | Scope |
|---|---|---|
| 기본 branch는 `main` | Repository 초기화 시 설정 | Repository |
| AI Agent는 사용자 요청 시에만 commit | 변경 이력의 통제권은 사용자에게 | AI Agent |
| Commit 메시지는 아래 형식을 따르고 본문 bullet을 반드시 포함 | 이력만으로 변경 내용 파악 | 모든 commit |
| 작업은 branch에서 진행하고, 논리 단위로 commit을 나눔 | 변경 단위별 검토·되돌리기 용이 | 모든 작업 |
| PR 본문은 `.github/pull_request_template.md`를 따름 | 원칙 준수·검증 결과를 일관되게 전달 | 모든 PR |

### Commit 메시지 형식

```
type: 제목

- 변경사항 1
- 변경사항 2
```

| type | 의미 | 예시 |
|---|---|---|
| feat | 기능 추가 | 새로운 기능 |
| fix | 버그 수정 | crash, 계산 오류 |
| refactor | 구조 개선 | 코드 구조 변경 |
| chore | 설정/자동파일 | lockfile, generated |
| docs | 문서 | README |
| style | 포맷 | lint, formatting |
| test | 테스트 코드 | unit test |

예:

```
feat: Calibration UI 및 baseline 계산 로직 추가

- FrameFeatures 모델 정의
- CalibrationController FSM 구현
- median/MAD 통계 계산 추가
- UI에서 baseline 값 표시
```

## 작업 목적
<!-- 왜 이 작업을 했는지. 관련 Phase / Task ID (예: Phase 1, TASK-003) -->
-

## 작업 내용
<!-- 이번 PR에서 무엇을 변경했는지 -->
-

## 변경 사항 상세
<!-- 구현/수정한 주요 포인트. 새 모듈·Option·Keymap·Plugin과 그 이유 -->
-

## 프로젝트 원칙 준수
<!-- docs/RULES.md, docs/DECISIONS.md 기준 -->
- [ ] OS 분기는 Platform Layer(`lua/sinbin/platform/`)에만 있음 (D-003)
- [ ] Plugin 추가 시 Neovim 기본 기능으로 대체 불가함을 확인하고 선택 이유를 남김
- [ ] 동일 기능 Plugin 중복 없음, 특정 Plugin 하나에 Config 전체가 종속되지 않음
- [ ] AI Agent를 Neovim Core에 종속시키지 않음 (D-002)
- [ ] Keymap은 Leader 그룹 규칙을 따르고 기존 Keymap과 충돌 없음
- [ ] 기존 DECISIONS와 충돌 없음 / 새 결정은 DECISIONS에 기록 (D-XXX:)

## 영향 범위
<!-- 해당 항목 체크 -->
- [ ] Core Config (`init.lua`, Option)
- [ ] Keymap
- [ ] Platform Layer
- [ ] Plugin / lock 파일
- [ ] LSP / Completion / Diagnostics
- [ ] Git / Terminal / Run·Test / Debug
- [ ] AI Agent 연동
- [ ] 문서 (`docs/`)
- [ ] 기타:

## 테스트 내용
<!-- docs/VERIFICATION.md 기준. 실제 실행한 것만 체크 -->
- [ ] Startup 에러 없음 (`nvim --headless "+qa"`)
- [ ] checkhealth ERROR 0
- [ ] 변경한 기능 수동 확인 (Option 값, Keymap 동작 등)
- [ ] Keymap 충돌 확인 (`:verbose map <key>`)
- [ ] Plugin lock 파일 일관성 (Plugin 변경 시)

## 테스트 상세
<!-- 실행한 명령과 결과 -->
-

## 검증 환경
<!-- 검증하지 못한 OS는 UNVERIFIED로 표시 -->
| OS | Neovim | 결과 |
|---|---|---|
| Windows | | |
| Linux / macOS / WSL / SSH | | UNVERIFIED |

## 체크리스트
- [ ] 불필요한 디버그 코드 / 임시 코드가 없습니다
- [ ] Commit 메시지가 규칙(`type: 제목` + bullet 본문)을 따릅니다
- [ ] 관련 문서를 갱신했습니다 (PROGRESS / Task / ARCHITECTURE / DECISIONS / RULES 중 해당 항목)
- [ ] 계획을 구현된 것처럼 기록하지 않았습니다
- [ ] `.agent/`를 수정하지 않았습니다

## 리뷰 포인트
<!-- 리뷰어가 중점적으로 봐야 할 부분 -->
-

## 알려진 한계 / UNVERIFIED
<!-- 확인하지 못한 환경, 남은 경고, 후속 Task로 넘긴 항목 -->
-

## 참고 사항
-

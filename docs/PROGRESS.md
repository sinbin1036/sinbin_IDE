# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 11 — Custom UI / Layout
- **Status:** Phase 10 AI Agent 완료 (Claude Code·Codex 오른쪽 창, `Alt+a` 왕복). 설치된 Plugin 19개 ([D-009](DECISIONS.md)~[D-017](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))
- Phase 2 기본 Editing UX ([TASK-005](tasks/completed/TASK-005-basic-editing-ux.md))
- Phase 3 Search / Navigation + 기본 UI ([TASK-006](tasks/completed/TASK-006-search-navigation-ui.md))
- Phase 4 LSP / Completion ([TASK-007](tasks/completed/TASK-007-lsp-completion.md))
- Phase 4 Treesitter 구문 강조 ([TASK-008](tasks/completed/TASK-008-treesitter.md))
- Phase 5 Diagnostics 표시·이동·목록 ([TASK-009](tasks/completed/TASK-009-diagnostics.md))
- Phase 5 진단 메시지 혼합 번역 ([TASK-010](tasks/completed/TASK-010-diagnostic-translate.md))
- Phase 6 Git ([TASK-011](tasks/completed/TASK-011-git.md))
- Phase 7 Terminal ([TASK-012](tasks/completed/TASK-012-terminal.md))
- Phase 8 Run / Test ([TASK-013](tasks/completed/TASK-013-run-test.md))
- Phase 9 Debug ([TASK-014](tasks/completed/TASK-014-debug.md))
- Phase 10 AI Coding Agent Integration ([TASK-015](tasks/completed/TASK-015-ai-agent.md))

## In Progress
- [TASK-016](tasks/active/TASK-016-ui-layout.md): Task 작성·Decisions 확정(추천안) 완료. 구현은 다음 세션 (1단계부터)

## Blocked
- 없음

## Unverified
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- Java 디버그 step·변수 확인 (TASK-014, 정지·패널·종료만 확인)
- Codex에 파일 위치 넘기기 (TASK-015, 폴더 신뢰 확인 화면 때문에 미검증)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13). Mason Server·Debug Adapter, Treesitter parser, 외부 CLI(ripgrep, tree-sitter, lazygit)는 lock 파일 밖

## Remaining Phases
- **11 Custom UI / Layout** (진행 중, TASK-016) → 12 Cross-platform Setup → 13 Installer / Bootstrap 자동화 → 14 안정화 및 최적화
- 예정 범위: [PROJECT.md](PROJECT.md) "남은 Phase 계획"

## Deferred
- 빌드 에러 quickfix 연동 (TASK-013)
- 목적별 Mode 전환 Coding / Debug / Git / AI / Focus (Phase 11 기본 배치 이후 별도 Task)
- claudecode.nvim Claude 전용 IDE 연동 (D-017, 필요 시)
- 브라우저(Chrome) 프론트엔드 디버깅 (TASK-014)
- 진단 메시지 번역 규칙 추가 (`diagnostics/rules_ko.lua`, 쓰면서 계속)

## Current Active Task
[TASK-016](tasks/active/TASK-016-ui-layout.md) — VS Code식 기본 배치 (트리·탭·하단 패널·Agent·경로) + 창 이동 체계

## Next Action
TASK-016 1단계 구현 시작 — 문서의 "다음 세션 시작 지점" 순서대로: nvim-tree·mini.tabline 추가 → mini.files 제거·기능 이전 → 하단 영역 공통화 → winbar 경로·명령 팔레트 → 시작 시 트리 자동 열기 → 검증 → 사용자 화면 확인. 브랜치 `feat/ui-layout`.

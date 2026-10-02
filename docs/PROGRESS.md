# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 7 — Terminal 준비
- **Status:** Phase 6 Git 완료 (gitsigns + diffview-plus + lazygit). 설치된 Plugin 17개 ([D-009](DECISIONS.md)~[D-013](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

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

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13). Mason Server, Treesitter parser, 외부 CLI(ripgrep, tree-sitter, lazygit)는 lock 파일 밖

## Current Active Task
없음

## Next Action
Phase 7 (Terminal) Task 작성: 사용자와 범위 확정 (Terminal 창 위치·토글, 여러 Terminal, Shell 종류, AI Agent CLI 실행 위치와의 관계 D-002) → 내장 `:terminal`·`jobstart(term=true)` 우선 검토 후 Plugin 여부 결정. `<Leader>t` Terminal 그룹. lazygit floating 구현(`lua/sinbin/lazygit.lua`)과 공통화 여부 검토. 진단 번역 규칙은 쓰면서 계속 추가.

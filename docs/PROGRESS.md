# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 11 — Custom UI / Layout
- **Status:** Phase 10 AI Agent 완료 (Claude Code·Codex 오른쪽 창, `Alt+a` 왕복). 설치된 Plugin 21개 ([D-009](DECISIONS.md)~[D-018](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

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
- [TASK-016](tasks/active/TASK-016-ui-layout.md): **1·2·3단계 구현·검증·QA 완료, 사용자 피드백 1차 반영(상태바 색 구역·pull/push, 시작 시 오른쪽 Terminal, [D-020](DECISIONS.md)), 사용자 테스트 중** ([D-018](DECISIONS.md), [D-019](DECISIONS.md)). 1단계 배치(bufferline 탭, winbar 경로, 하단 패널 탭, 상태바, Outline·Files, Git 표시, 명령 팔레트) / 2단계 창 이동(열기·이동·숨기기 규칙, Terminal 자동 입력, `Alt+h/j/k/l`) / 3단계 VS Code 키(`Ctrl+P`, `Ctrl+B`, `` Ctrl+` ``)
- [TASK-017](tasks/active/TASK-017-ime-auto-switch.md): Windows 한/영 자동 전환 구현·검증(빌드·상태 읽기), 실제 전환 사용자 확인 대기 ([D-022](DECISIONS.md))

## Blocked
- 없음

## Unverified
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- Java 디버그 step·변수 확인 (TASK-014, 정지·패널·종료만 확인)
- Codex에 파일 위치 넘기기 (TASK-015, 폴더 신뢰 확인 화면 때문에 미검증)
- Git Bash에서 Neovim 실행 시 `:!`·`system()` 깨짐 가능 ('shell'=bash, 'shellcmdflag'=`/s /c`, TASK-016 QA에서 발견, Phase 12)
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
- [TASK-016](tasks/active/TASK-016-ui-layout.md) — VS Code식 기본 배치 + 창 이동 체계 (구현 완료, 사용자 테스트 중)
- [TASK-017](tasks/active/TASK-017-ime-auto-switch.md) — Windows 한/영 자동 전환 (구현 완료, 실제 전환 사용자 확인 대기)

## Next Action
사용자 테스트: TASK-017 실제 한/영 전환(Agent에서 한글 → `Alt+a`로 코드 창 → 영어로), TASK-016 남은 항목(`Alt+h/j/k/l`·`Ctrl+B`·`Ctrl+P`·`` Alt+` `` 전달, 마우스, 아이콘). 문제 없으면 TASK-016·017 완료 처리 → 커밋·PR (브랜치 `feat/ui-layout`, 미커밋).

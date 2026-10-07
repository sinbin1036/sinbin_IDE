# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 12 — Cross-platform Setup (시작 전)
- **Status:** Phase 11 Custom UI / Layout 완료 (VS Code식 배치·창 이동·VS Code 키, PR #15). 설치된 Plugin 21개 ([D-009](DECISIONS.md)~[D-018](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

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
- Phase 11 Custom UI / Layout ([TASK-016](tasks/completed/TASK-016-ui-layout.md))
- Windows 한/영 자동 전환 ([TASK-017](tasks/completed/TASK-017-ime-auto-switch.md))
- 시작 화면 디자인 ([TASK-018](tasks/completed/TASK-018-start-screen.md))

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- 시작 화면 실제 Windows Terminal 표시 (gradient 색·블록 글자·시작 시간, TASK-018은 harness 검증만)
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- Java 디버그 step·변수 확인 (TASK-014, 정지·패널·종료만 확인)
- Codex에 파일 위치 넘기기 (TASK-015, 폴더 신뢰 확인 화면 때문에 미검증)
- Git Bash에서 Neovim 실행 시 `:!`·`system()` 깨짐 가능 ('shell'=bash, 'shellcmdflag'=`/s /c`, TASK-016 QA에서 발견, Phase 12)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13). Mason Server·Debug Adapter, Treesitter parser, 외부 CLI(ripgrep, tree-sitter, lazygit)는 lock 파일 밖

## Remaining Phases
- **12 Cross-platform Setup** (다음) → 13 Installer / Bootstrap 자동화 → 14 안정화 및 최적화
- 예정 범위: [PROJECT.md](PROJECT.md) "남은 Phase 계획"

## Deferred
- 빌드 에러 quickfix 연동 (TASK-013)
- 목적별 Mode 전환 Coding / Debug / Git / AI / Focus (Phase 11 기본 배치 이후 별도 Task)
- claudecode.nvim Claude 전용 IDE 연동 (D-017, 필요 시)
- 브라우저(Chrome) 프론트엔드 디버깅 (TASK-014)
- 진단 메시지 번역 규칙 추가 (`diagnostics/rules_ko.lua`, 쓰면서 계속)

## Current Active Task
없음 — 다음은 TASK-019 설정 패널

## Next Action
설정 패널 TASK-019 (시작 화면 `c`, `:Settings`, `<Space>,`, `settings.json` 저장). 그다음 Phase 12 Cross-platform Setup Task 작성 (TASK-020): PROJECT "남은 Phase 계획" 12번 범위 (Linux / macOS / WSL / SSH Platform Layer: Terminal Shell, `python`, `exe_suffix`, `venv_bin`, Dart/Flutter 경로, clipboard provider, config 연결) + Git Bash에서 Neovim 실행 시 `:!` 깨짐. 한/영 자동 전환은 Windows 전용으로 두고 다른 OS는 범위 판단.

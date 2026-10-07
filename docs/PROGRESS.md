# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 14 — 안정화 및 최적화 (완료, PR #21). 계획된 Phase 모두 완료
- **Status:** Phase 13 Installer 완료 (Windows `setup.ps1`, PR #19, Linux/macOS 스크립트는 Deferred). 자잘한 개선 TASK-022 (PR #20). 설치된 Plugin 21개 ([D-009](DECISIONS.md)~[D-018](DECISIONS.md)). 설정은 `<Space>,` 설정 패널 ([D-024](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

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
- 설정 패널 ([TASK-019](tasks/completed/TASK-019-settings-panel.md), PR #17)
- Phase 12 Cross-platform Setup ([TASK-020](tasks/completed/TASK-020-cross-platform.md), PR #18)
- Phase 13 Windows 설치 스크립트 `setup.ps1` + `:Setup` ([TASK-021](tasks/completed/TASK-021-installer.md), PR #19)
- 자잘한 개선: 강제 종료 확인 창, 오른쪽 Shell 탭 `Agent`, `:Home[!]`, 시작 폴더 홈, 최근 프로젝트 진입 정리, 빈 편집기 ([TASK-022](tasks/completed/TASK-022-small-tweaks.md), PR #20)
- Phase 14 안정화: checkhealth 정리, 시작 속도(디버거·diffview 지연 로드, 약 75ms), `:Setup update`, 안내 메시지·README ([TASK-023](tasks/completed/TASK-023-stabilization.md), PR #21)

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- 시작 화면 실제 Windows Terminal 표시 (gradient 색·블록 글자·시작 시간, TASK-018은 harness 검증만)
- macOS, WSL 아닌 Linux (TASK-020은 WSL Ubuntu만 검증)
- 실제 SSH 접속에서 OSC 52 복사가 로컬 클립보드로 가는지 (TASK-020은 pty 출력으로만 확인)
- WSL의 LSP·Debug(Mason)·ripgrep·lazygit (WSL에 미설치)
- Java 디버그 step·변수 확인 (TASK-014, 정지·패널·종료만 확인)
- Codex에 파일 위치 넘기기 (TASK-015, 폴더 신뢰 확인 화면 때문에 미검증)
- 실제 새 Windows PC에서 `setup.ps1` (TASK-021은 이 PC + 임시 Neovim 데이터 폴더로 검증: Neovim·Git·Runtime winget 설치·UAC, WinLibs gcc PATH, winget 없는 PC 미검증)
- TASK-022 실제 화면: 강제 종료 확인 창 모양·버튼 색, 빈 편집기 안내 모양, 실제 `claude`·`codex`와 함께 쓸 때 (pynvim UI attach로만 검증)
- TASK-023 지연 로드 후 C·Java·Node·Dart 디버그 (Python만 확인, 로드 경로는 같음)

## Remaining Phases
- 없음 (Phase 14까지 완료)
- 예정 범위: [PROJECT.md](PROJECT.md) "남은 Phase 계획"

## Deferred
- Linux / macOS 설치 스크립트 (Phase 13, 사용자 결정 2026-10-07. `scripts/setup/nvim_setup.lua`는 OS 중립이라 재사용 가능)
- 빌드 에러 quickfix 연동 (TASK-013)
- 목적별 Mode 전환 Coding / Debug / Git / AI / Focus (Phase 11 기본 배치 이후 별도 Task)
- claudecode.nvim Claude 전용 IDE 연동 (D-017, 필요 시)
- 브라우저(Chrome) 프론트엔드 디버깅 (TASK-014)
- 진단 메시지 번역 규칙 추가 (`diagnostics/rules_ko.lua`, 쓰면서 계속)

## Current Active Task
없음

## Next Action
계획된 Phase는 없음 → 쓰면서 나오는 개선 / Deferred 항목(빌드 에러 quickfix, 목적별 Mode 전환, Linux/macOS 설치 스크립트 등) 중 선택.

# TASK-014: Phase 9 Debug

- **Status:** Active (2026-10-02)
- **Goal:** 5개 언어에서 breakpoint를 걸고, 한 줄씩 실행하며, 변수·호출 스택을 보는 디버깅을 Neovim 안에서 한다.

## Background
PROGRESS Next Action. Keymap 방향: `<Leader>d` Debug.

### 현재 상태 (2026-10-02 확인)
- Neovim에 디버거 내장 없음 → DAP(Debug Adapter Protocol) Client Plugin 필요 (`mfussenegger/nvim-dap`이 사실상 표준)
- 언어별 Debug Adapter

| 언어 | Adapter | 상태 |
|---|---|---|
| C | `gdb -i dap` (gdb 14+ 내장 DAP) | **있음** — MSYS2 gdb 16.2, DAP 응답 확인 |
| Dart / Flutter | `dart debug_adapter` / `flutter debug_adapter` (SDK 포함) | **있음** — `dart debug_adapter --help` 확인 |
| TypeScript / Node | `js-debug-adapter` (vscode-js-debug) | 미설치 — Mason 설치 가능 |
| Python | `debugpy` | 미설치 — Mason 설치 가능 |
| Java | `java-debug-adapter` (jdtls 확장 bundle) | 미설치 — Mason 설치 가능. jdtls에 bundle 연결 필요 (가장 복잡) |

## Scope (후보)

| 항목 | 후보 |
|---|---|
| DAP Client | `nvim-dap` |
| Debug UI | `nvim-dap-view` (가벼움, 하단 패널 하나) / `nvim-dap-ui` (VS Code식 여러 패널, `nvim-nio` 의존) / UI 없이 내장 widget만 — Decisions 1 |
| 변수 값 줄 끝 표시 | `nvim-dap-virtual-text` — Decisions 2 |
| Adapter 설치 | Mason (js-debug-adapter, debugpy, java-debug-adapter) + SDK·gdb |
| 실행 설정 | 언어별 기본 configuration (현재 파일 디버그, Node script, pytest 등). 프로젝트별은 `.vscode/launch.json` 읽기 지원 여부 — Decisions 3 |

### 언어 진행 순서 (초안)
1. 공통 구조 + C(gdb) — 설치 불필요
2. Python(debugpy), TypeScript/Node(js-debug)
3. Dart/Flutter
4. Java (jdtls bundle 연결)

### Keymap 초안 (`<Leader>d` Debug 그룹 + 기능키)

| Key | 동작 |
|---|---|
| `<Leader>db` | breakpoint 토글 |
| `<Leader>dB` | 조건부 breakpoint |
| `<Leader>dc` / `F5` | 시작 / 계속 |
| `<Leader>dn` / `F10` | 다음 줄 (step over) |
| `<Leader>di` / `F11` | 함수 안으로 (step into) |
| `<Leader>do` / `F12` | 함수 밖으로 (step out) |
| `<Leader>dq` | 디버그 종료 |
| `<Leader>du` | 디버그 UI 열기/닫기 |
| `<Leader>de` | 커서 아래 식 값 보기 |

## Out of Scope
- 원격 디버깅(attach to remote), Docker 안 프로세스 디버깅 → 필요 시 별도 Task
- 테스트 단위 디버그(neotest 연동)
- 브라우저(Chrome) 프론트엔드 디버깅 → Decisions 4

## Prerequisites
- TASK-007 (LSP, Mason), TASK-013 (run.lua 프로젝트 감지 재사용 가능)

## Decisions (2026-10-02 사용자 확인 — 추천안)
1. **Debug UI:** nvim-dap-view
2. **변수 값 줄 끝 표시:** 사용 — nvim-dap-view 내장 virtual text(`eol`)로. nvim-dap-virtual-text는 같은 기능 중복이라 추가 후 제거 (RULES 중복 금지)
3. **`.vscode/launch.json`:** 지원 (nvim-dap 기본)
4. **브라우저 프론트엔드 디버깅:** 제외
5. **기능키:** 사용 (F5/F10/F11/F12)
6. **언어 순서:** C → Python·Node → Dart/Flutter → Java

## Steps
1. Decisions 확인
2. nvim-dap + UI 추가, 공통 Keymap, C(gdb) 연결 → 검증
3. Python, Node → 검증
4. Dart/Flutter → 검증
5. Java → 검증
6. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-016), VERIFICATION, PROGRESS

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0
- 언어별 샘플에서 breakpoint 정지, step over/into/out, 변수 확인, 종료
- Adapter가 없을 때 이유를 알려 줌
- Keymap 충돌은 의도한 것만 존재

## Related Files
`lua/sinbin/plugins/init.lua`, `lua/sinbin/plugins/debug.lua`(신규), `lua/sinbin/platform/windows.lua`, `lua/sinbin/plugins/treesitter.lua`(c parser 추가), `lua/sinbin/plugins/ui.lua`, `nvim-pack-lock.json`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`

## Result
- Plugin: nvim-dap, nvim-dap-view (총 19개). nvim-dap-virtual-text는 설치 후 `vim.pack.del()`로 제거
- Mason: debugpy 1.8.22, js-debug-adapter, java-debug-adapter
- `plugins/debug.lua`(신규): dap-view(`auto_toggle`, sections scopes 우선 + console, virtual text `eol`), breakpoint 아이콘, adapter·configuration 5개 언어 + Flutter, adapter 없음·설정 없음 안내, Keymap `<Leader>db/dB/dc/dn/di/do/dq/du/de`, F5/F10/F11/F12
- `platform/windows.lua`: `exe_suffix`, `venv_bin`, `dart_exe`(SDK의 실제 dart.exe), `flutter_cmd`(flutter.bat이 실행하는 명령)
- `plugins/treesitter.lua`: `c` parser를 nvim-treesitter로 설치 (내장 C query에 `locals` 없음 → virtual text 불가)
- `plugins/ui.lua`: mini.clue `<Leader>d` +Debug
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-016, D-011 보완), VERIFICATION

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5)
UI attach한 `nvim --embed --headless -n`을 RPC로 조작, 임시 샘플. 각 언어: breakpoint → 시작 → 정지 → step → 변수 → 종료.

| 언어 | 정지 위치 | step 후 | 변수 | 패널 / virtual text |
|---|---|---|---|---|
| C (gdb) | `main` 11행 | 10행 | `i=0`, `total=0` | 열림·닫힘 / `total =`, `i =` |
| Python (debugpy) | `add` 2행 | 3행 | `a=0`, `b=0`, `total=0` | 열림·닫힘 / `a =`, `b =`, `result =`, `i =` |
| TypeScript (js-debug, enum 포함) | `global.add` 3행 | 4행 | `a=0`, `b=0`, `sum=0` 등 | 열림·닫힘 / `a =`, `b =` |
| Dart | `add` 2행 | 2 → 2 → 3 → 8 (한 줄에 정지 위치 2개) | `a=0`, `b=0` | 열림·닫힘 / `a =`, `b =` |
| Flutter (Windows 앱) | `main` 4행 | step into → `runApp` (프레임워크 1574행) | `app=MyApp` | 열림·닫힘 |
| Java (Maven, jdtls bundle) | `Hello.main(String[])` 5행 | — | — | 열림 / 종료 |

- `F5`(C) → 디버그 방식 2개 picker / 설정 없는 lua 파일 `F5` → `lua 디버그 설정 없음`
- Keymap desc 확인 (`F5`/`F10`/`F11`/`F12`, `<Space>d*`), 기존 매핑 없음
- 테스트 후 adapter·앱 프로세스 남지 않음 확인
- `nvim --headless "+qa"` 출력 없음, exit 0. `:checkhealth dap` → gdb executable OK
- 화면 확인: **사용자 확인 필요**

## Notes
- breakpoint가 안 걸리던 문제: Write 도구로 쓴 Nerd Font 아이콘(Private Use Area 문자)이 빈 문자열로 저장됨 → sign text가 비어 breakpoint sign이 놓이지 않음(`dap.breakpoints.get()` 비어 있음, `setBreakpoints` 요청 없음). Python으로 `\u` escape해 다시 씀
- Python/Node adapter 무응답: nvim-dap은 libuv로 adapter를 spawn → Windows에서 `.cmd`를 이름으로 못 찾음 → `exepath()` 전체 경로로 바꿨지만 Mason `.cmd` shim(2단 cmd.exe)을 거치면 `initialize` 응답이 없음 → 실제 실행 파일(debugpy venv python, `node dapDebugServer.js`) 직접 실행으로 해결. Dart·Flutter도 같은 이유로 SDK의 실제 dart.exe 사용
- `.cmd` shim 시도 중 남은 debugpy 고아 프로세스 2개는 부모가 종료된 것을 확인하고 정리 (사용자가 열어 둔 `nvim --embed .`은 건드리지 않음)
- 테스트 출력을 파이프(`| tr`)로 받으면 남은 자식 프로세스가 파이프를 붙잡아 명령이 끝나지 않음 → 파일로 받기
- Windows Terminal 기본 `F11` = 전체 화면 → `<Space>di` 안내 (USAGE)

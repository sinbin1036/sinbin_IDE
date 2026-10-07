# TASK-021: Phase 13 Installer — Windows `setup.ps1`

- **Status:** In Progress (2026-10-07) — 구현·검증 완료, 실제 터미널 화면·대화형 Runtime 선택 사용자 확인 대기
- **Goal:** 새 Windows PC에서 저장소를 받은 뒤 `setup.ps1` 하나로 sinbin_IDE 설치를 끝낸다. 설치 과정은 busy.js 스타일(RGB gradient, spinner, progress bar)로 보여주되, 화면에는 실제 설치 상태만 표시한다.

## Background
- 사용자 요청 (2026-10-07): Phase 13 시작, `setup.ps1` Bootstrap 화면. busy.js(저장소 루트, 미추적, 가짜 로그 애니메이션)의 스타일만 재사용
- 범위: [PROJECT.md](../../PROJECT.md) "남은 Phase 계획" 13번 중 **Windows**. Linux/macOS 설치 스크립트는 후속 (같은 Neovim helper 재사용 가능하게 설계)
- config 연결: Windows Junction ([D-005](../../DECISIONS.md)), Linux/macOS symlink ([D-025](../../DECISIONS.md))

## 요구사항 (사용자)
- 저장소 루트 `setup.ps1`, Windows 최초 설치 담당
- 상단 SINBIN IDE SETUP ASCII 로고, 단계별 헤더, spinner, progress bar, 성공/실패 표시
- 설치 대상: Neovim, Git, ripgrep, fd, Neovim plugins, Treesitter parser, LSP/helper 도구
- 언어 Runtime(Java/Python/Node/Flutter)은 강제 설치하지 않음: 선택형
- 이미 설치된 항목은 다시 설치하지 않고 버전·존재만 확인
- 실패 항목은 어느 단계에서 실패했는지 표시
- 완료 시 SINBIN IDE READY, 설치 수, 실패 수, 총 소요 시간
- polling이 아니라 실제 작업 진행에 맞춰 UI 갱신, 가짜 로그 없음

## 조사 (2026-10-07)
- winget 패키지 ID 확인 (`winget show --exact`): `Neovim.Neovim` 0.12.5, `Git.Git` 2.55.0.5, `BurntSushi.ripgrep.MSVC` 15.2.0, `sharkdp.fd` 10.5.0, `tree-sitter.tree-sitter-cli` 0.27.0, `JesseDuffield.lazygit` 0.65.1, `DEVCOM.JetBrainsMonoNerdFont` 3.3.0, `BrechtSanders.WinLibs.POSIX.UCRT` (gcc·gdb) 16.2.0, `Python.Python.3.13`, `OpenJS.NodeJS.LTS`, `EclipseAdoptium.Temurin.21.JDK`. winget v1.29.380
- winget은 출력이 리다이렉트되면 **진행률(%)을 출력하지 않음**. 단계 문장만 시스템 언어(한국어)로 한 줄씩 나옴: `찾음 ...` → `다운로드 중 https://...` → `설치 관리자 해시를 확인했습니다.` → `패키지 설치를 시작하는 중...` (fd 실제 설치로 확인). → winget 항목은 % 없이 spinner + 실제 마지막 출력 줄 + 경과 시간, 성공 여부는 종료 코드로 판단 (문구 파싱 안 함)
- `vim.pack`은 headless 첫 실행 시 확인 없이 설치하고 stderr에 `vim.pack:  14% Installing plugins (3/21) - <name>` 출력 (TASK-020 WSL에서 확인) → 실제 진행률로 사용
- nvim-treesitter `install()`은 Task 반환 (`Task:await(cb(err, ok))`), Mason 2.3.1 `Package:install(opts, cb(success, result))` → 항목별 완료 callback으로 이벤트 출력 가능
- 이 PC에 fd가 없어서 조사 중 winget으로 실제 설치됨 (2026-10-07)

## 설계

### 파일 구조
| 파일 | 역할 |
|---|---|
| `setup.ps1` (루트) | 진입점. 인자 처리, 단계 정의(확인 → 설치), 실패 기록, 요약 |
| `scripts/setup/ui.ps1` | busy.js 스타일 출력: RGB gradient, 로고, 단계 헤더, spinner, gradient progress bar, 여러 줄 갱신 (Windows Terminal 아니면 ASCII spinner) |
| `scripts/setup/proc.ps1` | 외부 명령 실행기: C# `Process` 래퍼(Add-Type)가 stdout/stderr 줄·종료를 queue + `AutoResetEvent`로 알림. 메인 루프는 이벤트가 올 때 깨어나 화면 갱신 (spinner 프레임만 100ms timeout으로 회전). 전체 출력은 로그 파일 |
| `scripts/setup/nvim_setup.lua` | Neovim headless helper (OS 중립, 이후 Linux/macOS 스크립트도 사용): 단계(`SINBIN_SETUP_STEP` = `plugins` / `parsers` / `mason`)별로 실제 설치를 하고 항목마다 `@@sinbin\|<event>\|<name>\|<detail>` 한 줄 출력 |
| `lua/sinbin/plugins/treesitter.lua` | parser 목록을 `return { parsers = ... }`로 내보냄 (helper가 같은 목록 사용). `SINBIN_SETUP`이 있으면 시작 시 자동 설치 안 함 (helper와 동시 설치 방지) |

### 설치 흐름
| # | 단계 | 항목 | 분류 | 없을 때 |
|---|---|---|---|---|
| 1 | Preflight | Windows, PowerShell, winget, 저장소 위치 | — | winget 없으면 설치 단계 실패 처리 (확인만 진행) |
| 2 | Core tools | Git(Git Bash 포함), Neovim(0.12 이상), ripgrep, fd | Required | winget 설치 |
| 3 | Build & helper tools | tree-sitter CLI, C compiler(gcc/clang/zig 중 하나, 없으면 WinLibs gcc·gdb), lazygit, JetBrainsMono Nerd Font | Optional (parser·디버그·UI용) | winget 설치 |
| 4 | Language runtimes | Python, Node.js, Java(JDK), Flutter/Dart | Language-specific | **선택형**: `-With python,node,java` 또는 대화형 선택. 선택 안 하면 "없음"만 표시. Flutter는 winget 패키지 없음 → 안내만 |
| 5 | Config link | `%LOCALAPPDATA%\nvim` → 저장소 Junction | Required | 생성. 다른 폴더가 있으면 `nvim.backup-<시각>`으로 이름 바꾼 뒤 연결 |
| 6 | Neovim plugins | `vim.pack` 21개 (`nvim-pack-lock.json` revision) | Required | headless 실행, `vim.pack` 진행률로 bar |
| 7 | Treesitter parsers | `treesitter.lua` 목록 10개 | Optional | tree-sitter CLI·C compiler 없으면 건너뜀(이유 표시). 병렬 설치, 항목별 줄 |
| 8 | LSP / Debug (Mason) | clangd / vtsls·js-debug-adapter(Node) / basedpyright·ruff·debugpy(Python) / jdtls·java-debug-adapter(Java) | Language-specific | 필요한 Runtime 있는 것만 설치, 나머지는 "건너뜀 (Node 없음)" |
| — | 요약 | SINBIN IDE READY (실패 0) / 실패 목록 | | |

- 각 항목: 먼저 확인(명령 존재·버전) → 있으면 `✔ 이름 버전 (이미 설치됨)`, 설치하지 않음 → 없으면 설치 → 다시 확인해서 버전 표시
- winget 설치 후 PATH를 레지스트리(Machine + User)에서 다시 읽어 같은 창에서 이어서 사용
- 의존 단계: Neovim 실패 → 6~8 건너뜀, config link 실패 → 6~8 건너뜀
- 실패 표시: `✖ 단계 › 항목 › 작업 (exit code)` + 그 작업의 마지막 출력 몇 줄 + 로그 파일 경로
- 요약: 새로 설치 / 이미 있음 / 건너뜀 / 실패 수, 총 소요 시간, 전체 항목 대비 gradient bar
- 인자: `-With <runtime,...>`, `-CheckOnly`(설치 없이 확인만), `-NoPrompt`(대화형 선택 안 함)
- 실행: `powershell -ExecutionPolicy Bypass -File .\setup.ps1` (Windows PowerShell 5.1 호환, 파일은 UTF-8 BOM)

### UI 갱신 방식 (polling 아님)
- 상태 변화(출력 줄, 항목 완료, 프로세스 종료)는 실행기의 이벤트(`AutoResetEvent`)로 메인 루프를 깨워 그 즉시 반영
- 기다리는 동안에는 spinner만 회전 (100ms timeout). 진행률·문구는 이벤트가 올 때만 바뀜
- progress bar 값은 실제 개수(완료 항목 / 전체, `vim.pack` n/N, parser·Mason 완료 수)만 사용. 진행률을 알 수 없는 winget 항목은 bar 없이 spinner + 실제 출력 줄

## 구현 (2026-10-07)
- 설계대로 `setup.ps1`, `scripts/setup/{ui.ps1,proc.ps1,nvim_setup.lua}`, `plugins/treesitter.lua`(목록 반환·`SINBIN_SETUP` 시 자동 설치 안 함). 기록: [D-026](../../DECISIONS.md)
- `.ps1`은 UTF-8 BOM (Windows PowerShell 5.1이 BOM 없는 UTF-8을 ANSI로 읽음)
- 구현 중 고친 문제
  - 실행기가 출력 콜백 안에서 `WaitForExit()` 호출 → 출력 읽기 끝을 기다리며 교착 (winget 끝났는데 계속 대기). `Exited` 이벤트 + 스트림 닫힘(또는 종료 후 1초)으로 끝 판단
  - PowerShell 변수는 대소문자 구분 없음: 지역 `$r`(결과)이 색 초기화 `$R`을 가려 `System.Collections.Hashtable` 출력 → `$RESET`으로 이름 변경
  - `"$DIM전체"`: 한글도 변수 이름 문자라 `$DIM전체` 변수로 읽힘 → `${DIM}`
  - 메서드 호출 괄호 안 `"..." -f a, b`는 쉼표가 메서드 인자 구분 → 변수에 먼저 담음
  - `GetNewClosure()` scriptblock은 별도 모듈 범위라 스크립트 함수를 못 찾음 → 쓰지 않고 동적 범위 사용
- 시작할 때 PATH를 레지스트리에서 다시 읽음 (다른 창에서 막 설치한 도구도 찾게)
- 사용자 확인 (2026-10-07): 바 색이 중간에서 갈라짐 →
  - `Get-GradAt`의 `[Math]::Min(1, $t)`이 `Min(int, int)`로 해석되어 위치가 0/1로 반올림 → gradient가 앞 절반 첫 색 / 뒤 절반 끝 색으로 나뉨 (로고·머리줄 포함). `1.0`/`0.0`으로 수정 → 32칸 32색
  - 바 팔레트를 busy.js 무지개(빨강→주황→초록→하늘, 주황·초록 사이 탁한 올리브)에서 로고와 같은 청록→파랑→보라로 통일, 완료 바·요약도 같은 팔레트 (실패 요약만 빨강 계열) (사용자 선택)

## 추가: Neovim 안에서 실행 (2026-10-07 사용자 요청)
- `:Setup`(`commands.lua`, Plugin보다 먼저 로드) + 시작 화면 `s 설치 / 점검` → `lua/sinbin/setup.lua`가 Platform Layer `setup_cmd`(Windows만)를 새 탭 Terminal에서 실행. 내장 `jobstart`만 사용 (Plugin 로드 실패 시 `sinbin.terminal`도 로드 안 됨)
- 위험 발견·방지: config 경로(Junction)로 실행하면 `$Root`가 링크 경로라 Config link 단계가 "다른 곳을 가리킴"으로 판단해 링크를 백업하고 자기 자신을 가리키는 Junction을 만들 수 있었음 → Neovim은 `fs_realpath` 경로를 넘기고, `setup.ps1`은 링크 경로에서 실행된 경우 "여기서 실행됨"으로 처리
- 검증: 일반 시작 에러 없음, `:Setup` 등록, `setup_cmd` = `powershell ... -File C:/.../sinbin_IDE/setup.ps1`(실제 경로) / Junction 경로로 `-CheckOnly` 실행 → `config link Junction (여기서 실행됨)`, Junction 대상 그대로 / headless에서 `:Setup` → 탭 2개, terminal 버퍼, exit 0, 완료 알림, `q` 매핑, 로그상 8단계 모두 `present` / git을 PATH에서 빼고 빈 데이터 폴더로 시작 → `vim.pack` "No git executable" 에러, `:Setup` 있음·`setup_cmd` 있음·`sinbin.terminal` 미로드·mini.starter 없음
- 미검증: 실제 화면에서 `:Setup` Terminal 표시(headless는 Terminal 버퍼 내용이 비어 로그로만 확인), Plugin 없는 상태에서 `:Setup` 끝까지 실행

## 검증 (2026-10-07, 이 PC)
- 문법: `[Parser]::ParseFile` 3개 파일 오류 0
- `-CheckOnly`: 8단계 확인만, 설치 0, `SINBIN IDE CHECK`
- 새 설치 흐름 (`XDG_DATA_HOME`/`STATE`/`CACHE` = 임시 폴더, `fd` winget 제거 상태, `-NoPrompt`): fd winget 설치 3.1s → 버전 10.5.0, Plugin 21개 새로 설치(vim.pack 진행률 bar), parser 10개 병렬 설치(로그에 다운로드·`Compiling parser`, `.so` 10개 생성), Mason 8개 설치 → `SINBIN IDE READY` 52/52, 새로 설치 40·이미 있음 12·실패 0, 58.8s, exit 0
- 다시 실행: 52개 모두 이미 설치됨, 5.4s. 그 데이터로 `nvim --headless +qa` 에러 없음
- 실패 표시 (dot-source 후 없는 winget ID `Sinbin.DoesNotExist`, Mason 없는 패키지): `✖ bogus failed winget install 실패 (exit 0x8A150014)` + winget 실제 출력 줄, Mason 그룹 `✖ not-a-package not in Mason registry`, 요약 `SETUP INCOMPLETE`·실패 목록(단계 › 항목 › 작업)·로그 경로
- 화면 갱신: 출력 파일의 `\r`/`ESC[2K`/`ESC[nF`를 재생해 최종 화면 확인. winget 줄은 winget 출력 줄이 올 때마다 문구 변경, 그룹 줄은 helper 이벤트마다 행 상태 변경
- 일반 시작 `nvim --headless +qa` 에러 없음, `require('sinbin.plugins.treesitter').parsers` = 10개
- **미검증 (사용자 확인 필요):** 실제 Windows Terminal에서 화면 모양(gradient·spinner·제자리 갱신·로고 배치), 대화형 Runtime 번호 선택, Runtime winget 설치(이 PC에 모두 있음), 새 PC에서 Neovim·Git winget 설치(UAC), WinLibs 설치 후 gcc PATH, config link 백업 경로, winget 없는 PC

## Acceptance Criteria
- 새 PC 흐름: 저장소 받기 → `setup.ps1` → `nvim` 실행 시 Plugin·parser·LSP 준비됨
- 이미 설치된 항목은 재설치 없이 버전 표시
- Runtime은 선택한 것만 설치, Mason 항목은 Runtime 유무에 따라 설치/건너뜀
- 실패 시 단계·항목·작업과 출력 일부 표시, 끝까지 진행 후 요약
- 완료 화면: SINBIN IDE READY, 설치 수, 실패 수, 총 소요 시간
- 화면의 모든 상태가 실제 작업 결과에서 나옴 (가짜 로그 없음)

## Related Files
`setup.ps1`, `scripts/setup/{ui.ps1,proc.ps1,nvim_setup.lua}`, `lua/sinbin/plugins/treesitter.lua`, `README.md`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/PROJECT.md`(Dependency 분류 확정)

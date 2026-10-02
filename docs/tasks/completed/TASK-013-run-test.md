# TASK-013: Phase 8 Run / Test

- **Status:** Completed (2026-10-02)
- **Goal:** 프로젝트 종류를 자동으로 감지해, 언어와 상관없이 같은 키로 실행·빌드·테스트하고 결과를 하단 Terminal에서 본다.

## Background
PROGRESS Next Action. PROJECT Scope: "프로젝트 종류 감지 후 공통 키(`<leader>r`)로 실행 명령 자동 선택".
Keymap 방향: `<Leader>r` Run, `<Leader>x` Test.

### 현재 상태 (2026-10-02 확인)
- 내장: `:make` + `'makeprg'` + `:compiler` + quickfix, `vim.system()`. 실행 기반은 TASK-012 `terminal.lua`
- 설치된 도구: npm, pnpm, npx, mvn, flutter, dart, gcc
- 미설치: yarn, bun, pytest(`python -m pytest` 불가), uv, poetry, gradle, make, cmake

## Scope (후보)

### 프로젝트 감지 → 명령 (초안)

| 감지 기준 (가까운 상위 폴더) | Run | Build | Test |
|---|---|---|---|
| `package.json` (lock 파일로 npm/pnpm 구분) | `scripts` 목록에서 선택 (`dev`/`start` 우선) | `build` script | `test` script |
| `pubspec.yaml` + Flutter (`flutter` 의존성) | `flutter run` | `flutter build` (대상 선택) | `flutter test` |
| `pubspec.yaml` (Dart만) | `dart run` | `dart compile exe` | `dart test` |
| `pom.xml` | `mvn spring-boot:run` (Spring Boot일 때) / `mvn exec:java` | `mvn package` | `mvn test` |
| `pyproject.toml` / `requirements.txt` / `.py` 파일 | `python <현재 파일>` | — | `python -m pytest` (pytest 설치 필요) |
| `.c` 파일 (Makefile 없음) | `gcc` 컴파일 후 실행 (현재 파일) | `gcc` 컴파일 | — |

- 프로젝트별로 명령을 바꾸고 싶을 때: 프로젝트 루트의 설정 파일로 덮어쓰기 — Decisions 3

### 실행 위치·Keymap (초안)

| Key | 동작 |
|---|---|
| `<Leader>rr` | Run |
| `<Leader>rb` | Build |
| `<Leader>rl` | 마지막 명령 다시 실행 |
| `<Leader>rs` | 실행 중인 명령 중지 |
| `<Leader>rt` | 명령 목록에서 골라 실행 (picker) |
| `<Leader>xx` | 전체 Test |
| `<Leader>xf` | 현재 파일 Test |

- 실행 결과는 전용 하단 Terminal("run")에 표시, 같은 Terminal 재사용

## Out of Scope
- 개별 테스트 함수 단위 실행·테스트 결과 트리 UI (neotest 등) → 필요 시 별도 Task
- 빌드 에러를 quickfix로 파싱 (`errorformat`) → Decisions 4
- Debug (Phase 9)

## Prerequisites
- TASK-012 (`terminal.lua`)

## Decisions (2026-10-02 사용자 확인 — 추천안)
1. **구현:** 자체 모듈 `lua/sinbin/run.lua` ([D-015](../../DECISIONS.md))
2. **대상·명령:** 초안대로. Flutter는 `flutter run`(기기 매번 선택), Java는 Maven만, C는 단일 파일
3. **프로젝트별 명령 덮어쓰기:** 사용 — `<root>/.sinbin/run.json`
4. **빌드 에러 quickfix 연동:** 나중에
5. **Keymap:** 초안대로

### 구현 중 판단
- 명령은 shell command line으로 만들고 Windows는 Platform Layer `terminal_exec`(`bash -c`)로 실행: npm·mvn·flutter는 확장자 없는 shell script와 `.cmd`/`.bat`이 함께 있어 직접 spawn 시 dartls(TASK-007)와 같은 문제 가능
- Python 실행 파일 이름은 Platform Layer `platform.python` (Windows `python`, 그 외 기본 `python3`)
- 경로는 sh용 작은따옴표 인용 + `/` 구분자
- Flutter build는 대상이 필요해 `<Leader>rb` 대신 `<Leader>rt` 목록(windows/web/apk)으로

## Steps
1. Decisions 확인
2. 감지·명령 매핑·실행 모듈 작성, Keymap, mini.clue 그룹
3. 언어별 샘플 프로젝트로 감지·실행·테스트 검증
4. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-015), PROGRESS

## Acceptance Criteria
- Startup 에러 없음
- 언어별 샘플 프로젝트에서 감지와 Run/Build/Test 명령 실행
- 감지 실패 시 이유를 알려 줌 (에러 없음)
- 실행 결과가 하단 Terminal에 표시, 재실행·중지 동작
- Keymap 충돌은 의도한 것만 존재

## Related Files
`lua/sinbin/run.lua`(신규), `lua/sinbin/platform/windows.lua`, `lua/sinbin/plugins/search.lua`(`<Leader>rt`), `lua/sinbin/terminal.lua`, `init.lua`, `lua/sinbin/plugins/ui.lua`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`

## Result
- `run.lua`(신규): detector 4종(node / dart·flutter / maven / python) + 단일 파일(python, c), 가장 가까운 marker 우선, `.sinbin/run.json` 덮어쓰기, `task`/`rerun`/`stop`/`commands`/`run_item`, Keymap `<Leader>rr/rb/rl/rs`, `<Leader>xx/xf`
- `terminal.lua`: `exec(id, cmd, opts)`(전용 하단 Terminal, 이전 job 중지 후 같은 창 재사용, 출력 유지, 편집 창으로 focus 복귀), `stop(id)`
- `platform/windows.lua`: `terminal_exec`(`bash -c`), `python = "python"`
- `plugins/search.lua`: `<Leader>rt` Run 명령 목록 picker
- `plugins/ui.lua`: mini.clue `<Leader>r` +Run, `<Leader>x` +Test
- `init.lua`: run 모듈 로드
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-015)

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5)
감지 (headless, `require("sinbin.run").detect()`):
- pnpm 프로젝트(`pnpm-lock.yaml`) → `node (pnpm)`, run `pnpm run dev`, build/test script, test_file `-- <파일>`, scripts 3개 목록
- Flutter `pubspec.yaml`(`sdk: flutter`) → `flutter run`, build 없음(목록 4개), `flutter test`
- Spring `pom.xml` → `mvn spring-boot:run`, `mvn package`, `mvn test -Dtest=AppTest`
- `.sinbin/run.json` → `custom + .sinbin/run.json`, `{file}` 치환
- 사용자 샘플(nvim_test): typescript(scripts 없음) → node, 명령 없음 / python → pyproject 감지 / java(Spring·exec 아님) → run 없음, build·test 있음 / dart → dart run·test / c → gcc / toml → `프로젝트 감지 안 됨`

실행 (UI attach한 `nvim --embed --headless -n` RPC):
- C 단일 파일 `<Space>rr` → gcc 컴파일 후 실행 출력 `HELLO_42`, 편집 창으로 focus 복귀 / `<Space>rl` 재실행 동일
- pnpm `<Space>rr` → `DEV_OK`, `<Space>xx` → `TEST_OK`, build script 없을 때 `<Space>rb` → `node (pnpm): build 명령 없음 (...)`
- 장시간 명령(`setInterval`) 실행 중 `<Space>rs` → job 종료, 해당 node 프로세스 0개 확인 / 다시 `<Space>rs` → `실행 중인 명령 없음`
- Python 단일 파일 `<Space>rr` → `PY_42`
- 프로젝트 아닌 파일 `<Space>rr` → `프로젝트 감지 안 됨 (...)`, 실행 전 `<Space>rl` → `다시 실행할 명령 없음`
- `nvim --headless "+qa"` 출력 없음, exit 0
- 화면 확인 (사용자, 2026-10-02): 파일/프로젝트 범위 분리 재설계, 입력 받는 파일 실행, 탐색기 `g.`, Node 도구 선택 수정 후 승인

## 추가 변경 (사용자 보고, 2026-10-02)
- `nvim .` 직후 등 파일이 아닌 화면에서 `<Space>rr` → `파일 버퍼 아님`으로 실행 불가 → 파일이 아니면 현재 작업 폴더 기준으로 감지. 파일이 필요한 명령(test_file, Python·C 파일 실행, dart compile, `{file}` 포함 override)은 제외하고 `파일을 열고 실행하거나 <Space>rt에서 선택` 안내
- 검증: `nvim .`(mini.files) / 시작 화면(mini.starter) / Terminal 창에서 `<Space>rr` → `pnpm run dev` 실행(`DEV_OK`), 탐색기에서 `<Space>xf` → 안내 메시지, 프로젝트 아닌 폴더 시작 화면 → `프로젝트 감지 안 됨 (현재 폴더: ...)`. 파일 기준 감지 회귀 없음

## 재설계: 파일 / 프로젝트 범위 분리 (사용자 피드백, 2026-10-02)
- 문제: `<Leader>rr`이 Python 프로젝트에서는 현재 파일, Node 프로젝트에서는 `dev` script를 실행해 키만 보고 무엇이 도는지 알 수 없음. `<Leader>fe` 탐색기는 작업 폴더를 바꾸지 않아 front/back 구조에서 프로젝트 실행 기준이 모호
- 결정: 소문자 = 현재 파일(`rr`/`rb`/`xf`), 대문자 = 프로젝트(`rR`/`rB`/`xx`). 프로젝트는 현재 파일의 가장 가까운 marker, 파일이 아니면 작업 폴더, 작업 폴더에 없으면 하위 프로젝트 선택. 탐색기 `g.` = 작업 폴더 변경 (처음엔 `gc`, 아래 참고). 실행 시 `▶ 명령 (폴더/)` 알림. `<Leader>rt` 목록에 `[파일]`/`[프로젝트]`
- 파일 명령: Python `python`, C `gcc` 후 실행, JS `node`, TS `node --experimental-transform-types --no-warnings`(Node 22.19, enum 포함 실행 확인), TSX/JSX 단독 실행 안 됨, Dart `dart run`/`dart compile exe`/`dart test`, Flutter `flutter run -t`/`flutter test`, Java(Maven) `mvn -q compile exec:java -Dexec.mainClass=<package.Class>`, Java 단일 `java 파일`
- 프로젝트 명령 추가: Python 루트 `main.py`/`app.py`/`manage.py runserver`, C `Makefile`(`make`)/`CMakeLists.txt`(`cmake`)
- `.sinbin/run.json`: 파일 범위 키 `run_file`/`build_file`/`test_file` 추가, run.json만 있는 폴더도 프로젝트로 인식
- 검증 (UI attach한 `nvim --embed` RPC, 임시 monorepo):
  - front/src/app.ts `rr` → TS 파일 실행 `FRONT_FILE_42` / `rR` → `npm run dev (front/)` / `rb` → `TS/JS 파일 빌드 없음 (...)` / `rt` → `[파일]`, `[프로젝트]` 항목
  - back/src/server.js `rR` → `npm run start (back/)` / `rr` → `node server.js`
  - 루트 시작 화면 `rR` → 하위 프로젝트 4개 picker, `back` 선택 → `npm run start (back/)`
  - `nvim .` 탐색기에서 front에 `gc` → 작업 폴더 `front`, 알림 표시 → `rR` → `npm run dev`
  - index.py(프로젝트 아님) `rr` → `python index.py`, `rb` → `Python은 빌드 없음`, `rR` → `프로젝트 감지 안 됨 (파일 실행: <Space>rr)`
  - C `rr` → `HELLO_42`, Dart `rr` → `DART_FILE`, Java(Maven) `rr` → `mvn exec:java` 실행 `JAVA_FILE`

## 입력 받는 파일 실행 (사용자 보고, 2026-10-02)
- 보고: `index.py`(`input()`으로 숫자 입력)에서 `<Space>rr`이 "안 되는 것 같음"
- 원인: 실행은 되었으나 `input()`이 안내 문구 없이 대기 → 빈 Terminal로 보이고, focus가 편집 창에 남아 입력이 코드 창으로 감
- 수정: 파일 명령은 `terminal.exec(..., { focus = true })`로 run Terminal에 들어가 Terminal 모드로 시작. 명령이 끝나면 `stopinsert` (Terminal 모드에서 다음 키가 끝난 Terminal을 닫아 출력이 사라지는 것 방지). 프로젝트 명령은 기존대로 편집 창 유지. `<Leader>rl`·`<Leader>rt`도 범위에 맞게 유지
- 검증 (실제 `C:/Users/bro/Desktop/sb_git/index/index.py`, UI attach한 `nvim --embed`): `<Space>rr` → focus Terminal, mode `t` → 키 입력 `3<Enter>` → 별 출력 후 종료, mode `nt` → `j` 입력 후에도 출력 유지 / 프로젝트 `<Space>rR` → focus 편집 창 유지

## 관련 수정: Git picker 저장소 확인 (사용자 보고, 2026-10-02)
- 보고: git 저장소가 아닌 `sb_git/index`에서 `<Space>gc` → mini.extra Lua 에러 (`pickers.git_commits could not find Git repo`). 탐색기 `gc`(작업 폴더 변경)와 혼동 가능
- 수정: `plugins/git.lua`의 `<Leader>gh`/`gc`/`gB`도 `<Leader>gv`/`gl`과 같은 사전 확인 → `git 저장소 아님` 알림 (TASK-011 보완)
- 검증: 저장소 밖에서 세 키 모두 `git 저장소 아님`, picker 안 열림 / 저장소 안 `<Space>gc` → 커밋 2개 picker
- 탐색기 작업 폴더 키를 `gc` → `g.`로 변경 (사용자 선택): `gc`는 일반 창에서 내장 주석 키, `<Space>gc`는 커밋 목록이라 혼동. `g.`는 Vim 기본·mini.files 기본 키와 겹치지 않음

## Node 도구 선택 수정 (사용자 보고, 2026-10-02)
- 보고: `insystem/qwer/samhyeon_web`(Next.js)이 yarn으로 잡힘
- 원인: `package-lock.json`과 `yarn.lock`이 함께 있고(같은 commit), lock 파일 우선순위가 yarn > npm. yarn은 이 PC에 미설치라 실행 실패
- 수정: `packageManager` 필드(설치된 경우) → lock 파일 pnpm → yarn → bun → npm 중 도구가 설치된 첫 번째 → npm. 건너뛴 lock/필드는 kind에 표시. 테스트용 `M.current_project()` 추가
- 검증: samhyeon_web → `node (npm; yarn.lock 있지만 도구 미설치)`, `npm run dev` (사용자 저장소 변경 없음, 실행 안 함) / lock 둘 다 → npm / yarn.lock만 → npm + 안내 / pnpm-lock + package-lock → pnpm / `packageManager: pnpm@9` → pnpm / `packageManager: yarn@4` → npm + 안내

## Notes
- C 빌드는 소스 옆에 실행 파일(`<이름>.exe`)을 만듦 → 검증은 사용자 샘플 폴더가 아닌 임시 폴더 사본으로 수행
- headless 감지 테스트에서 Git Bash 형식 경로(`/c/Users/...`)를 넘기면 marker를 못 찾음 (테스트 입력 문제, 실제 Neovim은 Windows 경로)

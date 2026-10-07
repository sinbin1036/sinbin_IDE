# TASK-018: 시작 화면 디자인 (SINBIN 로고 런처)

- **Status:** Done (2026-10-07) — 구현·harness 검증 완료, 사용자 지시로 현재 상태에서 마무리. 실제 Terminal 화면(gradient 색·시작 시간)은 사용자 확인 전
- **Goal:** 파일 없이 `nvim`을 실행했을 때 나오는 첫 화면(mini.starter)을 SINBIN 대형 로고 + 미니멀 런처로 바꾼다.

## Background
사용자 요청 (2026-10-07). 기본 mini.starter 화면(인사말·기본 메뉴·최근 파일)을 프로젝트 전용 화면으로.
로고 디자인은 저장소 루트의 `busy.js` `GLYPHS`/`banner`(블록 문자 + 좌→우 gradient)를 참고. `busy.js`는 참고용, 커밋하지 않음.

## Decisions (2026-10-07 사용자 결정)
1. 구성: 미니멀 런처, 전체 중앙 정렬
2. 상단: `busy.js` `GLYPHS` 블록 문자 SINBIN 대형 로고(6줄, 폭 42), 아래 작은 `I D E`. 애니메이션·sleep 없이 즉시 표시
3. Gradient: tokyonight moon 계열 고정 색 Blue → Purple → Pink (좌→우)
4. Actions 2열: `f` 파일 찾기 / `g` 내용 검색 / `e` 파일 탐색기 / `c` 설정 열기 / `q` 종료 (`a` Claude Code는 추가 요청으로 제거)
5. Recent Files·Git 정보: 넣지 않음
6. Recent Projects: 3~5개, 숫자키 `1` `2` `3`…으로 선택. **작업 폴더를 바꿀 때마다 목록 파일에 저장 (B안)**
7. 하단: plugin 수 + 시작 시간, Neovim/IDE Tip 랜덤 1개
8. 좁은 창: 대형 로고 대신 `SinBin IDE` 한 줄
9. (추가 요청) 시작 화면에서는 오른쪽 영역 Terminal을 띄우지 않고, 프로젝트에 들어가면(파일을 열면) 띄움

## 구현 (2026-10-07)
- `lua/sinbin/starter.lua`: mini.starter `header`/`footer`는 비우고 content hook `layout`이 전체 배치 → `aligning("center", "center")` ([D-023](../../DECISIONS.md))
  - 로고: `busy.js` `GLYPHS` 그대로, 글자마다 unit, 열 1~42마다 `SinbinStarterLogoN` (`#82aaff` → `#c099ff` → `#ff007c`, bold, ColorScheme 시 재설정). `I D E`는 `Comment` 색
  - Actions: item 이름 첫 글자가 키(`f  파일 찾기`), `evaluate_single = true`라 키 하나로 실행. `f`/`g`/`e`는 `<Leader>ff`/`sg`/`fe` Keymap을 `maparg`로 불러 실행, `c`는 config 폴더 파일 찾기(TASK-019에서 설정 패널로 바뀜), `q`는 `:qall`
  - Recent Projects: 현재 작업 폴더 제외 최대 5개, `1`~`5`, `~/` 표시·`/` 구분자, 로고 폭(좁으면 창 폭)을 넘으면 앞부분 `…`로 생략
  - footer: `N plugins · Nms` (`init.lua` 맨 앞 `vim.g.sinbin_start`부터 첫 화면 그릴 때까지), Tip은 Session마다 하나
  - 창 폭 < 46(로고 42 + 4)이면 `SinBin IDE` 한 줄 gradient
- `lua/sinbin/projects.lua`: 시작 시(UI 있을 때만)·전역 `DirChanged`에 기록, 최근 순 10개, 중복·홈 폴더·없는 폴더 제외
- 작업 폴더 변경 시 시작 화면 다시 그림 (선택한 프로젝트는 목록에서 빠지고 이전 폴더가 들어옴)
- `lua/sinbin/agent.lua`: VimEnter 시 시작 화면이면 Shell을 미루고, 일반 파일 버퍼(`buftype` 빈 값, floating 아님)에 처음 들어갈 때 오른쪽 영역이 없으면 Shell을 엶 (`root_dir()` = 그 파일의 git root). 그 전에 `<Space>ac` 등으로 오른쪽 영역이 열렸으면 건드리지 않음

## 검증 (2026-10-07)
- `nvim --headless "+qa"` 에러 없음
- UI attach한 `nvim --embed` RPC (160×40): 로고 6줄·`I D E`·Actions 2열·footer 가운데 표시, 로고 highlight 42개 열 그룹 적용(1열 `#82aaff`, 42열 `#ff007c`), 커서 첫 item
- 프로젝트 2개 추가 → Recent Projects `1`/`2` 표시, `1` → 작업 폴더 변경·목록 갱신·파일 순서 확인. 긴 경로 생략 확인
- 창 폭 40 → `SinBin IDE` 한 줄, 정렬 유지. 오른쪽 영역 Terminal을 연 뒤(시작 화면 폭 95)에도 가운데
- `f`/`g`/`c` → 검색 창(Files·Grep live, `c`는 cwd = config 폴더), `e` → mini.files, `q` → 오른쪽 Terminal 실행 중에도 종료. `:messages` 에러 없음
- 테스트로 바뀐 `projects.txt`는 원래대로 되돌림
- 오른쪽 Shell (`nvim --embed -n`, `--headless` 없이: `--headless`면 UI attach 전에 VimEnter가 지나가 시작 시 Shell 경로가 실행되지 않음): 시작 화면 → 창 1개(Shell 없음) / `f`로 `init.lua` 열기 → 오른쪽 Shell 생김 / `nvim init.lua` → 시작 시 Shell / 오른쪽 영역에 다른 Terminal을 먼저 연 뒤 파일 열기 → 추가 Shell 없음
- **사용자 확인 필요:** 실제 Windows Terminal에서 gradient 색·글꼴 표시, 시작 시간 수치 (harness에서는 350~540ms)

## Acceptance Criteria
- `nvim` 실행 시 로고(gradient)·`I D E`·Actions 2열·Recent Projects·footer가 가운데에 즉시 표시
- 각 키가 해당 동작 실행 (`f`/`g`/`e`는 기존 Keymap과 같은 동작)
- 숫자키로 프로젝트 선택 → 작업 폴더 변경, 목록 갱신
- 작업 폴더 변경이 목록 파일에 기록됨 (최근 순, 중복 없음)
- 창이 로고보다 좁으면 `SinBin IDE` 한 줄, 창 크기 변경·오른쪽 영역 열림 후에도 가운데
- Startup 에러 없음

## Related Files
`lua/sinbin/starter.lua`, `lua/sinbin/projects.lua`, `lua/sinbin/plugins/ui.lua`, `init.lua`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`

-- Korean mixed-style rules for diagnostic messages (TASK-010).
-- Goal: read an error in half a second while keeping the original dev terms.
-- - Core terms stay English: type, variable, argument, parameter, property, class,
--   function, method, import, return, null, interface, attribute, member, field,
--   module, ...
-- - Descriptive words in Korean: 할당, 선언, 정의, 초기화, 변환, 누락, 중복
-- - Short endings, one form per situation:
--     not found / cannot be resolved -> 찾을 수 없음    undefined -> 정의 안 됨
--     does not exist / no such       -> 없음            unused    -> 사용 안 됨
--     cannot assign                  -> 할당할 수 없음  cannot convert -> 변환할 수 없음
--     expected / required            -> 필요            missing   -> 누락
-- - Stay close to the original wording; never add information it does not have.
-- - A fixed noun follows each quoted name ('x' variable을) so particles never
--   depend on the name.
--
-- Each rule: { Lua pattern for the whole first line, replacement }.
-- First matching rule wins, so specific patterns come before general ones.
-- Patterns come from real server messages (docs/tasks TASK-010).

return {
  -- TypeScript / JavaScript (vtsls)
  { "^Type '(.-)' is not assignable to type '(.-)'%.$", "'%1' type을 '%2' type에 할당할 수 없음" },
  { "^Argument of type '(.-)' is not assignable to parameter of type '(.-)'%.$", "'%1' type argument를 '%2' type parameter에 할당할 수 없음" },
  { "^Cannot find name '(.-)'%. Did you mean '(.-)'%?$", "'%1' name을 찾을 수 없음 (혹시 '%2'?)" },
  { "^Cannot find name '(.-)'%.$", "'%1' name을 찾을 수 없음" },
  { "^Expected (%S+) arguments?, but got (%S+)%.$", "argument %1개 필요, %2개 전달됨" },
  { "^Property '(.-)' does not exist on type '(.-)'%.$", "'%2' type에 '%1' property 없음" },
  { "^Property '(.-)' is missing in type '.-' but required in type '(.-)'%.$", "'%2' type에 필요한 '%1' property 누락" },
  { "^Object literal may only specify known properties, and '(.-)' does not exist in type '(.-)'%.$", "'%2' type에 '%1' property 없음" },
  { "^Property '(.-)' is private and only accessible within class '(.-)'%.$", "'%1' property는 private ('%2' class 안에서만 접근 가능)" },
  { "^Class '(.-)' incorrectly implements interface '(.-)'%.$", "'%1' class가 '%2' interface를 잘못 구현함" },
  { "^'(.-)' is declared but its value is never read%.$", "'%1' 선언됐지만 사용 안 됨" },
  { "^'(.-)' is declared but never used%.$", "'%1' 선언됐지만 사용 안 됨" },
  { "^'(.-)' is possibly '(.-)'%.$", "'%1' 값이 '%2'일 수 있음" },
  { "^Cannot assign to '(.-)' because it is a constant%.$", "'%1' constant에 할당할 수 없음" },
  { "^Cannot find module '(.-)' or its corresponding type declarations%.$", "'%1' module을 찾을 수 없음" },
  { "^A function whose declared type is neither .- must return a value%.$", "function에 return 값 필요" },

  -- Python (basedpyright)
  { '^Type "(.-)" is not assignable to declared type "(.-)"$', '"%1" type을 선언된 "%2" type에 할당할 수 없음' },
  { '^Argument of type "(.-)" cannot be assigned to parameter "(.-)" of type "(.-)" in function "(.-)"$', '"%1" type argument를 "%3" type parameter "%2"에 할당할 수 없음 (function "%4")' },
  { '^"(.-)" is not defined$', '"%1" name 정의 안 됨' },
  { '^Argument missing for parameter "(.-)"$', '"%1" parameter에 argument 누락' },
  { "^Expected (%d+) positional arguments?$", "positional argument %1개 필요" },
  { '^No parameter named "(.-)"$', '"%1" parameter 없음' },
  { '^Cannot access attribute "(.-)" for class "(.-)"$', '"%2" class의 "%1" attribute에 접근할 수 없음' },
  { '^Import "(.-)" could not be resolved$', '"%1" import를 찾을 수 없음' },
  { '^Import "(.-)" is not accessed$', '"%1" import 사용 안 됨' },
  { '^Variable "(.-)" is not accessed$', '"%1" variable 사용 안 됨' },
  { '^Type of "(.-)" is unknown$', '"%1" type 알 수 없음' },
  { '^Function with declared return type "(.-)" must return value on all code paths$', '모든 code path에서 "%1" type return 값 필요' },
  { '^Result of call expression is of type "(.-)" and is not used;.*$', '"%1" type call 결과 사용 안 됨' },
  { '^This type is deprecated as of (Python [%d%.]+); use "(.-)" instead$', '%1부터 deprecated type, "%2" 사용 권장' },

  -- Python (ruff)
  { "^`(.-)` imported but unused$", "`%1` import 사용 안 됨" },
  { "^Undefined name `(.-)`$", "`%1` name 정의 안 됨" },
  { "^Local variable `(.-)` is assigned to but never used$", "`%1` local variable 할당됐지만 사용 안 됨" },
  { "^Import block is un%-sorted or un%-formatted$", "import block 정렬·포맷 안 됨" },
  { "^Found useless (.-)%. Either assign it to a variable or remove it%.$", "쓸모없는 %1 (variable에 할당하거나 제거)" },
  { "^Use `(.-)` for type annotations$", "type annotation에 `%1` 사용 권장" },

  -- Java (jdtls)
  { "^Type mismatch: cannot convert from (.-) to (.-)$", "%1 type을 %2 type으로 변환할 수 없음" },
  { "^(%S+) cannot be resolved to a variable$", "%1 variable을 찾을 수 없음" },
  { "^(%S+) cannot be resolved to a type$", "%1 type을 찾을 수 없음" },
  { "^The import (%S+) cannot be resolved$", "%1 import를 찾을 수 없음" },
  { "^The method (.-) in the type (%S+) is not applicable for the arguments (.-)$", "%2 type의 %1 method에 argument %3 적용할 수 없음" },
  { "^The method (.-) is undefined for the type (%S+)$", "%2 type에 %1 method 정의 안 됨" },
  { "^This method must return a result of type (%S+)$", "method에 %1 type return 값 필요" },
  { "^Duplicate local variable (%S+)$", "%1 local variable 중복" },
  { "^The value of the field (%S+) is not used$", "%1 field 사용 안 됨" },
  { '^Syntax error, insert "(.-)" to complete .*$', '문법 오류: "%1" 추가 필요' },

  -- Dart (dartls)
  { "^A value of type '(.-)' can't be assigned to a variable of type '(.-)'%.$", "'%1' type 값을 '%2' type variable에 할당할 수 없음" },
  { "^Undefined name '(.-)'%.$", "'%1' name 정의 안 됨" },
  { "^Undefined class '(.-)'%.$", "'%1' class 정의 안 됨" },
  { "^The value of the local variable '(.-)' isn't used%.$", "'%1' local variable 사용 안 됨" },
  { "^(%d+) positional arguments? expected by '(.-)', but (%d+) found%.$", "'%2'에 positional argument %1개 필요, %3개 전달됨" },
  { "^Too many positional arguments: (%d+) expected, but (%d+) found%.$", "positional argument 너무 많음: %1개 필요, %2개 전달됨" },
  { "^The (%a+) '(.-)' isn't defined for the type '(.-)'%.$", "'%3' type에 '%2' %1 정의 안 됨" },
  { "^The named parameter '(.-)' isn't defined%.$", "'%1' named parameter 정의 안 됨" },
  { "^The final variable '(.-)' can only be set once%.$", "'%1' final variable은 한 번만 할당 가능" },
  { "^The property '(.-)' can't be unconditionally accessed because the receiver can be 'null'%.$", "'%1' property에 조건 없이 접근할 수 없음 (receiver가 'null'일 수 있음)" },
  { "^Target of URI doesn't exist: '(.-)'%.$", "'%1' URI 대상 없음" },
  { "^Unused import: '(.-)'%.$", "'%1' import 사용 안 됨" },
  { "^The body might complete normally, causing 'null' to be returned, but the return type, '(.-)', is a potentially non%-nullable type%.$", "return 없이 끝날 수 있음 ('%1' return type은 non-nullable)" },

  -- C (clangd)
  { "^Use of undeclared identifier '(.-)'$", "'%1' identifier 선언 안 됨" },
  { "^Call to undeclared function '(.-)';.*$", "'%1' function 선언 안 됨" },
  { "^Too few arguments to function call, expected (%d+), have (%d+)$", "function call argument 부족: %1개 필요, %2개 전달됨" },
  { "^Too many arguments to function call, expected (%d+), have (%d+)$", "function call argument 너무 많음: %1개 필요, %2개 전달됨" },
  { "^No member named '(.-)' in '(.-)'$", "'%2'에 '%1' member 없음" },
  { "^Cannot assign to variable '(.-)' with const%-qualified type '(.-)'$", "'%2' type '%1' variable에 할당할 수 없음" },
  { "^'(.-)' file not found$", "'%1' file을 찾을 수 없음" },
  { "^Expected '(.-)' at end of declaration$", "declaration 끝에 '%1' 필요" },
  { "^Incompatible (.-) to (.-) conversion initializing '(.-)' with an expression of type '(.-)'$", "'%4' type으로 '%3' type 초기화할 수 없음 (호환 안 되는 %1 → %2 변환)" },
  { "^Unused variable '(.-)'$", "'%1' variable 사용 안 됨" },
  { "^Variable '(.-)' is uninitialized when used here$", "'%1' variable 초기화 없이 사용됨" },
  { "^Non%-void function does not return a value$", "non-void function에 return 값 없음" },
  { "^Format specifies type '(.-)' but the argument has type '(.-)'$", "format은 '%1' type인데 argument는 '%2' type" },
  { "^Included header (.-) is not used directly$", "%1 header 직접 사용 안 됨" },
}

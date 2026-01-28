---
description: 작업 요청 템플릿. 복사해서 채워넣으면 Claude가 정확하게 plan 모드로 실행합니다.
---

# 작업 요청 템플릿

다음 템플릿을 사용자에게 보여주고, 채워서 다시 입력하라고 안내하라.
코드 블록 없이 plain text로 출력하라.

---

[요청 유형] (하나 선택)
feat / fix / refactor / research / db / docs

[대상 모듈]
back / front / both

[작업 계층]
- back: Controller / Service / Domain / Repository / Config
- front: Page / Component / API / Hook / Util

[무엇을] (What)
구체적으로 무엇을 해야 하는지 1-2문장

[왜] (Why)
이 작업이 필요한 이유/배경

[제약 조건]
- 예: 기존 API 호환 유지
- 예: 특정 라이브러리 사용 금지

[관련 파일/테이블] (알고 있으면)
예: UserService.kt, users 테이블

[완료 조건]
이 작업이 "끝났다"고 판단할 기준
예: 빌드 통과, API 동작 확인, 테스트 통과

---

## 채워진 예시

[요청 유형] feat
[대상 모듈] back
[작업 계층] Service, Domain, Repository
[무엇을] 회원가입 API 구현
[왜] MVP 기능으로 필수
[제약 조건] 이메일 인증은 나중에, 일단 간단한 가입만
[관련 파일/테이블] User.kt, users 테이블
[완료 조건] 빌드 통과 + POST /users 동작 확인

---

## Plan 모드란?

사용자가 템플릿을 채워서 입력하면 **Plan 모드**로 진입한다.

### Plan 모드 흐름

```
1. 코드베이스 탐색 (Explore)
   └── 관련 파일, 패턴, 기존 구현 파악

2. 구현 계획 수립 (Plan)
   └── 수정할 파일, 구현 순서, 검증 방법 정리

3. 사용자 승인 요청
   └── 계획 확인 후 승인/수정 요청

4. 구현 실행
   └── 승인된 계획대로 코드 작성
```

### Plan 모드의 장점
- 코드 작성 전에 전체 그림 파악
- 사용자와 방향 합의 후 진행
- 대규모 변경 시 실수 방지

---

## 실행 규칙

사용자가 위 템플릿을 채워서 입력하면:
1. EnterPlanMode 호출
2. 코드베이스 탐색 (Explore agent)
3. 구현 계획 수립
4. ExitPlanMode로 승인 요청
5. 승인 후 구현 시작

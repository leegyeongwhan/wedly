---
description: Git 커밋 메시지 자동 생성. 변경사항을 분석하고 컨벤션에 맞는 커밋 메시지를 생성합니다.
allowed-tools: Bash(git:*), Bash(./gradlew:*), Bash(npm:*), Read, Grep, Glob
---

# 커밋 메시지 생성

## 사용법

```
/commit              # 모든 변경사항 커밋
/commit "메시지"     # 지정된 메시지로 커밋
```

---

## 현재 상태 확인

1. `git status`로 변경된 파일 확인
2. `git diff --staged`로 스테이징된 변경사항 확인
3. `git diff`로 스테이징 안 된 변경사항 확인

---

## Pre-commit 검증

### Backend (Kotlin 파일이 포함된 경우)

```bash
cd back && ./gradlew build -x test --no-daemon 2>&1 | tail -30
```

**실패 시 정책:**
1. 에러 분석
2. 자동 수정 시도 (최대 3회)
3. 3회 실패 시 → 커밋 중단 + 수정 제안

### Frontend (TypeScript 파일이 포함된 경우)

```bash
cd front && npm run lint 2>&1 | tail -30
```

**실패 시 정책:**
1. 에러 분석
2. 자동 수정 시도 (최대 3회)
3. 3회 실패 시 → 커밋 중단 + 수정 제안

---

## 커밋 메시지 형식

```
<type>(<scope>): <subject>

<body>

Generated with Claude Code
```

### Type
- `feat`: 새로운 기능
- `fix`: 버그 수정
- `refactor`: 리팩토링
- `docs`: 문서 변경
- `style`: 코드 스타일 변경
- `test`: 테스트 추가/수정
- `chore`: 빌드, 설정 변경

### Scope (선택)
- `back`: 백엔드 변경
- `front`: 프론트엔드 변경

---

## 작업 순서

1. 변경사항 분석
2. Kotlin 파일 포함 시: Gradle build 검증 (실패 시 자동 수정 3회)
3. TypeScript 파일 포함 시: npm lint 검증 (실패 시 자동 수정 3회)
4. 적절한 type 선택
5. 간결한 subject 작성 (50자 이내)
6. 필요시 body에 상세 설명
7. **사용자 확인 후** 커밋 실행

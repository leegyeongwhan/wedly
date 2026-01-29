---
description: 빌드/테스트 검증 후 결과 분석
---

# 검증 루프 실행

변경된 파일 유형에 따라 해당 검증을 실행합니다.

---

## Backend 검증 (Kotlin/Java 파일 변경 시)

### 1. 빌드 검증

// turbo
```bash
cd back && ./gradlew build -x test --no-daemon 2>&1 | tail -50
```

- 성공 시: Step 2로
- 실패 시: 에러 메시지 분석 → 원인 파악 → 수정 제안

### 2. 테스트 실행 (선택)

// turbo
```bash
cd back && ./gradlew test --no-daemon 2>&1 | tail -50
```

- 실패 시: 실패한 테스트 분석 → 수정 제안

### 3. 코드 리뷰 (Self-Verify)

변경된 Kotlin 파일을 리뷰:
- `git diff --name-only`로 변경된 .kt 파일 목록 확인
- Kotlin 컨벤션 체크:
  - data class 활용
  - null safety 적절히 사용
  - 불필요한 nullable 타입 제거
  - sealed class 활용 (상태 관리)

---

## Frontend 검증 (TypeScript 파일 변경 시)

### 1. 린트 검증

// turbo
```bash
cd front && npm run lint 2>&1 | tail -30
```

- 성공 시: Step 2로
- 실패 시: 에러 분석 → 수정 제안

### 2. 빌드 검증

// turbo
```bash
cd front && npm run build 2>&1 | tail -50
```

- 성공 시: Step 3로
- 실패 시: 에러 분석 → 수정 제안

### 3. 코드 리뷰 (Self-Verify)

변경된 TypeScript 파일을 리뷰:
- `git diff --name-only`로 변경된 .ts/.tsx 파일 목록 확인
- TypeScript/React 컨벤션 체크:
  - strict 타입 사용
  - any 타입 금지
  - Server Component vs Client Component 적절히 구분
  - Tailwind 클래스 정리

---

## 결과 보고

```
## 검증 결과

### Backend
- 빌드: ✅/❌
- 테스트: ✅/❌/⏭️ (스킵)
- 코드 리뷰: ✅/⚠️ (이슈 N개)

### Frontend
- 린트: ✅/❌
- 빌드: ✅/❌
- 코드 리뷰: ✅/⚠️ (이슈 N개)

### 권장 조치
- (있으면 나열)
```

---

## 자동 수정 (실패 시)

빌드/린트 실패가 방금 수정한 코드와 관련된 경우:
- 자동으로 수정 시도
- 수정 후 다시 Step 1부터 재실행
- 최대 3회 반복

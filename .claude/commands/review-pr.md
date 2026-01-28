---
description: GitHub PR 리뷰. PR 번호를 입력하면 변경사항을 분석하고 컨벤션에 맞는 리뷰를 제공합니다.
allowed-tools: Bash(git:*), Bash(gh:*), Read, Grep, Glob
---

# PR 리뷰: $ARGUMENTS

## 사용법

```
/review-pr 42
/review-pr         # PR 번호 입력 프롬프트
```

---

## 리뷰 프로세스

### 1. PR 정보 수집
- PR 제목, 설명 확인
- 변경된 파일 목록 확인
- 커밋 히스토리 확인

### 2. 코드 분석

#### Backend (Kotlin) 체크리스트

##### 아키텍처 (DDD)
- [ ] Controller는 요청/응답 변환만 담당
- [ ] **Service는 흐름 조율만** (비즈니스 로직 X)
- [ ] **Domain에 비즈니스 로직 위치**
- [ ] Repository는 데이터 접근만 담당
- [ ] Tell, Don't Ask 원칙

##### Kotlin 컨벤션
- [ ] data class 활용 (DTO)
- [ ] null safety 적절히 사용
- [ ] 확장 함수 활용
- [ ] sealed class (상태/결과 타입)

##### 보안
- [ ] SQL Injection (JPA 쿼리 안전)
- [ ] 인증/인가 체크
- [ ] 민감 정보 노출

##### 성능
- [ ] N+1 쿼리 (fetch join)
- [ ] 불필요한 조회
- [ ] 적절한 인덱스

#### Frontend (TypeScript/React) 체크리스트

##### 컴포넌트 구조
- [ ] Server/Client Component 적절히 구분
- [ ] 컴포넌트 책임 분리
- [ ] Props 타입 정의

##### TypeScript 컨벤션
- [ ] strict 타입 사용
- [ ] any 타입 금지
- [ ] interface vs type 적절히 사용

##### React 패턴
- [ ] 불필요한 re-render 방지
- [ ] useEffect 의존성 배열 정확

##### 스타일
- [ ] Tailwind 클래스 정리
- [ ] 반응형 디자인

### 3. 리뷰 결과 출력

```
## PR #번호 리뷰 결과

### 요약
- 변경 파일: N개 (back: N, front: N)
- 추가: +N줄, 삭제: -N줄

### Critical (반드시 수정)
- 없음 / 있으면 나열

### Warning (수정 권장)
- 없음 / 있으면 나열

### Suggestion (개선 제안)
- 없음 / 있으면 나열

### Good (잘한 점)
- 칭찬할 부분

### 결론
✅ Approve / ⚠️ Request Changes / 💬 Comment
```

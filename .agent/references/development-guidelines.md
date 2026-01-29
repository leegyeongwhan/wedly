# Weddly 개발 가이드라인

## 핵심 역할

Weddly 웨딩 플랫폼의 **유일한 개발자이자 기획자이자 총괄**과 함께하는 파트너.
모든 것을 함께 해내는 동료로서 행동합니다.

---

## 프로젝트 구조

- **Monorepo** (Git Submodules): weddly → back, front
- **Backend**: Kotlin 2.2 + Spring Boot 4.0 + JPA + PostgreSQL
- **Frontend**: Next.js 16 + TypeScript 5.9 + Tailwind CSS 3.4

---

## 핵심 설계 원칙

### 비즈니스 로직은 Domain에

```
Service  → 흐름 조율, 트랜잭션, 외부 연동
Domain   → 비즈니스 로직, 도메인 규칙
```

### Tell, Don't Ask

```kotlin
// ❌ Ask
if (booking.status == PENDING) booking.status = CONFIRMED

// ✅ Tell
booking.confirm()
```

### KISS (Keep It Simple)

- 과도한 추상화 금지
- 미래를 위한 과잉 설계 금지 (YAGNI)
- 필요할 때 패턴 적용

---

## 응답 스타일

1. **결론부터** - 핵심 답변 먼저
2. **복수 옵션** - A vs B 방식 (장단점 명시)
3. **코드 예시** - Before/After 비교
4. **영향 범위** - 변경 시 영향받는 파일 명시

---

## 금지 사항

- 과도한 추상화
- 미래를 위한 과잉 설계 (YAGNI)
- 불필요한 복잡성
- DB 직접 변경 (SELECT만 허용)
- .env 파일 읽기/수정

---

## 테스트 원칙 ⚠️ 필수

> **테스트 없는 코드는 레거시**. 모든 기능에 테스트 동반.

- **Backend**: JUnit 5, `메서드명_상황_예상결과` 네이밍
- **Frontend**: Vitest, React Testing Library
- 경계값 + 실패 시나리오 필수
- 상세 가이드 → [coding-conventions.md](file:///home/gylee/IdeaProjects/weddly/.agent/references/coding-conventions.md)

### 코드 작성 후 체크리스트

- [ ] 정상 시나리오 테스트 작성
- [ ] 실패 시나리오 테스트 작성
- [ ] 경계값 테스트 작성 (0, 1, MAX)
- [ ] 도메인 불변식 검증

---

## 참조 문서

| 주제 | 참조 |
|------|------|
| 아키텍처/레이어 | [architecture.md](file:///home/gylee/IdeaProjects/weddly/.agent/references/architecture.md) |
| 코딩 컨벤션 | [coding-conventions.md](file:///home/gylee/IdeaProjects/weddly/.agent/references/coding-conventions.md) |
| DB/쿼리 최적화 | [postgres-best-practices.md](file:///home/gylee/IdeaProjects/weddly/.agent/references/postgres-best-practices.md) |

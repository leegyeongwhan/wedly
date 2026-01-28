---
name: weddly-architecture
description: Weddly 프로젝트 아키텍처 이해. 구조, Entity, Service, 모듈 관계 질문 시 사용. "아키텍처", "구조", "Entity", "Service" 관련 질문에 자동 적용.
---

# Weddly 아키텍처 가이드

## 핵심 원칙

> **비즈니스 로직은 Domain에, Service는 흐름 조율만**

| 레이어 | 책임 |
|--------|------|
| Controller | 요청/응답 변환 |
| **Service** | **흐름 조율**, 트랜잭션, 외부 연동 |
| **Domain** | **비즈니스 로직**, 도메인 규칙 |
| Repository | 데이터 접근 |

## 프로젝트 구조

```
weddly/
├── back/                  (Kotlin + Spring Boot)
│   └── src/main/kotlin/
│       ├── domain/        # Entity, Repository
│       ├── service/       # 흐름 조율
│       ├── controller/    # REST API
│       └── dto/           # Request/Response
│
└── front/                 (Next.js + TypeScript)
    └── src/app/           # App Router
```

## 도메인 모델

```
User     → 회원
Vendor   → 웨딩 업체
Service  → 업체 서비스
Booking  → 예약
Review   → 리뷰
Payment  → 결제
```

## 상세 가이드

| 주제 | 참조 |
|------|------|
| 레이어 구조 | `references/layer-structure.md` |
| Entity 설계 | `references/entity-design.md` |
| Frontend 구조 | `references/frontend-structure.md` |

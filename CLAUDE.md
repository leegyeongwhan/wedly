# Weddly 프로젝트 영구 계획표

> 새 세션에서 이 파일을 읽어 진행 상황을 파악한다.

---

## 프로젝트 개요

**Weddly** - 웨딩 플랫폼 (1인 개발)

### 기술 스택
| 영역 | 기술 |
|------|------|
| Backend | Kotlin 2.2, Spring Boot 4.0, JPA, PostgreSQL, Gradle 8.14 |
| Frontend | Next.js 16, React 19, TypeScript 5.9, Tailwind CSS 3.4 |
| Infra | Git Submodules, GitHub Actions |

### 리포지토리 구조
```
weddly/                    (상위 리포지토리)
├── back/                  (submodule → weddly-back)
│   └── Kotlin + Spring Boot
├── front/                 (submodule → weddly-front)
│   └── Next.js + TypeScript
└── .github/workflows/     (CI/CD)
```

---

## 사고 프레임워크

1. **First Principles** - "원래 이렇게 해왔다"를 의심, 근본 원리에서 재구축
2. **Connecting the Dots** - 다른 도메인의 해결책을 현재 문제에 연결
3. **KISS** - Keep It Simple, Stupid

---

## 소프트웨어 3.0 아키텍처

> LLM 시대의 에이전트 설계는 전통적인 소프트웨어 아키텍처와 동일한 원칙을 따른다.

### 핵심 개념

| 개념 | 설명 |
|------|------|
| **Harness** | LLM을 실제 시스템과 연결하는 도구. LLM만으로는 파일/API/DB 접근 불가 |
| **프롬프트 = 프로그램** | 자연어로 "무엇(What)"을 말하면 LLM이 "어떻게(How)"를 수행 |
| **토큰 = 메모리** | Context Window가 곧 작업 메모리. 관리가 핵심 |

### 아키텍처 매핑

```
전통 아키텍처          Claude 설정           역할
─────────────────────────────────────────────────────
Controller      →    Commands (/ask)    →  사용자 진입점
Service Layer   →    Agents             →  비즈니스 로직 처리
Domain          →    Skills             →  도메인 지식
External System →    MCP                →  외부 시스템 연동
```

### 설계 원칙

1. **Progressive Disclosure** (점진적 공개)
   - SKILL.md = Facade (진입점만 제공)
   - references/ = 세부 내용 (필요시 로드)
   - Skill 폭발 방지, Context 절약

2. **디미터의 법칙**
   - "친구의 친구에게 말하지 마라"
   - Agent는 직접 관련된 Skill만 참조

3. **단일 책임 원칙 (SRP)**
   - 하나의 Skill = 하나의 도메인
   - 과도한 분할은 Skill 폭발 유발

### 현재 구조

```
.claude/
├── commands/     # Controller - 사용자 진입점
│   ├── ask.md
│   ├── commit.md
│   ├── verify.md
│   └── review-pr.md
├── agents/       # Service - 비즈니스 로직
│   ├── code-reviewer/
│   └── db-analyst/
└── skills/       # Domain - 도메인 지식 (Progressive Disclosure)
    ├── weddly-architecture/
    ├── coding-conventions/
    │   ├── SKILL.md          # Facade
    │   └── references/       # 필요시 로드
    └── supabase-postgres-best-practices/
        ├── SKILL.md
        └── references/       # 30개 규칙
```

---

## 작업 계획표

| Phase | 항목 | 상태 |
|-------|------|------|
| 0-1 | Claude 설정 세팅 | ✅ 완료 |
| 0-2 | 기술 스택 최신화 | ✅ 완료 |
| 1-1 | 도메인 모델 설계 | ⬜ 대기 |
| 1-2 | DB 스키마 설계 | ⬜ 대기 |
| 2-1 | 인증/인가 구현 | ⬜ 대기 |
| 2-2 | 핵심 API 개발 | ⬜ 대기 |
| 3-1 | 프론트엔드 UI 구현 | ⬜ 대기 |
| 4-1 | 배포 파이프라인 완성 | ⬜ 대기 |

---

## 이미 구현된 것

| 항목 | 위치 |
|------|------|
| Git Submodules 구조 | `.gitmodules` |
| GitHub Actions CI/CD | `.github/workflows/deploy.yml` |
| Spring Boot 기본 설정 | `back/src/main/resources/application.yml` |
| Next.js 기본 설정 | `front/next.config.js` |

---

## 상세 참조 (Skill로 분리됨)

| 주제 | 참조 |
|------|------|
| 프로젝트 아키텍처 | `.claude/skills/weddly-architecture/` |
| 코딩 컨벤션 (Kotlin + Next.js) | `.claude/skills/coding-conventions/` |
| PostgreSQL 최적화 (30개 규칙) | `.claude/skills/supabase-postgres-best-practices/` |

---

## 도메인 모델 (예정)

```
// 추후 설계
- User (회원)
- Vendor (업체)
- Service (서비스/상품)
- Booking (예약)
- Review (리뷰)
- Payment (결제)
```

---

## 현재 작업

> Claude는 작업 완료 시 이 섹션을 자동 업데이트한다.

### 진행 중
- [ ] Phase 1-1: 도메인 모델 설계

### 최근 완료
- [x] Phase 0-1: Claude 설정 세팅
- [x] Phase 0-2: 기술 스택 최신화
- [x] 테스트 정책 상세화

### 다음 할 일
- Phase 1-2: DB 스키마 설계
- Phase 2-1: 인증/인가 구현

---

## Git 계정 정보

- **이 프로젝트**: leegyeongwhan (개인 계정, leekhy02@naver.com)
- **글로벌 설정**: 회사 계정 (변경하지 않음)

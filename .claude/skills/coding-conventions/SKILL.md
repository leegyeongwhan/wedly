---
name: coding-conventions
description: Weddly 코딩 컨벤션. Kotlin, TypeScript, React 관련 질문에 자동 적용. 세부 내용은 references/에서 필요시 로드.
---

# Weddly 코딩 컨벤션

이 Skill은 Backend(Kotlin)와 Frontend(TypeScript/React) 코딩 컨벤션의 **진입점**입니다.

## 언제 사용되나요?

- "Kotlin 코드 어떻게 작성해?" → `references/kotlin.md` 참조
- "React 컴포넌트 패턴이 뭐야?" → `references/nextjs.md` 참조
- "코드 리뷰해줘" → code-reviewer Agent가 이 Skill 참조

## 핵심 원칙 (공통)

### 1. 단순함 (KISS)
- 과도한 추상화 금지
- 필요할 때만 패턴 적용
- "미래를 위한" 코드 금지

### 2. 읽기 쉬운 코드
- 의미 있는 이름
- 함수는 한 가지 일만
- 주석보다 코드로 설명

### 3. 일관성
- 팀/프로젝트 컨벤션 따르기
- 기존 코드 스타일 유지

## 세부 가이드

언어별 상세 컨벤션은 필요시 참조됩니다:

| 주제 | 참조 파일 |
|------|----------|
| Kotlin + Spring Boot | `references/kotlin.md` |
| Next.js + TypeScript | `references/nextjs.md` |

Claude는 질문 맥락에 따라 적절한 파일을 자동으로 로드합니다.

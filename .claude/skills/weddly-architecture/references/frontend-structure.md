# Frontend 구조 (Next.js App Router)

## 디렉토리 구조

```
src/app/
├── layout.tsx           # 루트 레이아웃
├── page.tsx             # 홈페이지
├── (auth)/              # 인증 관련 그룹
│   ├── login/
│   └── register/
├── (main)/              # 메인 페이지 그룹
│   ├── vendors/
│   └── services/
└── api/                 # API Routes
```

---

## 컴포넌트 분류

| 유형 | 위치 | 특징 |
|------|------|------|
| Server Component | `app/**/*.tsx` (기본) | 데이터 fetching, SEO |
| Client Component | `'use client'` 선언 | 상호작용, 상태 관리 |
| Shared Component | `components/` | 재사용 가능 UI |

---

## Server Component (기본)

```tsx
// app/vendors/page.tsx
async function VendorsPage() {
  const vendors = await fetch('/api/vendors').then(r => r.json())

  return (
    <div>
      {vendors.map(vendor => (
        <VendorCard key={vendor.id} vendor={vendor} />
      ))}
    </div>
  )
}
```

**사용 시점:**
- 데이터 fetching
- 백엔드 리소스 접근
- SEO가 중요한 페이지

---

## Client Component

```tsx
// components/VendorFilter.tsx
'use client'

import { useState } from 'react'

export function VendorFilter({ onFilter }: Props) {
  const [category, setCategory] = useState('')

  return (
    <select value={category} onChange={e => {
      setCategory(e.target.value)
      onFilter(e.target.value)
    }}>
      <option value="">전체</option>
      <option value="photo">사진</option>
      <option value="dress">드레스</option>
    </select>
  )
}
```

**사용 시점:**
- useState, useEffect 필요
- 이벤트 핸들러 (onClick, onChange)
- 브라우저 API 사용

---

## 데이터 흐름

```
[Client] → [Next.js Server] → [Spring Boot API] → [PostgreSQL]
              ↓
       Server Component에서
       직접 fetch 가능
```

### API 호출 패턴

```tsx
// Server Component에서 직접 호출
async function Page() {
  const data = await fetch('http://localhost:8080/api/vendors', {
    cache: 'no-store' // 또는 revalidate
  })
  return <VendorList data={data} />
}

// Client Component에서 SWR 사용
'use client'
import useSWR from 'swr'

function VendorList() {
  const { data, error } = useSWR('/api/vendors', fetcher)
  if (error) return <div>에러 발생</div>
  if (!data) return <div>로딩중...</div>
  return <div>{/* ... */}</div>
}
```

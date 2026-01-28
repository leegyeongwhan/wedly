# Next.js 14 + TypeScript 베스트 프랙티스

## App Router 기본

### 1. 폴더 구조

```
src/app/
├── layout.tsx              # 루트 레이아웃
├── page.tsx                # 홈페이지 (/)
├── loading.tsx             # 로딩 UI
├── error.tsx               # 에러 UI
├── (auth)/                 # Route Group
│   ├── login/page.tsx
│   └── register/page.tsx
└── api/
    └── users/route.ts      # API Route
```

### 2. Server vs Client Component

```tsx
// ✅ Server Component (기본)
async function VendorList() {
  const vendors = await fetch('/api/vendors').then(r => r.json())
  return <ul>{vendors.map(v => <li key={v.id}>{v.name}</li>)}</ul>
}

// ✅ Client Component
'use client'
import { useState } from 'react'

function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
}
```

### 3. 데이터 Fetching

```tsx
// Server Component에서 직접 fetch
async function VendorPage({ params }: { params: { id: string } }) {
  const vendor = await fetch(`${API_URL}/vendors/${params.id}`, {
    next: { revalidate: 60 } // ISR
  }).then(r => r.json())

  return <VendorDetail vendor={vendor} />
}
```

---

## TypeScript 베스트 프랙티스

### 1. Props 타입 정의

```tsx
interface ButtonProps {
  children: React.ReactNode
  variant?: 'primary' | 'secondary'
  disabled?: boolean
  onClick?: () => void
}

function Button({ children, variant = 'primary', ...props }: ButtonProps) {
  return <button className={`btn-${variant}`} {...props}>{children}</button>
}
```

### 2. any 금지

```tsx
// ❌ Bad
function process(data: any) { ... }

// ✅ Good
interface User { id: number; name: string }
function process(data: User) { ... }

// ✅ Good: unknown + 타입 가드
function process(data: unknown) {
  if (isUser(data)) console.log(data.name)
}
```

### 3. Utility Types

```tsx
type UpdateUser = Partial<User>           // 모든 속성 optional
type UserPreview = Pick<User, 'id' | 'name'>  // 특정 속성만
type UserWithoutPassword = Omit<User, 'password'>  // 특정 속성 제외
```

---

## React 패턴

### 1. 불필요한 re-render 방지

```tsx
'use client'
import { memo, useMemo, useCallback } from 'react'

// memo: props 변경 없으면 re-render 방지
const ExpensiveList = memo(function ExpensiveList({ items }: Props) {
  return items.map(item => <Item key={item.id} item={item} />)
})

// useMemo: 계산 결과 메모이제이션
const processedData = useMemo(() => expensiveCalculation(data), [data])

// useCallback: 함수 메모이제이션
const handleClick = useCallback((id: number) => console.log(id), [])
```

### 2. Error Boundary

```tsx
// app/error.tsx
'use client'
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  )
}
```

---

## Tailwind CSS

```tsx
// ✅ 유틸리티 클래스
<button className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
  Click
</button>

// ✅ 조건부 클래스 (cn 함수)
import { cn } from '@/lib/utils'
<button className={cn(
  'px-4 py-2 rounded',
  variant === 'primary' && 'bg-blue-500 text-white',
  disabled && 'opacity-50 cursor-not-allowed'
)}>

// ✅ 반응형
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
```

---

## 금지 사항

| 하지 말 것 | 대신 |
|-----------|------|
| `any` 타입 | 구체적인 타입 또는 `unknown` |
| 불필요한 `'use client'` | Server Component 우선 |
| useEffect로 data fetch | Server Component에서 직접 fetch |
| 인라인 스타일 | Tailwind 클래스 |

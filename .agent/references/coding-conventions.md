# Weddly 코딩 컨벤션

이 문서는 Backend(Kotlin)와 Frontend(TypeScript/React) 코딩 컨벤션을 정리합니다.

---

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

---

## Kotlin + Spring Boot 베스트 프랙티스

### 1. Data Class (DTO, Entity)

```kotlin
// DTO
data class UserRequest(
    val email: String,
    val name: String,
    val password: String
)

data class UserResponse(
    val id: Long,
    val email: String,
    val name: String
) {
    companion object {
        fun from(entity: User) = UserResponse(
            id = entity.id!!,
            email = entity.email,
            name = entity.name
        )
    }
}
```

### 2. Null Safety

```kotlin
// ✅ Good: Elvis 연산자
val name = user?.name ?: "Unknown"

// ✅ Good: safe call + let
user?.let {
    sendEmail(it.email)
}

// ✅ Good: require/check 로 early return
fun process(user: User?) {
    requireNotNull(user) { "User cannot be null" }
    // user는 이제 non-null
}

// ❌ Bad: !! 남용
val name = user!!.name  // NPE 위험!
```

### 3. 확장 함수

```kotlin
// String 확장
fun String.isValidEmail(): Boolean =
    this.matches(Regex("^[A-Za-z0-9+_.-]+@(.+)$"))

// 사용
if (email.isValidEmail()) { ... }

// Entity → DTO 변환 확장
fun User.toResponse() = UserResponse(
    id = this.id!!,
    email = this.email,
    name = this.name
)
```

### 4. Sealed Class (상태/결과)

```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val message: String) : Result<Nothing>()
    object Loading : Result<Nothing>()
}

// when으로 처리 (컴파일러가 모든 케이스 체크)
when (val result = getUser(1L)) {
    is Result.Success -> println(result.data)
    is Result.Error -> println(result.message)
    is Result.Loading -> println("Loading...")
}
```

### 5. When Expression

```kotlin
// ✅ 표현식으로 사용
val message = when (status) {
    Status.PENDING -> "대기 중"
    Status.APPROVED -> "승인됨"
    Status.REJECTED -> "거부됨"
}

// ✅ 범위 검사
val grade = when (score) {
    in 90..100 -> "A"
    in 80 until 90 -> "B"
    else -> "F"
}
```

### 6. Entity

```kotlin
@Entity
@Table(name = "users")
class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false, unique = true)
    var email: String,

    @Column(nullable = false)
    var name: String,

    @CreatedDate
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    fun updateProfile(name: String) {
        this.name = name
    }
}
```

### 7. Repository

```kotlin
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): User?
    fun existsByEmail(email: String): Boolean
}
```

### 8. Service

```kotlin
@Service
@Transactional(readOnly = true)
class UserService(
    private val userRepository: UserRepository
) {
    fun getUser(id: Long): UserResponse {
        val user = userRepository.findById(id)
            .orElseThrow { NotFoundException("User not found: $id") }
        return UserResponse.from(user)
    }

    @Transactional
    fun createUser(request: UserRequest): UserResponse {
        require(!userRepository.existsByEmail(request.email)) {
            "Email already exists"
        }
        val user = User(email = request.email, name = request.name)
        return UserResponse.from(userRepository.save(user))
    }
}
```

### 9. Controller

```kotlin
@RestController
@RequestMapping("/api/users")
class UserController(
    private val userService: UserService
) {
    @GetMapping("/{id}")
    fun getUser(@PathVariable id: Long) = userService.getUser(id)

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createUser(@Valid @RequestBody request: UserRequest) =
        userService.createUser(request)
}
```

### 10. JPA 성능 최적화

```kotlin
// ✅ Fetch Join
@Query("SELECT u FROM User u JOIN FETCH u.orders WHERE u.id = :id")
fun findWithOrders(@Param("id") id: Long): User?

// ✅ EntityGraph
@EntityGraph(attributePaths = ["orders"])
fun findById(id: Long): User?

// ✅ Batch Size (application.yml)
spring:
  jpa:
    properties:
      hibernate:
        default_batch_fetch_size: 100
```

### Kotlin 금지 사항

| 하지 말 것 | 대신 |
|-----------|------|
| `!!` 남용 | `?.let`, `?:`, `requireNotNull` |
| `var` 남발 | `val` 우선 |
| 거대한 Service | 책임별로 분리 |

---

## Next.js 14 + TypeScript 베스트 프랙티스

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

### 4. Props 타입 정의

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

### 5. any 금지

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

### 6. Utility Types

```tsx
type UpdateUser = Partial<User>           // 모든 속성 optional
type UserPreview = Pick<User, 'id' | 'name'>  // 특정 속성만
type UserWithoutPassword = Omit<User, 'password'>  // 특정 속성 제외
```

### 7. 불필요한 re-render 방지

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

### 8. Error Boundary

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

### 9. Tailwind CSS

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

### TypeScript/React 금지 사항

| 하지 말 것 | 대신 |
|-----------|------|
| `any` 타입 | 구체적인 타입 또는 `unknown` |
| 불필요한 `'use client'` | Server Component 우선 |
| useEffect로 data fetch | Server Component에서 직접 fetch |
| 인라인 스타일 | Tailwind 클래스 |

---

## 테스트 작성 가이드

> 테스트는 선택이 아닌 **필수**. 코드 품질의 마지막 방어선.

### 핵심 원칙

1. **테스트 없는 코드는 레거시** - 모든 기능에 테스트 동반
2. **실패 케이스 우선** - 성공보다 실패 시나리오가 더 중요
3. **경계값 필수** - 0, 1, MAX, null, 빈 값 테스트
4. **읽기 쉬운 테스트** - 테스트 코드도 프로덕션 코드처럼 관리

### Backend (Kotlin + JUnit 5)

#### 네이밍 컨벤션

```
메서드명_상황_예상결과
```

**예시**:
- `confirm_예약이PENDING상태일때_CONFIRMED로변경`
- `confirm_이미CONFIRMED상태일때_예외발생`
- `cancel_취소불가기한지났을때_예외발생`

#### 테스트 구조 (Given-When-Then)

```kotlin
@Test
fun `confirm_예약이PENDING상태일때_CONFIRMED로변경`() {
    // Given - 테스트 준비
    val booking = Booking.create(
        userId = 1L,
        serviceId = 100L,
        date = LocalDate.now().plusDays(7)
    )

    // When - 테스트 실행
    booking.confirm()

    // Then - 결과 검증
    assertThat(booking.status).isEqualTo(BookingStatus.CONFIRMED)
    assertThat(booking.confirmedAt).isNotNull()
}
```

#### 필수 테스트 케이스

| 케이스 | 설명 | 예시 |
|--------|------|------|
| **Happy Path** | 정상 시나리오 | 유효한 입력으로 성공 |
| **경계값** | 0, 1, MAX | 금액 0원, 최대 수량 |
| **실패 시나리오** | 예외 발생 | 잘못된 상태 전이 |
| **도메인 불변식** | 비즈니스 규칙 | 예약은 미래 날짜만 |

#### 예외 테스트

```kotlin
@Test
fun `confirm_이미CONFIRMED상태일때_예외발생`() {
    // Given
    val booking = createConfirmedBooking()

    // When & Then
    assertThatThrownBy { booking.confirm() }
        .isInstanceOf(IllegalStateException::class.java)
        .hasMessageContaining("이미 확정된 예약")
}
```

#### 테스트 픽스처

```kotlin
// 테스트 데이터 생성 헬퍼
fun createPendingBooking(
    userId: Long = 1L,
    date: LocalDate = LocalDate.now().plusDays(7)
): Booking = Booking.create(userId, 100L, date)

fun createConfirmedBooking(): Booking =
    createPendingBooking().also { it.confirm() }
```

### Frontend (Vitest + Testing Library)

#### 테스트 유형

| 유형 | 도구 | 대상 |
|------|------|------|
| **Unit** | Vitest | 유틸 함수, hooks |
| **Component** | Testing Library | 컴포넌트 렌더링 |
| **Integration** | Playwright | E2E 시나리오 |

#### 컴포넌트 테스트

```tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { BookingCard } from './BookingCard'

describe('BookingCard', () => {
  it('예약 정보를 렌더링한다', () => {
    // Given
    const booking = { id: 1, serviceName: '메이크업', date: '2025-03-15' }

    // When
    render(<BookingCard booking={booking} />)

    // Then
    expect(screen.getByText('메이크업')).toBeInTheDocument()
    expect(screen.getByText('2025-03-15')).toBeInTheDocument()
  })

  it('취소 버튼 클릭 시 onCancel 호출', async () => {
    // Given
    const onCancel = vi.fn()
    render(<BookingCard booking={mockBooking} onCancel={onCancel} />)

    // When
    fireEvent.click(screen.getByRole('button', { name: '취소' }))

    // Then
    expect(onCancel).toHaveBeenCalledWith(mockBooking.id)
  })
})
```

#### Hook 테스트

```tsx
import { renderHook, act } from '@testing-library/react'
import { useBookingForm } from './useBookingForm'

describe('useBookingForm', () => {
  it('날짜 변경 시 상태 업데이트', () => {
    const { result } = renderHook(() => useBookingForm())

    act(() => {
      result.current.setDate('2025-03-15')
    })

    expect(result.current.date).toBe('2025-03-15')
  })
})
```

### 테스트 커버리지 기준

| 영역 | 최소 | 권장 |
|------|------|------|
| Domain (Entity) | 90% | 95% |
| Service | 80% | 90% |
| Controller | 70% | 80% |
| Component | 70% | 85% |

### Anti-Patterns (피해야 할 것)

#### ❌ 구현 세부사항 테스트
```kotlin
// Bad: 내부 구현에 의존
assertThat(booking.statusHistory.size).isEqualTo(2)

// Good: 외부 동작에 집중
assertThat(booking.status).isEqualTo(CONFIRMED)
```

#### ❌ 테스트 간 의존성
```kotlin
// Bad: 테스트 순서에 의존
@Test fun test1() { repository.save(entity) }
@Test fun test2() { repository.findById(1) } // test1에 의존

// Good: 각 테스트 독립적
@BeforeEach fun setup() { repository.deleteAll() }
```

#### ❌ 너무 많은 Mock
```kotlin
// Bad: 모든 것을 Mock
// Good: 실제 객체 우선, 외부 의존성만 Mock
```

### CI/CD 연동

- **PR 생성 시**: 전체 테스트 실행
- **테스트 실패 시**: 머지 차단
- **커버리지 하락 시**: 경고 (차단 X)

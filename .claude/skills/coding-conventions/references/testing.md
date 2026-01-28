# 테스트 작성 가이드

> 테스트는 선택이 아닌 **필수**. 코드 품질의 마지막 방어선.

---

## 핵심 원칙

1. **테스트 없는 코드는 레거시** - 모든 기능에 테스트 동반
2. **실패 케이스 우선** - 성공보다 실패 시나리오가 더 중요
3. **경계값 필수** - 0, 1, MAX, null, 빈 값 테스트
4. **읽기 쉬운 테스트** - 테스트 코드도 프로덕션 코드처럼 관리

---

## Backend (Kotlin + JUnit 5)

### 네이밍 컨벤션

```
메서드명_상황_예상결과
```

**예시**:
- `confirm_예약이PENDING상태일때_CONFIRMED로변경`
- `confirm_이미CONFIRMED상태일때_예외발생`
- `cancel_취소불가기한지났을때_예외발생`

### 테스트 구조 (Given-When-Then)

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

### 필수 테스트 케이스

| 케이스 | 설명 | 예시 |
|--------|------|------|
| **Happy Path** | 정상 시나리오 | 유효한 입력으로 성공 |
| **경계값** | 0, 1, MAX | 금액 0원, 최대 수량 |
| **실패 시나리오** | 예외 발생 | 잘못된 상태 전이 |
| **도메인 불변식** | 비즈니스 규칙 | 예약은 미래 날짜만 |

### 예외 테스트

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

### 테스트 픽스처

```kotlin
// 테스트 데이터 생성 헬퍼
fun createPendingBooking(
    userId: Long = 1L,
    date: LocalDate = LocalDate.now().plusDays(7)
): Booking = Booking.create(userId, 100L, date)

fun createConfirmedBooking(): Booking =
    createPendingBooking().also { it.confirm() }
```

---

## Frontend (Vitest + Testing Library)

### 테스트 유형

| 유형 | 도구 | 대상 |
|------|------|------|
| **Unit** | Vitest | 유틸 함수, hooks |
| **Component** | Testing Library | 컴포넌트 렌더링 |
| **Integration** | Playwright | E2E 시나리오 |

### 컴포넌트 테스트

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

### Hook 테스트

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

---

## 테스트 커버리지 기준

| 영역 | 최소 | 권장 |
|------|------|------|
| Domain (Entity) | 90% | 95% |
| Service | 80% | 90% |
| Controller | 70% | 80% |
| Component | 70% | 85% |

---

## Anti-Patterns (피해야 할 것)

### ❌ 구현 세부사항 테스트
```kotlin
// Bad: 내부 구현에 의존
assertThat(booking.statusHistory.size).isEqualTo(2)

// Good: 외부 동작에 집중
assertThat(booking.status).isEqualTo(CONFIRMED)
```

### ❌ 테스트 간 의존성
```kotlin
// Bad: 테스트 순서에 의존
@Test fun test1() { repository.save(entity) }
@Test fun test2() { repository.findById(1) } // test1에 의존

// Good: 각 테스트 독립적
@BeforeEach fun setup() { repository.deleteAll() }
```

### ❌ 너무 많은 Mock
```kotlin
// Bad: 모든 것을 Mock
// Good: 실제 객체 우선, 외부 의존성만 Mock
```

---

## CI/CD 연동

- **PR 생성 시**: 전체 테스트 실행
- **테스트 실패 시**: 머지 차단
- **커버리지 하락 시**: 경고 (차단 X)

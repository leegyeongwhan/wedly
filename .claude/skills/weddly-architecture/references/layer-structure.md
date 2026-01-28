# Backend 레이어 구조

> **핵심 원칙**: 비즈니스 로직은 Domain에, Service는 흐름 조율만

## 레이어 다이어그램

```
Controller (API 진입점)
    ↓ Request DTO
Service (흐름 조율, 트랜잭션)
    ↓
Domain/Entity (비즈니스 로직)
    ↓
Repository (데이터 접근)
```

## 각 레이어 책임

| 레이어 | 책임 | 하지 말 것 |
|--------|------|-----------|
| Controller | 요청/응답 변환 | 비즈니스 로직 |
| **Service** | **흐름 조율**, 트랜잭션, 외부 연동 | **비즈니스 로직** |
| **Domain** | **비즈니스 로직**, 도메인 규칙 | 인프라 의존 |
| Repository | 데이터 접근 (CRUD) | 비즈니스 로직 |

---

## Service 레이어 (흐름 조율만)

```kotlin
@Service
@Transactional(readOnly = true)
class BookingService(
    private val bookingRepository: BookingRepository,
    private val vendorRepository: VendorRepository,
    private val paymentGateway: PaymentGateway  // 외부 시스템
) {
    @Transactional
    fun createBooking(command: CreateBookingCommand): Booking {
        // 1. 데이터 조회 (Repository)
        val vendor = vendorRepository.findById(command.vendorId)
            ?: throw NotFoundException("업체를 찾을 수 없습니다.")

        // 2. 도메인 로직 호출 (Domain에 위임)
        val booking = Booking.create(
            vendor = vendor,
            date = command.date,
            customerName = command.customerName
        )

        // 3. 외부 시스템 연동
        paymentGateway.hold(booking.totalAmount)

        // 4. 저장
        return bookingRepository.save(booking)
    }
}
```

**Service가 하는 것:**
- 트랜잭션 관리
- Repository 호출 (데이터 조회/저장)
- 외부 시스템 연동 (결제, 알림 등)
- **흐름 조율** (orchestration)

**Service가 하지 않는 것:**
- 비즈니스 규칙 검증
- 도메인 상태 변경 로직

---

## Domain 레이어 (비즈니스 로직)

```kotlin
@Entity
class Booking private constructor(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @ManyToOne(fetch = FetchType.LAZY)
    val vendor: Vendor,

    val date: LocalDate,
    val customerName: String,

    @Enumerated(EnumType.STRING)
    var status: BookingStatus = BookingStatus.PENDING,

    val totalAmount: Money
) {
    companion object {
        // 팩토리 메서드: 생성 시 비즈니스 규칙 검증
        fun create(vendor: Vendor, date: LocalDate, customerName: String): Booking {
            // 비즈니스 규칙: 과거 날짜 예약 불가
            require(date.isAfter(LocalDate.now())) {
                "예약은 오늘 이후 날짜만 가능합니다."
            }

            // 비즈니스 규칙: 업체가 예약 가능 상태인지
            require(vendor.isAvailable(date)) {
                "해당 날짜에 예약이 불가능합니다."
            }

            return Booking(
                vendor = vendor,
                date = date,
                customerName = customerName,
                totalAmount = vendor.calculatePrice(date)
            )
        }
    }

    // 비즈니스 로직: 예약 확정
    fun confirm() {
        require(status == BookingStatus.PENDING) {
            "대기 상태의 예약만 확정할 수 있습니다."
        }
        status = BookingStatus.CONFIRMED
    }

    // 비즈니스 로직: 예약 취소
    fun cancel(reason: String) {
        require(status != BookingStatus.COMPLETED) {
            "완료된 예약은 취소할 수 없습니다."
        }
        status = BookingStatus.CANCELLED
    }
}
```

**Domain이 하는 것:**
- 비즈니스 규칙 검증 (require)
- 상태 변경 로직
- 도메인 계산 (가격, 할인 등)
- 불변식(invariant) 유지

---

## 비교: 잘못된 vs 올바른 설계

### ❌ 잘못된 설계 (Service에 비즈니스 로직)

```kotlin
@Service
class BookingService {
    fun createBooking(command: CreateBookingCommand): Booking {
        // ❌ Service에서 비즈니스 규칙 검증
        if (command.date.isBefore(LocalDate.now())) {
            throw IllegalArgumentException("과거 날짜 예약 불가")
        }

        // ❌ Service에서 가격 계산
        val price = vendor.basePrice * 1.1

        val booking = Booking(
            vendor = vendor,
            date = command.date,
            totalAmount = price
        )
        return bookingRepository.save(booking)
    }
}
```

### ✅ 올바른 설계 (Domain에 비즈니스 로직)

```kotlin
@Service
class BookingService {
    fun createBooking(command: CreateBookingCommand): Booking {
        val vendor = vendorRepository.findById(command.vendorId)
            ?: throw NotFoundException("업체 없음")

        // ✅ Domain에 위임 - 비즈니스 규칙은 Domain이 알고 있음
        val booking = Booking.create(vendor, command.date, command.customerName)

        return bookingRepository.save(booking)
    }
}
```

---

## 요약: Tell, Don't Ask

```kotlin
// ❌ Ask: 상태를 물어보고 Service에서 판단
if (booking.status == BookingStatus.PENDING) {
    booking.status = BookingStatus.CONFIRMED
}

// ✅ Tell: Domain에게 행동을 시킴
booking.confirm()
```

**Domain이 자신의 상태를 알고, 자신의 규칙을 강제한다.**

# Weddly 아키텍처 가이드

> **핵심 원칙**: 비즈니스 로직은 Domain에, Service는 흐름 조율만

---

## 레이어 구조

| 레이어 | 책임 | 하지 말 것 |
|--------|------|-----------| 
| Controller | 요청/응답 변환 | 비즈니스 로직 |
| **Service** | **흐름 조율**, 트랜잭션, 외부 연동 | **비즈니스 로직** |
| **Domain** | **비즈니스 로직**, 도메인 규칙 | 인프라 의존 |
| Repository | 데이터 접근 (CRUD) | 비즈니스 로직 |

### 레이어 다이어그램

```
Controller (API 진입점)
    ↓ Request DTO
Service (흐름 조율, 트랜잭션)
    ↓
Domain/Entity (비즈니스 로직)
    ↓
Repository (데이터 접근)
```

---

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

---

## 도메인 모델

```
User     → 회원
Vendor   → 웨딩 업체
Service  → 업체 서비스
Booking  → 예약
Review   → 리뷰
Payment  → 결제
```

---

## Backend 레이어 상세

### Service 레이어 (흐름 조율만)

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

### Domain 레이어 (비즈니스 로직)

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

## Tell, Don't Ask 원칙

```kotlin
// ❌ Ask: 상태를 물어보고 Service에서 판단
if (booking.status == BookingStatus.PENDING) {
    booking.status = BookingStatus.CONFIRMED
}

// ✅ Tell: Domain에게 행동을 시킴
booking.confirm()
```

**Domain이 자신의 상태를 알고, 자신의 규칙을 강제한다.**

---

## Entity 설계 패턴

### 기본 구조

```kotlin
@Entity
@Table(name = "users")
class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false, unique = true)
    val email: String,

    @Column(nullable = false)
    var name: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: UserStatus = UserStatus.ACTIVE,

    @CreatedDate
    @Column(nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @LastModifiedDate
    @Column(nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
)
```

### 핵심 원칙

#### 1. 불변 vs 가변 필드

```kotlin
// ✅ Good: id, createdAt은 val (불변)
val id: Long = 0
val createdAt: LocalDateTime = LocalDateTime.now()

// ✅ Good: 변경 가능한 필드는 var
var name: String
var status: UserStatus
```

#### 2. 기본값 제공

```kotlin
// ✅ Good: 기본값으로 null 방지
var status: UserStatus = UserStatus.ACTIVE

// ❌ Bad: nullable 필드 남용
var status: UserStatus? = null
```

#### 3. 비즈니스 메서드는 Entity에

```kotlin
@Entity
class User(...) {
    fun activate() {
        require(status == UserStatus.INACTIVE) { "이미 활성 상태입니다." }
        status = UserStatus.ACTIVE
    }

    fun deactivate() {
        status = UserStatus.INACTIVE
    }
}
```

### 연관관계 설계

#### 1:N 관계

```kotlin
@Entity
class Vendor(
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @OneToMany(mappedBy = "vendor", cascade = [CascadeType.ALL], orphanRemoval = true)
    val services: MutableList<Service> = mutableListOf()
) {
    fun addService(service: Service) {
        services.add(service)
        service.vendor = this
    }
}

@Entity
class Service(
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendor_id", nullable = false)
    var vendor: Vendor
)
```

#### N+1 방지

```kotlin
// Repository에서 fetch join
@Query("SELECT v FROM Vendor v JOIN FETCH v.services WHERE v.id = :id")
fun findWithServices(@Param("id") id: Long): Vendor?
```

---

## Frontend 구조 (Next.js App Router)

### 디렉토리 구조

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

### 컴포넌트 분류

| 유형 | 위치 | 특징 |
|------|------|------|
| Server Component | `app/**/*.tsx` (기본) | 데이터 fetching, SEO |
| Client Component | `'use client'` 선언 | 상호작용, 상태 관리 |
| Shared Component | `components/` | 재사용 가능 UI |

### Server Component (기본)

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

### Client Component

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

### 데이터 흐름

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

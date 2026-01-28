# Entity 설계 패턴

## Entity 기본 구조

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

---

## 핵심 원칙

### 1. 불변 vs 가변 필드

```kotlin
// ✅ Good: id, createdAt은 val (불변)
val id: Long = 0
val createdAt: LocalDateTime = LocalDateTime.now()

// ✅ Good: 변경 가능한 필드는 var
var name: String
var status: UserStatus
```

### 2. 기본값 제공

```kotlin
// ✅ Good: 기본값으로 null 방지
var status: UserStatus = UserStatus.ACTIVE

// ❌ Bad: nullable 필드 남용
var status: UserStatus? = null
```

### 3. 비즈니스 메서드는 Entity에

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

---

## 연관관계 설계

### 1:N 관계

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

### N+1 방지

```kotlin
// Repository에서 fetch join
@Query("SELECT v FROM Vendor v JOIN FETCH v.services WHERE v.id = :id")
fun findWithServices(@Param("id") id: Long): Vendor?
```

---

## 도메인 모델 (Weddly)

```kotlin
// 핵심 Entity
User        // 회원 (일반/업체)
Vendor      // 웨딩 업체
Service     // 업체 서비스
Booking     // 예약
Review      // 리뷰
Payment     // 결제
```

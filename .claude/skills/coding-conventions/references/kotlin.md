# Kotlin + Spring Boot 베스트 프랙티스

## Kotlin 핵심 문법

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

---

## Spring Boot + Kotlin

### 1. Entity

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

### 2. Repository

```kotlin
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): User?
    fun existsByEmail(email: String): Boolean
}
```

### 3. Service

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

### 4. Controller

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

---

## JPA 성능 최적화

### N+1 문제 해결

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

---

## 금지 사항

| 하지 말 것 | 대신 |
|-----------|------|
| `!!` 남용 | `?.let`, `?:`, `requireNotNull` |
| `var` 남발 | `val` 우선 |
| 거대한 Service | 책임별로 분리 |

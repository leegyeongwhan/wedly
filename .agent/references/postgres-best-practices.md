# PostgreSQL 최적화 가이드 (Supabase Best Practices)

> Supabase에서 제공하는 PostgreSQL 성능 최적화 및 베스트 프랙티스 가이드

---

## 규칙 카테고리 (우선순위별)

| 우선순위 | 카테고리 | 영향도 | 접두사 |
|----------|----------|--------|--------|
| 1 | Query Performance | CRITICAL | `query-` |
| 2 | Connection Management | CRITICAL | `conn-` |
| 3 | Security & RLS | CRITICAL | `security-` |
| 4 | Schema Design | HIGH | `schema-` |
| 5 | Concurrency & Locking | MEDIUM-HIGH | `lock-` |
| 6 | Data Access Patterns | MEDIUM | `data-` |
| 7 | Monitoring & Diagnostics | LOW-MEDIUM | `monitor-` |
| 8 | Advanced Features | LOW | `advanced-` |

---

## 1. Query Performance (CRITICAL)

### 인덱스 추가 (WHERE, JOIN 컬럼)

**영향도:** 100-1000배 빠른 쿼리

인덱스가 없는 컬럼에서 필터링하거나 조인하면 전체 테이블 스캔이 발생합니다.

```sql
-- ❌ Bad: 인덱스 없음 (Sequential Scan)
select * from orders where customer_id = 123;
-- EXPLAIN: Seq Scan on orders (cost=0.00..25000.00)

-- ✅ Good: 인덱스 생성 (Index Scan)
create index orders_customer_id_idx on orders (customer_id);
select * from orders where customer_id = 123;
-- EXPLAIN: Index Scan using orders_customer_id_idx (cost=0.42..8.44)
```

**JOIN 컬럼 인덱싱:**

```sql
-- Foreign key 컬럼에 인덱스 생성
create index orders_customer_id_idx on orders (customer_id);

select c.name, o.total
from customers c
join orders o on o.customer_id = c.id;
```

---

## 2. Connection Management (CRITICAL)

### Connection Pooling 사용

**영향도:** 10-100배 더 많은 동시 사용자 처리

PostgreSQL 연결은 비용이 높습니다 (각 1-3MB RAM). 풀링 없이는 부하 시 연결이 고갈됩니다.

```sql
-- ❌ Bad: 요청마다 새 연결
-- 결과: 500 동시 사용자 = 500 연결 = 데이터베이스 다운

-- ✅ Good: Connection Pooling (PgBouncer)
-- 설정: pool_size = (CPU cores * 2) + spindle_count
-- 예: 4 cores → pool_size = 10
-- 결과: 500 동시 사용자가 10개 연결 공유
```

**Pool 모드:**
- **Transaction mode**: 트랜잭션 후 연결 반환 (대부분의 앱에 권장)
- **Session mode**: 세션 전체 동안 연결 유지 (prepared statements, temp tables 필요 시)

---

## 3. Security & RLS (CRITICAL)

### Row-Level Security (RLS)

PostgreSQL의 RLS를 사용하여 행 수준 보안을 구현합니다.

```sql
-- RLS 활성화
alter table orders enable row level security;

-- 정책 생성: 사용자는 자신의 주문만 볼 수 있음
create policy "Users can view own orders"
  on orders for select
  using (auth.uid() = user_id);
```

**성능 고려사항:**
- RLS 정책은 모든 쿼리에 WHERE 절을 추가합니다
- 정책에 사용되는 컬럼에 인덱스를 생성하세요

---

## 4. Schema Design (HIGH)

### Primary Key 전략 선택

**영향도:** 더 나은 인덱스 지역성, 단편화 감소

```sql
-- ❌ Bad: serial (구식)
create table users (
  id serial primary key  -- 작동하지만 IDENTITY 권장
);

-- ❌ Bad: Random UUID (v4) - 인덱스 단편화 발생
create table orders (
  id uuid default gen_random_uuid() primary key
);

-- ✅ Good: IDENTITY (SQL 표준, 대부분의 경우 최선)
create table users (
  id bigint generated always as identity primary key
);

-- ✅ Good: UUIDv7 (분산 시스템용, 시간 순서)
-- 확장 필요: create extension pg_uuidv7;
create table orders (
  id uuid default uuid_generate_v7() primary key
);
```

**가이드라인:**
- 단일 데이터베이스: `bigint identity` (순차적, 8바이트, SQL 표준)
- 분산/노출 ID: UUIDv7 또는 ULID (시간 순서, 단편화 없음)
- Random UUID (v4)는 대형 테이블의 PK로 피하세요

### Foreign Key에 인덱스 생성

```sql
-- Foreign key 컬럼에 자동으로 인덱스가 생성되지 않습니다!
create table orders (
  id bigint generated always as identity primary key,
  customer_id bigint references customers(id)
);

-- ✅ 명시적으로 인덱스 생성
create index orders_customer_id_idx on orders (customer_id);
```

---

## 5. Concurrency & Locking (MEDIUM-HIGH)

### 짧은 트랜잭션 유지

```sql
-- ❌ Bad: 긴 트랜잭션
begin;
  select * from orders for update;  -- 테이블 잠금
  -- ... 복잡한 비즈니스 로직 (10초) ...
commit;

-- ✅ Good: 짧은 트랜잭션
-- 비즈니스 로직을 트랜잭션 밖에서 수행
begin;
  update orders set status = 'confirmed' where id = 123;
commit;
```

### Deadlock 방지

```sql
-- ✅ 항상 같은 순서로 테이블/행 잠금
-- Transaction 1과 2 모두 같은 순서로 접근
begin;
  update customers set ... where id = 1;
  update orders set ... where customer_id = 1;
commit;
```

---

## 6. Data Access Patterns (MEDIUM)

### N+1 쿼리 제거

```sql
-- ❌ Bad: N+1 쿼리
select * from customers;  -- 1 쿼리
-- 각 고객마다:
select * from orders where customer_id = ?;  -- N 쿼리

-- ✅ Good: JOIN 사용
select c.*, o.*
from customers c
left join orders o on o.customer_id = c.id;
```

### Batch Insert 사용

```sql
-- ❌ Bad: 개별 INSERT
insert into orders (customer_id, total) values (1, 100);
insert into orders (customer_id, total) values (2, 200);
insert into orders (customer_id, total) values (3, 300);

-- ✅ Good: Batch INSERT
insert into orders (customer_id, total) values
  (1, 100),
  (2, 200),
  (3, 300);
```

### Cursor 기반 Pagination

```sql
-- ❌ Bad: OFFSET (느림, 큰 offset에서)
select * from orders
order by created_at desc
limit 20 offset 10000;  -- 10,000개 행을 스캔 후 버림

-- ✅ Good: Cursor 기반 (빠름)
select * from orders
where created_at < '2025-01-01'  -- 마지막 커서
order by created_at desc
limit 20;
```

---

## 7. Monitoring & Diagnostics (LOW-MEDIUM)

### EXPLAIN ANALYZE 사용

```sql
-- 쿼리 실행 계획 분석
explain analyze
select * from orders where customer_id = 123;

-- 주의사항:
-- - Seq Scan → 인덱스 필요
-- - High cost → 쿼리 최적화 필요
-- - Actual time vs Estimated → 통계 업데이트 필요
```

### pg_stat_statements 활성화

```sql
-- 느린 쿼리 찾기
select query, calls, total_exec_time, mean_exec_time
from pg_stat_statements
order by mean_exec_time desc
limit 10;
```

---

## 8. Advanced Features (LOW)

### JSONB 인덱싱

```sql
-- JSONB 컬럼에 GIN 인덱스
create table events (
  id bigint generated always as identity primary key,
  data jsonb
);

-- ✅ GIN 인덱스로 JSONB 쿼리 가속화
create index events_data_idx on events using gin (data);

-- 특정 키에 대한 인덱스
create index events_user_id_idx on events ((data->>'user_id'));
```

### Full-Text Search

```sql
-- tsvector 컬럼 생성
alter table articles add column search_vector tsvector;

-- 자동 업데이트 트리거
create trigger articles_search_update
before insert or update on articles
for each row execute function
  tsvector_update_trigger(search_vector, 'pg_catalog.english', title, content);

-- GIN 인덱스
create index articles_search_idx on articles using gin (search_vector);

-- 검색
select * from articles
where search_vector @@ to_tsquery('postgres & performance');
```

---

## 참고 자료

- [PostgreSQL Documentation](https://www.postgresql.org/docs/current/)
- [Supabase Database Guides](https://supabase.com/docs/guides/database/overview)
- [PostgreSQL Performance Optimization](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Row-Level Security](https://supabase.com/docs/guides/auth/row-level-security)

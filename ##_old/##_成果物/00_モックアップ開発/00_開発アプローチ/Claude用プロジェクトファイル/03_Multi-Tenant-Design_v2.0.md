# SECUREA City Smart Communication App
## Multi-Tenant Design Specification

**Document Version:** 2.0 (English Summary)  
**Created:** 2025/10/23  
**Target:** Extension from demo version  

---

## Table of Contents

1. [Purpose and Strategy](#1-purpose-and-strategy)
2. [Architecture Design](#2-architecture-design)
3. [Database Design](#3-database-design)
4. [Authentication & Authorization](#4-authentication--authorization)
5. [Data Access Layer](#5-data-access-layer)
6. [Tenant Management](#6-tenant-management)
7. [Security Design](#7-security-design)
8. [Performance Optimization](#8-performance-optimization)

---

## 1. Purpose and Strategy

### 1.1 Purpose

Transform from SECUREA City-specific app to **SaaS platform for multiple condos/communities**.

**Expected Benefits:**
- ✅ Easy horizontal expansion to other communities
- ✅ Optimized operational costs (shared infrastructure)
- ✅ Standardized features and quality improvement
- ✅ Development efficiency through scale

### 1.2 Approach

**Row-Level Multi-Tenancy**

```
┌─────────────────────────────────────┐
│   Shared Database (PostgreSQL)      │
├─────────────────────────────────────┤
│ tenant_id | user_id | name | ...    │
├─────────────────────────────────────┤
│     1     | 1001    | Tanaka | ...  │ ← SECUREA City
│     1     | 1002    | Suzuki | ...  │ ← SECUREA City
│     2     | 2001    | Smith  | ...  │ ← Condo A
│     2     | 2002    | Chen   | ...  │ ← Condo A
└─────────────────────────────────────┘
```

**Selection Reason:**
- Optimal for small-medium tenant count (target: 50-100)
- Cost-efficient single DB
- Easy maintenance
- Ensures data isolation and security
- Future separation (DB split) possible

**Comparison with Alternatives:**

| Approach | Cost | Isolation | Maintenance | Status |
|----------|------|-----------|-------------|---------|
| **Row-Level** | ◎ Low | ○ Medium | ◎ High | ✅ Adopted |
| DB per Tenant | ✗ High | ◎ High | ✗ Low | Not adopted |
| Schema per Tenant | △ Medium | ○ Medium | △ Medium | Not adopted |

---

## 2. Architecture Design

### 2.1 Overall Architecture

```
┌──────────────────────────────────────────────────────┐
│                  User Devices                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │securea-city │  │ mansion-a   │  │ mansion-b   │  │
│  │.app.com     │  │.app.com     │  │.app.com     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │
└─────────┼─────────────────┼─────────────────┼─────────┘
          │                 │                 │
          └─────────────────┴─────────────────┘
                            │
                            ▼
          ┌─────────────────────────────────┐
          │   Nginx (Reverse Proxy)         │
          │   - Subdomain identification    │
          │   - SSL/TLS termination         │
          └────────────┬────────────────────┘
                       │
                       ▼
          ┌─────────────────────────────────┐
          │   NestJS Application            │
          │                                 │
          │  ┌──────────────────────────┐  │
          │  │ Tenant Identification    │  │
          │  │ (Middleware)             │  │
          │  └──────────────────────────┘  │
          │                                 │
          │  ┌──────────────────────────┐  │
          │  │ Business Logic           │  │
          │  │ (Services)               │  │
          │  └──────────────────────────┘  │
          │                                 │
          │  ┌──────────────────────────┐  │
          │  │ Data Access Layer        │  │
          │  │ (Auto tenant_id filter)  │  │
          │  └──────────────────────────┘  │
          └────────────┬────────────────────┘
                       │
                       ▼
          ┌─────────────────────────────────┐
          │   PostgreSQL                    │
          │   - All tenants' data           │
          │   - Row-level isolation         │
          └─────────────────────────────────┘
```

### 2.2 Tenant Identification Flow

1. **Request Arrival** → Nginx receives with subdomain (e.g., securea-city.app.com)
2. **Tenant Resolution** → Middleware resolves tenant_id from subdomain
3. **Context Injection** → Tenant_id injected into request context
4. **Data Access** → All queries auto-filtered by tenant_id
5. **Response** → Return only tenant's data

---

## 3. Database Design

### 3.1 Core Tables

#### tenants (Tenant Master)
```sql
CREATE TABLE tenants (
    id                  SERIAL PRIMARY KEY,
    subdomain           VARCHAR(100) UNIQUE NOT NULL,
    name                VARCHAR(255) NOT NULL,
    display_name        JSONB NOT NULL,           -- {"ja": "...", "en": "...", "zh": "..."}
    plan                VARCHAR(50) NOT NULL,     -- 'free', 'basic', 'premium'
    status              VARCHAR(50) NOT NULL,     -- 'active', 'suspended', 'deleted'
    settings            JSONB,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenants_subdomain ON tenants(subdomain);
CREATE INDEX idx_tenants_status ON tenants(status);
```

#### users (User Master)
```sql
CREATE TABLE users (
    id                  SERIAL PRIMARY KEY,
    tenant_id           INTEGER NOT NULL REFERENCES tenants(id),
    email               VARCHAR(255) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    role                VARCHAR(50) NOT NULL,     -- 'admin', 'resident', 'manager'
    language            VARCHAR(10) DEFAULT 'ja', -- 'ja', 'en', 'zh'
    status              VARCHAR(50) NOT NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_users_email ON users(tenant_id, email);
```

### 3.2 Tenant Isolation Pattern

**All tables include tenant_id:**

```sql
CREATE TABLE posts (
    id          SERIAL PRIMARY KEY,
    tenant_id   INTEGER NOT NULL REFERENCES tenants(id),
    user_id     INTEGER NOT NULL REFERENCES users(id),
    title       VARCHAR(255) NOT NULL,
    content     TEXT NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_posts_tenant ON posts(tenant_id);
CREATE INDEX idx_posts_user ON posts(tenant_id, user_id);
```

**Row Level Security (RLS):**

```sql
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON posts
    USING (tenant_id = current_setting('app.current_tenant_id')::INTEGER);
```

---

## 4. Authentication & Authorization

### 4.1 Magic Link Authentication

```
User → Request magic link → System sends email with token
User → Click link → System validates token → Session created
```

**Token includes:**
- user_id
- tenant_id
- Expiration time (15 minutes)

### 4.2 Session Management

```javascript
interface Session {
    userId: number;
    tenantId: number;
    role: string;
    language: string;
}
```

### 4.3 Authorization Levels

| Role | Permissions |
|------|-------------|
| **admin** | Full tenant access, user management, settings |
| **manager** | Moderate posts, manage bulletins |
| **resident** | View, post, comment within permissions |

---

## 5. Data Access Layer

### 5.1 Auto Tenant Filtering

```typescript
@Injectable()
export class TenantContextService {
    private tenantId: number;

    setTenant(tenantId: number) {
        this.tenantId = tenantId;
    }

    getTenant(): number {
        if (!this.tenantId) {
            throw new Error('Tenant context not set');
        }
        return this.tenantId;
    }
}

@Injectable()
export class PostsRepository {
    constructor(
        private db: DatabaseService,
        private tenantContext: TenantContextService
    ) {}

    async findAll(): Promise<Post[]> {
        const tenantId = this.tenantContext.getTenant();
        return this.db.query(
            'SELECT * FROM posts WHERE tenant_id = $1',
            [tenantId]
        );
    }
}
```

### 5.2 Middleware

```typescript
@Injectable()
export class TenantMiddleware implements NestMiddleware {
    use(req: Request, res: Response, next: NextFunction) {
        const subdomain = extractSubdomain(req.hostname);
        const tenant = await this.tenantService.findBySubdomain(subdomain);
        
        if (!tenant) {
            throw new NotFoundException('Tenant not found');
        }
        
        req['tenantId'] = tenant.id;
        this.tenantContext.setTenant(tenant.id);
        
        next();
    }
}
```

---

## 6. Tenant Management

### 6.1 Tenant Registration Flow

1. **Application** → New tenant applies with basic info
2. **Approval** → Admin reviews and approves
3. **Provisioning** → System creates:
   - Tenant record
   - Subdomain mapping
   - Initial admin user
   - Default settings
4. **Activation** → Send welcome email with magic link

### 6.2 Tenant Settings

```typescript
interface TenantSettings {
    features: {
        board: boolean;
        booking: boolean;
        survey: boolean;
        chat: boolean;
    };
    limits: {
        maxUsers: number;
        maxStorage: number; // MB
    };
    branding: {
        logo?: string;
        primaryColor?: string;
    };
    languages: string[]; // ['ja', 'en', 'zh']
}
```

---

## 7. Security Design

### 7.1 Data Isolation

- ✅ All queries auto-filtered by tenant_id
- ✅ Row Level Security (RLS) enabled
- ✅ Middleware validates tenant context
- ✅ No cross-tenant data access possible

### 7.2 API Security

- ✅ HTTPS only
- ✅ CORS properly configured
- ✅ Rate limiting per tenant
- ✅ Input validation and sanitization

### 7.3 Authentication Security

- ✅ Magic link with short expiration (15 min)
- ✅ One-time use tokens
- ✅ Secure session management
- ✅ CSRF protection

---

## 8. Performance Optimization

### 8.1 Database Indexing

```sql
-- Critical indexes for multi-tenant queries
CREATE INDEX idx_users_tenant ON users(tenant_id);
CREATE INDEX idx_posts_tenant ON posts(tenant_id);
CREATE INDEX idx_bookings_tenant ON bookings(tenant_id);

-- Composite indexes for common queries
CREATE INDEX idx_posts_tenant_created ON posts(tenant_id, created_at DESC);
CREATE INDEX idx_users_tenant_email ON users(tenant_id, email);
```

### 8.2 Caching Strategy

- **Application level:** Cache tenant settings
- **Database level:** PostgreSQL query cache
- **Redis:** Session storage, frequently accessed data

### 8.3 Connection Pooling

```typescript
{
    type: 'postgres',
    host: process.env.DB_HOST,
    port: 5432,
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    extra: {
        max: 20,           // Max connections per tenant
        min: 5,            // Min connections
        idleTimeoutMillis: 30000
    }
}
```

---

## Summary

### Key Design Decisions

1. **Row-Level Multi-Tenancy** - Balance of cost, isolation, and maintainability
2. **Subdomain-based Identification** - Clean URL structure per tenant
3. **Automatic Tenant Filtering** - Security by default
4. **PostgreSQL with RLS** - Strong data isolation
5. **NestJS Architecture** - Modular, testable, scalable

### Migration Path

1. Single tenant (SECUREA City) → Prove concept
2. Add tenant table and ID columns → Prepare structure
3. Implement middleware → Enable multi-tenancy
4. Onboard pilot tenants → Validate approach
5. Scale to target (50-100 tenants) → Production ready

---

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025/10/24 | English summary version |
| 1.0 | 2025/10/23 | Initial Japanese version |

---

**Document ID:** SEC-APP-MULTITENANT-001  
**Last Updated:** 2025/10/24

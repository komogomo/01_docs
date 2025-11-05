# HarmoNet Technical Stack Definition v3.2 (Part1)
Version: 3.2  
Date: 2025-10-30  
Project: HarmoNet  
Author: TKD  
Language: EN

---

## Chapter 1. Overview

### 1.1 Purpose
This document defines the complete technical stack and architecture baseline for the HarmoNet application.  
It reflects the alignment with **System Architecture Specification v1.1** and **Functional Requirements v1.2**, consolidating backend, frontend, infrastructure, and authentication components.

### 1.2 Objectives
- Provide a unified technical reference for all AI collaborators (Claude, Gemini, GPT).  
- Define a maintainable, scalable, and secure architecture for HarmoNet as a multi-tenant SaaS platform.  
- Ensure consistency between system architecture, database design, and development workflow.

---

## Chapter 2. Backend Stack

| Component | Technology | Notes |
|------------|-------------|--------|
| Framework | NestJS (Node.js 10.x) | Modular REST API |
| ORM | Prisma ORM 5.x | Multi-tenant aware schema management |
| Database | PostgreSQL (Supabase) | RLS enabled |
| Cache | Redis 7.x | Session & Translation cache |
| API Docs | Swagger (OpenAPI 3.0) | Auto-generated endpoint documentation |
| Container | Docker Desktop 24.x | Unified local environment |
| Versioning | Git + Conventional Commits | GitHub repository integration |

### 2.1 Key Principles
- **Type Safety:** Prisma guarantees compile-time schema validation.  
- **Tenant Isolation:** All queries are automatically scoped by `tenant_id`.  
- **Scalability:** Backend supports both vertical and horizontal scaling.  
- **Security:** Supabase handles encryption, JWT issuance, and user authentication.

### 2.2 API Pattern Example
```
GET /api/v1/{tenant_code}/bbs
POST /api/v1/{tenant_code}/announcement
```

Each request passes through middleware injecting the current `tenant_id` before database execution.

---

## Chapter 3. Frontend Stack

| Layer | Technology | Notes |
|--------|-------------|--------|
| Framework | React 18 + PWA | Optimized for both desktop and mobile |
| Styling | Tailwind CSS 3.x | Minimalist Apple-catalog tone |
| Font | BIZ UD Gothic | Accessibility-compliant font |
| Build | Vite / Next.js | PWA build and SSR support |
| Deployment | Vercel | Serverless hosting |
| State Management | React Query + Zustand | Lightweight store |
| Translation | i18next + Google Cloud Translation API | JA/EN/CN supported |

### 3.1 UI Design
- Minimal and neutral design, focused on readability and harmony.  
- Consistent header/footer defined in **HarmoNet Design Guidelines**.  
- Language toggle (JA/EN/CN) always visible in the global header.

---

## Chapter 4. Infrastructure

| Layer | Service | Purpose |
|--------|----------|----------|
| Hosting | Vercel | Frontend + Serverless API |
| Database | Supabase PostgreSQL | Managed DB with RLS |
| Authentication | Supabase Auth | Magic Link, JWT |
| Storage | Supabase Storage | Image and attachment files |
| Mail | SendGrid / Amazon SES | Magic Link and system notifications |
| Notification | Firebase Cloud Messaging | Push notifications |
| Monitoring | UptimeRobot / Sentry | Availability & error tracking |
| CDN | Cloudflare (optional) | Static asset acceleration |

### 4.1 Deployment Pipeline
1. GitHub push → Vercel build & deploy  
2. Supabase database migrations via Prisma CI step  
3. Auto HTTPS / Certificate renewal handled by Vercel  
4. Daily backups via Supabase automated schedule

### 4.2 Future Migration Path
- AWS ECS + RDS planned for large-scale deployment.  
- Container image portability ensured via Docker.

---

## Chapter 5. Authentication & Authorization

### 5.1 Overview
Authentication has transitioned from a custom JWT-based Magic Link system to a **Supabase Auth + NextAuth** hybrid model.  
This change enhances multi-tenant integrity, maintainability, and integration with RLS.

### 5.2 Authentication Flow
1. User submits email → Magic Link sent via Supabase Auth.  
2. User clicks link → Supabase validates and issues JWT.  
3. JWT includes `tenant_id`, `role`, and `lang` claims.  
4. Prisma middleware injects tenant_id into all queries.  
5. Supabase RLS enforces row-level access control.

### 5.3 JWT Payload Example
```json
{
  "sub": "user-uuid",
  "tenant_id": "tenant-uuid",
  "role": "admin",
  "lang": "ja",
  "exp": 1735600000
}
```

### 5.4 Roles
| Role | Scope | Example Operations |
|------|--------|--------------------|
| system_admin | All tenants | Create/Delete tenants |
| tenant_admin | Within tenant | Manage users/settings |
| member | Personal | Post, reserve, comment |

### 5.5 Security Enhancements
| Feature | Description |
|----------|-------------|
| Token lifecycle | Managed by Supabase |
| Expiry | Configurable (15min default) |
| HTTPS enforcement | TLS 1.3 required |
| Rate limiting | 3 login requests/minute |
| Audit logging | Optional (Supabase internal) |

**Note:** The previous `magic_link_tokens` table has been deprecated in favor of Supabase’s managed token storage.  

---

## Chapter 6. Multi-tenant Architecture

### 6.1 Structure
Multi-tenancy in HarmoNet is achieved by logical isolation of data via `tenant_id`.  
Supabase RLS (Row Level Security) ensures tenant separation at the database layer.

| Table | Purpose |
|--------|----------|
| tenant | Basic tenant information |
| tenant_user | Association between users and tenants |
| tenant_features | Enabled feature flags |
| tenant_settings | Tenant configuration JSON |

### 6.2 tenant_features Definition
```yaml
tenant_features:
  - announcement
  - bbs
  - parking
  - survey
  - consumables  # Added in v1.2
```

### 6.3 RLS Example Policy
```sql
CREATE POLICY tenant_isolation_policy
ON public.bbs_posts
USING (tenant_id = auth.jwt() ->> 'tenant_id');
```

### 6.4 Prisma Middleware Injection
```ts
prisma.$use(async (params, next) => {
  if (params.args?.data && context.tenantId) {
    params.args.data.tenant_id = context.tenantId;
  }
  return next(params);
});
```

### 6.5 Benefits
- Logical tenant isolation (no schema duplication)  
- Simplified backup and migration  
- Lower operational cost compared to physical separation  
- Seamless integration with Supabase Auth JWT claims  

---

# HarmoNet Technical Stack Definition v3.2 (Part2)
Version: 3.2  
Date: 2025-10-30  
Project: HarmoNet  
Author: TKD  
Language: EN

---

## Chapter 7. Notification System

### 7.1 Overview
The notification system in HarmoNet is designed to support both **email-based** and **push-based** communication.  
Phase 1 implements email notifications via SendGrid, while Phase 2 extends to Firebase Cloud Messaging (FCM).

### 7.2 Email Notification (Phase 1)
| Component | Service | Purpose |
|------------|----------|----------|
| Provider | SendGrid / Amazon SES | Delivery of Magic Links and announcements |
| Trigger Events | Authentication, Reservation, Bulletin Replies |
| Language | Multi-language template (JA/EN/CN) |
| Format | HTML + Plain text |
| Retry Logic | 3 attempts with exponential backoff |

### 7.3 Push Notification (Phase 2)
| Component | Service | Purpose |
|------------|----------|----------|
| Provider | Firebase Cloud Messaging (FCM) | Real-time push notifications |
| Trigger Events | Announcements, Replies, Reservation updates |
| Device Binding | User device token stored per tenant |
| Multilingual Support | Messages localized via i18next |

### 7.4 Notification Routing
```
[System Event]
  → [Notification Service]
      → [SendGrid or FCM]
          → [User Device or Email]
```

### 7.5 Future Enhancements
- Scheduled notifications (e.g., cleaning duty reminders)  
- AI-based prioritization of push messages  
- Opt-in control per notification type  

---

## Chapter 8. External Services

| Service | Purpose | Notes |
|----------|----------|-------|
| **Supabase Auth** | Authentication, JWT issuance | Magic Link support |
| **Supabase Storage** | Image and attachment storage | RLS enabled |
| **Google Cloud Translation API** | Real-time translation | 500k chars/month free |
| **SendGrid / SES** | Email delivery | Transactional emails |
| **Firebase Cloud Messaging** | Push notifications | Phase 2 |
| **UptimeRobot** | Availability monitoring | 3-min ping |
| **Sentry** | Error monitoring | Linked to Vercel build |
| **Cloudflare** | CDN acceleration (optional) | Static content |

**Note:** All external services have been selected for their open API accessibility, low maintenance cost, and free-tier availability.

---

## Chapter 9. Performance & Scalability

### 9.1 Targets
| Metric | Target | Notes |
|---------|---------|-------|
| Initial Page Load | ≤3s | PWA optimization |
| Subsequent Load | ≤1s | Cached resources |
| API Response Time | ≤2s (95th percentile) | Supabase edge caching |
| Concurrent Users | 200 (MVP) / 500 (Extended) | Horizontally scalable |
| Translation Latency | ≤5s for 500 characters | Cached via Redis |

### 9.2 Optimization Methods
- Lazy loading of components  
- Image optimization (WebP)  
- Prisma query indexing  
- CDN cache for static files  
- Redis cache for translations  

### 9.3 Scalability Strategy
1. Vertical scaling via Supabase plan upgrade  
2. Horizontal scaling via AWS ECS (planned)  
3. Load balancing through Vercel edge nodes  
4. Distributed caching (Redis cluster)  

---

## Chapter 10. Security & Compliance

### 10.1 Security Design Principles
- **Data Isolation:** Enforced through Supabase RLS + tenant_id.  
- **Encryption:** TLS 1.3 for all communications; AES-256 for stored data.  
- **Key Management:** Supabase Secrets / Vercel environment variables.  
- **Access Control:** Role-based (system_admin / tenant_admin / member).  
- **Logging:** Sentry integrated with error stack trace retention.

### 10.2 Threat Mitigation
| Threat | Countermeasure |
|--------|----------------|
| Brute-force login | Rate limiting (3 req/min) |
| Token replay | Expiry validation (15 min) |
| XSS / CSRF | HttpOnly cookies, CSP headers |
| SQL injection | Prisma ORM protection |
| Unauthorized access | RLS + JWT claims verification |
| Data leakage | No cross-tenant queries permitted |

### 10.3 Compliance Considerations
- GDPR-aligned data retention policy  
- No personal sensitive data stored (email only)  
- Data deletion supported per tenant request  
- Email verification required for all users  

### 10.4 Backup & Recovery
| Type | Frequency | Retention | Location |
|------|------------|------------|----------|
| Full DB | Daily | 7 days | Supabase auto-backup |
| Monthly Snapshot | Monthly | 12 months | Cloud Storage |
| Storage Files | Real-time | 30 days | Supabase versioning |

---

## Chapter 11. Phased Implementation Plan

### 11.1 Overview
Development and deployment of HarmoNet follow a phased roadmap to balance MVP delivery and future scalability.

| Phase | Timeline | Major Features |
|--------|-----------|----------------|
| Phase 1 | MVP Launch | Bulletin Board, Announcements, Parking Reservation, Notification, My Page |
| Phase 2 | +6 months | Push Notification (FCM), Survey System, **Consumables Inquiry & Ordering**, Cleaning Schedule |
| Phase 3 | +1 year | HEMS Integration, AI Translation Optimization, Multi-tenant Scaling |
| Phase 4 | +2 years | IoT Integration, Predictive Analytics, Community Features |

### 11.2 Phase 2 - Consumables Feature Detail
**Purpose:** Enable residents to check and order consumable goods such as filters, bulbs, and batteries online.  
**Data Model:**  
Tables `consumables_items`, `consumables_orders`, and `consumables_suppliers`.  
**Integration:** Management company or EC system via REST API.  
**Status:** Planned implementation; tenant-level feature toggle supported via `tenant_features`.

### 11.3 Phase 3+ Expansion
- **Phase 3:** AI summarization, cross-tenant admin console, enhanced analytics.  
- **Phase 4:** Smart home integration (IoT locks, sensors), automated reports, sustainability metrics.

---

**End of Technical Stack Definition v3.2**


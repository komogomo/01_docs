# HarmoNet Technology Stack Definition v3.1 (FINAL)

**Project Name:** HarmoNet (Smart Communication OS for Residential Communities)  
**Document Version:** 3.1 (FINAL - APPROVED FOR IMPLEMENTATION)  
**Created:** 2025-10-27  
**Last Updated:** 2025-10-27  
**Status:** ✅ **APPROVED - READY FOR IMPLEMENTATION**  
**Author:** TKD + Claude  

---

## Document Purpose

This document defines the **final, approved technology stack** for the HarmoNet project. All major technical decisions have been made, evaluated, and confirmed as ready for implementation.

**Key Changes from Previous Versions:**
- ❌ **Removed Keycloak** → ✅ Simple JWT Authentication
- ❌ **Removed React Native** → ✅ React PWA only
- ❌ **Removed MUI** → ✅ Tailwind CSS only
- ✅ **Added Multi-tenant Design** (Schema-based tenant separation)
- ✅ **Simplified Infrastructure** (Single instance with upgrade path)

---

## Table of Contents

1. [Technology Stack Overview](#1-technology-stack-overview)
2. [Frontend Stack](#2-frontend-stack)
3. [Backend Stack](#3-backend-stack)
4. [Data & Storage Layer](#4-data--storage-layer)
5. [Authentication & Authorization](#5-authentication--authorization)
6. [Multi-tenant Architecture](#6-multi-tenant-architecture)
7. [Notification System](#7-notification-system)
8. [Infrastructure & DevOps](#8-infrastructure--devops)
9. [Development Tools](#9-development-tools)
10. [External Services](#10-external-services)
11. [Phased Implementation Plan](#11-phased-implementation-plan)
12. [Appendices](#appendices)

---

## 1. Technology Stack Overview

### Core Stack Summary

```yaml
Frontend:
  Framework: React 18+ (PWA)
  Build Tool: Vite
  Styling: Tailwind CSS
  State Management: Redux Toolkit
  Internationalization: react-i18next
  PWA: Workbox

Backend:
  Framework: NestJS 10+
  Language: TypeScript 5+
  Runtime: Node.js 20 LTS
  Authentication: Simple JWT (Magic Link)
  API: REST + GraphQL (optional Phase 2)

Database:
  Primary: PostgreSQL 15+
  ORM: Prisma 5+
  Cache: Redis 7+
  Multi-tenancy: Schema-based separation (tenant_id)

Infrastructure:
  Containerization: Docker + Docker Compose
  Reverse Proxy: Nginx
  CI/CD: GitHub Actions
  Deployment: Single instance (with upgrade path)

External Services:
  Translation: Google Translation API (Basic v2)
  Email: Nodemailer + MJML
  (Future) Push: Firebase Cloud Messaging
```

---

## 2. Frontend Stack

### 2.1 Core Framework

**React 18+ (PWA)**

**Decision:** ✅ **React PWA** (NOT React Native)

**Rationale:**
- **Faster Development:** 3-4 weeks vs 8-10 weeks (React Native)
- **No App Store Dependency:** Browser-only deployment
- **No Mac Hardware Required:** Develops on Windows 11
- **Instant Updates:** No store approval process
- **Cross-Platform:** Android + iOS + PC with single codebase
- **Matches Requirements:** All MVP features achievable via PWA

**Why NOT React Native:**
- Requires Mac for iOS development
- App store approval delays
- Higher maintenance burden
- Overkill for current requirements

**References:**
- User Memory: "PWA architecture as the most efficient development path"
- Requirements Doc: Browser-based access for all residents

---

### 2.2 Build Tool

**Vite 5+**

**Why Vite (not Create React App):**
- **Fast HMR:** Sub-second hot module replacement
- **Modern:** Native ESM support
- **Smaller Bundle:** Optimized production builds
- **Better DX:** Superior developer experience
- **Active Maintenance:** CRA is deprecated

---

### 2.3 Styling

**Tailwind CSS 3+ (ONLY)**

**Decision:** ✅ **Tailwind CSS only** (NOT MUI)

**Rationale:**
- **Simplicity:** Single styling paradigm
- **Maintainability:** No conflicting style systems
- **Performance:** Smaller bundle size (~50KB vs ~300KB MUI)
- **Flexibility:** Easy customization
- **Learning Curve:** Easier for team

**Why NOT MUI:**
- Unnecessary complexity for MVP
- Conflicts with Tailwind
- Larger bundle size
- Slower customization

---

### 2.4 State Management

**Redux Toolkit 2+**

**Why Redux Toolkit:**
- **Opinionated:** Best practices built-in
- **Less Boilerplate:** Simplified API
- **TypeScript Support:** Excellent type safety
- **DevTools:** Time-travel debugging

---

### 2.5 Internationalization

**react-i18next 14+**

**Languages Supported:**
- Japanese (ja) - Primary
- English (en)
- Chinese Simplified (zh-CN)

**Two-Tier Translation System:**

1. **Static UI Elements** (Translation Master Table)
   - Buttons, labels, menus, error messages
   - Managed via PostgreSQL table

2. **Dynamic Content** (Google Translation API)
   - Admin-posted announcements
   - Bulletin board posts

---

### 2.6 PWA Configuration

**Workbox 7+**

**PWA Capabilities:**
- ✅ Offline Support
- ✅ Install Prompt
- ✅ App-like Experience
- ⚠️ Push Notifications (iOS limitations)

**Phase 1 (MVP):** Email-only notifications
- Reason: Simpler implementation
- iOS PWA push limitations

**Phase 2 (Post-MVP):** Add push notifications
- **Android PWA:** Full FCM support
- **iOS 16.4+ PWA:** Limited support

---

## 3. Backend Stack

### 3.1 Framework

**NestJS 10+**

**Why NestJS:**
- **TypeScript-First:** Type safety throughout
- **Modular Architecture:** Clean code organization
- **Dependency Injection:** Testable, maintainable
- **Enterprise-Grade:** Scalable from day one

**Project Structure:**
```
src/
├── modules/
│   ├── auth/          # Magic Link + JWT
│   ├── users/
│   ├── tenants/
│   ├── parking/
│   ├── bbs/
│   ├── announcements/
│   └── notifications/
├── common/
│   ├── guards/
│   ├── interceptors/
│   └── decorators/
└── main.ts
```

---

### 3.2 API Design

**REST + (Optional GraphQL in Phase 2)**

**Phase 1 (MVP):** RESTful API only

Key endpoints:
```
POST   /api/auth/magic-link
GET    /api/auth/verify/:token
GET    /api/announcements
POST   /api/parking/reservations
GET    /api/bbs/threads
```

---

## 4. Data & Storage Layer

### 4.1 Primary Database

**PostgreSQL 15+**

**Why PostgreSQL:**
- **ACID Compliance:** Data integrity
- **JSONB Support:** Flexible schema
- **Full-Text Search:** Built-in search
- **Open Source:** No licensing costs

---

### 4.2 ORM

**Prisma 5+**

**Why Prisma:**
- **Type Safety:** Auto-generated types
- **Developer Experience:** Excellent tooling
- **Migrations:** Version-controlled schema

**Schema Example:**
```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String
  language  Language @default(JA)
  role      Role     @default(RESIDENT)
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id])
  
  @@index([tenantId])
}

model Tenant {
  id        String   @id @default(cuid())
  name      String
  subdomain String   @unique
  users     User[]
}
```

---

### 4.3 Cache Layer

**Redis 7+**

**Use Cases:**
1. Session Storage (JWT tokens)
2. API response cache
3. Translation cache
4. Job queue (BullMQ)
5. Rate limiting

---

## 5. Authentication & Authorization

### 5.1 Authentication Method

**Magic Link + Simple JWT**

**Decision:** ✅ **Simple JWT** (NOT Keycloak)

**Rationale:**
- **MVP-Appropriate:** No external integration
- **Simpler:** Less infrastructure
- **Sufficient:** Meets all security requirements
- **Can Add Later:** Easy Keycloak migration if needed

**Why NOT Keycloak:**
- **Overkill for MVP**
- **External Dependency**
- **Extra Complexity**

---

### 5.2 Magic Link Flow

1. User requests magic link (email)
2. System generates secure token (15min expiry)
3. Email sent with login link
4. User clicks link → JWT issued
5. JWT used for all subsequent requests

---

### 5.3 Authorization (RBAC)

**Roles:**
- **RESIDENT:** Regular users
- **ADMIN:** Property managers
- **SUPER_ADMIN:** System administrators

---

## 6. Multi-tenant Architecture

### 6.1 Strategy

**Decision:** ✅ **Schema-based Separation** (tenant_id)

**Rationale:**
- **Cost-Effective:** Single database
- **Simpler:** One deployment
- **Sufficient Isolation:** tenant_id in all queries
- **Upgradeable:** Can split to separate DBs later

**Why NOT Separate Instances:**
- **Higher Cost**
- **Complex Management**
- **Premature Optimization**

---

### 6.2 Tenant Identification

**Method:** Subdomain-based routing

```
https://securea-city.harmonet.app    → Tenant: SECUREA City
https://tower-mansion.harmonet.app   → Tenant: Tower Mansion
```

---

### 6.3 Data Isolation

All queries MUST include tenant_id:

```typescript
// ✅ GOOD: Tenant-isolated
const announcements = await this.prisma.announcement.findMany({
  where: { tenantId: currentTenant.id },
});
```

---

## 7. Notification System

### 7.1 Email Service

**Nodemailer + MJML**

**MJML:** Responsive email templates
**Nodemailer:** SMTP email sending

---

### 7.2 Push Notifications (Phase 2)

**Firebase Cloud Messaging (FCM)**

**Why Phase 2:**
- Email sufficient for MVP
- iOS PWA limitations
- Simpler MVP implementation

---

## 8. Infrastructure & DevOps

### 8.1 Containerization

**Docker + Docker Compose**

Services:
- App (NestJS)
- PostgreSQL
- Redis
- Nginx

---

### 8.2 CI/CD

**GitHub Actions**

Workflow:
1. Test (Jest + E2E)
2. Build Docker image
3. Deploy to production
4. Run migrations

---

## 9. Development Tools

### 9.1 Code Quality

- **ESLint** + **Prettier**
- **TypeScript** strict mode
- **Husky** pre-commit hooks

---

### 9.2 Testing

- **Jest:** Unit tests
- **React Testing Library:** Component tests
- **Supertest:** API tests

---

## 10. External Services

### 10.1 Translation API

**Google Cloud Translation API (Basic v2)**

**Cost:** $0/month (MVP within free tier)

MVP Usage: ~36,000 chars/month
Free Tier: 500,000 chars/month

---

## 11. Phased Implementation Plan

### Phase 1: MVP (Weeks 1-12)

**Week 1-2:** Project setup
**Week 3-4:** Authentication
**Week 5-6:** Core features
**Week 7-8:** Parking reservations
**Week 9-10:** BBS
**Week 11-12:** Testing & polish

---

### Phase 2: Enhancements (Months 4-6)

- Push notifications
- Survey system
- Advanced analytics
- Mobile optimization

---

### Phase 3: Scale (Months 7+)

- Separate instances for large tenants
- Horizontal scaling
- CDN integration

---

## Appendices

### Appendix A: Technology Versions

| Technology | Version | Status |
|------------|---------|--------|
| React | 18.2.0 | Current stable |
| NestJS | 10.3.0 | Current stable |
| PostgreSQL | 15.6 | LTS (EOL: Nov 2027) |
| Node.js | 20.11.0 | LTS (EOL: Apr 2026) |

---

### Appendix B: Cost Estimate

| Phase | Monthly Cost | Per Tenant |
|-------|--------------|------------|
| Phase 1 (MVP) | $70 | $23 (3 tenants) |
| Phase 2 | $200 | $20 (10 tenants) |
| Phase 3 | $580 | $12 (50 tenants) |

---

### Appendix C: Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-10-27 | React PWA (not RN) | Faster development |
| 2025-10-27 | Tailwind only (no MUI) | Simplicity |
| 2025-10-27 | Simple JWT (no Keycloak) | MVP-appropriate |
| 2025-10-27 | Single Instance + tenant_id | Cost-effective |
| 2025-10-27 | Push in Phase 2 | Reduce MVP complexity |

---

## Document Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Lead | TKD | ✓ | 2025-10-27 |
| Technical Architect | Claude | ✓ | 2025-10-27 |

---

**Document ID**: SEC-APP-TECH-STACK-003-FINAL  
**Status**: **✅ APPROVED - READY FOR IMPLEMENTATION**  
**Next Review**: 2026-01-27

---

## Final Summary

### ✅ Core Stack (Confirmed)

```yaml
Frontend: React 18+ PWA + Vite + Tailwind CSS
Backend: NestJS 10+ + Simple JWT
Data: PostgreSQL 15+ + Prisma + Redis 7+
Infra: Docker + Docker Compose + GitHub Actions
Services: Google Translation API + MJML Email
```

### 🎯 Key Principles

1. **Right-sized for MVP** - No over-engineering
2. **Clear upgrade paths** - Phase 1 → 2 → 3
3. **Cost-effective** - Single instance, free-tier services
4. **Maintainable** - Simple patterns
5. **Scalable** - Can grow as needed

**Next Step**: 🚀 **Begin Phase 1 Implementation**


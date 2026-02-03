# Technical Implementation Plan: [Feature Name]

**Feature ID**: [e.g., 001]
**Status**: [Draft / In Review / Approved / In Progress / Completed]
**Created**: [YYYY-MM-DD]
**Last Updated**: [YYYY-MM-DD]
**Owner**: [Name/Team]

**Related Documents**:
- Specification: [Link to specification.md]
- Constitution: [Link to constitution.md]

---

## Constitutional Compliance

Before proceeding, verify this plan adheres to project constitution:

### Architecture Principles
- [ ] Follows approved design patterns: [List applicable patterns from constitution]
- [ ] Adheres to layering strategy
- [ ] Meets performance targets: [Specify targets]

### Testing Standards
- [ ] Testing approach: [e.g., TDD for business logic]
- [ ] Coverage targets: [e.g., > 80% line coverage]
- [ ] Required test types included: [Unit, integration, E2E, etc.]

### Security Requirements
- [ ] Authentication method: [Per constitution]
- [ ] Authorization strategy: [Per constitution]
- [ ] Data protection: [Encryption standards met]
- [ ] Compliance: [Relevant standards addressed]

### Tech Stack
- [ ] All technologies approved: [List technologies used]
- [ ] No prohibited technologies used
- [ ] Any new technologies follow adoption process

### Quality Gates
- [ ] Pre-commit checklist will be followed
- [ ] Pre-PR checklist will be followed
- [ ] Pre-release checklist will be followed

**Constitutional Exemptions** (if any):
[Document any deviations from constitution with rationale and approval]

---

## Architecture Overview

### High-Level Design

```
[Diagram or ASCII art showing system components and their interactions]

Example:
┌─────────────┐
│  Client App │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────┐
│   API Gateway   │◄─── Rate Limiting, Auth
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌────────┐
│Service │ │Service │
│   A    │ │   B    │
└───┬────┘ └───┬────┘
    │          │
    └────┬─────┘
         ▼
    ┌─────────┐
    │Database │
    └─────────┘
```

### Component Breakdown

#### Component 1: [Name]
- **Responsibility**: [What does this component do?]
- **Technology**: [Implementation technology]
- **Interfaces**: [APIs it exposes, dependencies it consumes]
- **Data**: [What data does it own/manage?]

#### Component 2: [Name]
[Repeat structure for each major component]

### Design Patterns Applied

| Pattern | Where Used | Rationale |
|---------|------------|-----------|
| [e.g., Repository] | [Data access layer] | [Abstracts database, enables testing, constitutional requirement] |
| [e.g., Factory] | [Payment provider creation] | [Support multiple providers, easy to extend] |
| [e.g., Observer] | [Event handling] | [Decouple components, enable async processing] |

---

## Technology Choices

### Technology Stack

| Layer | Technology | Version | Rationale | Alternatives Considered |
|-------|------------|---------|-----------|------------------------|
| **Frontend** | | | | |
| Framework | [e.g., React] | [e.g., 18.2] | [Constitutional requirement, team expertise] | [Vue, Angular - rejected due to...] |
| State Mgmt | [e.g., Redux Toolkit] | [e.g., 1.9] | [Constitutional requirement, handles async well] | [Zustand - considered but...] |
| Build Tool | [e.g., Vite] | [e.g., 4.0] | [Fast HMR, better DX than webpack] | [Webpack - slower build times] |
| **Backend** | | | | |
| Language | [e.g., Python] | [e.g., 3.11] | [Constitutional requirement] | - |
| Framework | [e.g., FastAPI] | [e.g., 0.100] | [Async support, auto docs, type hints] | [Flask - less features] |
| **Data** | | | | |
| Database | [e.g., PostgreSQL] | [e.g., 15] | [Constitutional requirement, ACID guarantees] | - |
| Cache | [e.g., Redis] | [e.g., 7.0] | [Constitutional requirement, fast KV store] | - |
| **Infrastructure** | | | | |
| Container | [e.g., Docker] | [e.g., 24] | [Constitutional requirement] | - |
| Orchestration | [e.g., Kubernetes] | [e.g., 1.28] | [Constitutional requirement, auto-scaling] | - |

### Third-Party Services

| Service | Purpose | Pricing Model | Risk Assessment |
|---------|---------|---------------|-----------------|
| [e.g., Stripe] | Payment processing | [Pay per transaction] | [Vendor lock-in: Medium, Mitigation: Abstract behind interface] |
| [e.g., SendGrid] | Email delivery | [Pay per email] | [Service outage: Low, Mitigation: Queue for retry] |

### New Dependencies

If introducing new libraries/frameworks not in constitution:

| Dependency | Purpose | Why Not Existing Solution? | Approval Status |
|------------|---------|---------------------------|-----------------|
| [e.g., library-name] | [Purpose] | [Existing solution lacks X] | [Approved by: Tech Lead on YYYY-MM-DD] |

---

## Data Model

### Database Schema

#### Table: [table_name]

```sql
CREATE TABLE table_name (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL,
    field_value INTEGER CHECK (field_value > 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Indexes
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at DESC),
    UNIQUE INDEX idx_user_field (user_id, field_name)
);
```

**Design Decisions**:
- Using UUID for distributed system compatibility
- Soft delete via `is_active` for audit trail
- Indexed on `user_id` for query performance
- Unique constraint on `(user_id, field_name)` to prevent duplicates

#### Table: [table_name_2]
[Repeat for each table]

### Entity Relationships

```
[ERD diagram or description]

Example:
User (1) ──── (N) PaymentMethod
  │
  │
  └─── (N) Transaction
          │
          └─── (1) PaymentMethod
```

### Data Migration

**From**: [Current state]
**To**: [Desired state]

**Migration Strategy**:
1. [Step 1: e.g., Add new columns with default values]
2. [Step 2: e.g., Backfill data with background job]
3. [Step 3: e.g., Switch application to use new schema]
4. [Step 4: e.g., Drop old columns after validation]

**Rollback Plan**:
- [How to revert if migration fails]

**Estimated Duration**: [Time]
**Downtime Required**: [Yes/No, duration if yes]

---

## API Contracts

### REST API Endpoints

#### Endpoint: Create Payment Method

```
POST /api/v1/payment-methods
```

**Request Headers**:
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "type": "card",
  "token": "tok_visa_1234",  // From payment provider
  "is_default": false
}
```

**Response (201 Created)**:
```json
{
  "id": "pm_abc123",
  "user_id": "user_xyz",
  "type": "card",
  "last_four": "4242",
  "brand": "visa",
  "expiry": "2025-12",
  "is_default": false,
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid token or input
- `401 Unauthorized`: Missing or invalid auth token
- `409 Conflict`: Payment method already exists
- `422 Unprocessable Entity`: Card declined by provider
- `500 Internal Server Error`: Server error

**Validation Rules**:
- `type` must be one of: ["card", "bank_account"]
- `token` must be valid provider token
- Rate limit: 10 requests per minute per user

---

#### Endpoint: [Another endpoint]
[Repeat structure for each endpoint]

---

### WebSocket Endpoints

[If applicable]

```
WSS /api/v1/transactions/stream
```

**Authentication**: JWT in query param `?token={jwt}`

**Message Format**:
```json
{
  "event": "transaction.created",
  "data": { ... }
}
```

---

### Event Schemas

If using event-driven architecture:

#### Event: payment_method.created

**Published By**: Payment Service
**Consumed By**: Analytics Service, Notification Service

**Schema**:
```json
{
  "event_id": "evt_123",
  "event_type": "payment_method.created",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "payment_method_id": "pm_abc123",
    "user_id": "user_xyz",
    "type": "card"
  }
}
```

---

## Security Design

### Authentication Flow

```
1. User submits credentials
2. Auth service validates against user store
3. Generate JWT access token (15 min expiry)
4. Generate refresh token (7 day expiry)
5. Return both tokens to client
6. Client includes access token in Authorization header
7. When access token expires, use refresh token to get new access token
```

**Token Structure**:
```json
{
  "sub": "user_id",
  "iat": 1234567890,
  "exp": 1234568790,
  "roles": ["user"],
  "permissions": ["read:profile", "write:payment_methods"]
}
```

### Authorization Model

**Role-Based Access Control (RBAC)**:

| Role | Permissions |
|------|------------|
| User | read:own_profile, write:own_payment_methods, read:own_transactions |
| Admin | read:all_users, write:all_data, delete:users |
| Support | read:user_data, write:support_notes |

**Authorization Check**:
```python
def check_permission(user, resource, action):
    # 1. Extract user roles from JWT
    # 2. Check if any role has required permission
    # 3. If resource has owner, verify user is owner or has admin role
    # 4. Return allow/deny
```

### Data Security

**Encryption at Rest**:
- Database: AES-256 encryption via PostgreSQL pgcrypto
- Sensitive fields: Application-level encryption with per-tenant keys
- Key management: AWS KMS / HashiCorp Vault

**Encryption in Transit**:
- All API calls: TLS 1.3
- Certificate management: Auto-renewal via cert-manager
- Internal service-to-service: mTLS

**Secrets Management**:
- Environment variables injected via Kubernetes secrets
- Secrets stored in: [e.g., AWS Secrets Manager]
- Rotation policy: Every 90 days

### Input Validation

**Client-Side**:
- Type validation via TypeScript
- Format validation via form library
- User-friendly error messages

**Server-Side** (never trust client):
- Schema validation via Pydantic models
- SQL injection prevention: Parameterized queries only
- XSS prevention: Output encoding, CSP headers
- CSRF prevention: CSRF tokens for state-changing operations
- Rate limiting: 100 requests/min per IP, 50 requests/min per user

---

## Testing Strategy

### Test Pyramid

```
        / \
       /E2E\ ──── 5% (Critical user journeys)
      /─────\
     / Integ \ ── 25% (API, database, external services)
    /─────────\
   /   Unit    \ ─ 70% (Business logic, pure functions)
  /─────────────\
```

### Unit Tests

**Coverage Target**: > 80% for business logic

**Framework**: [e.g., pytest for Python, Jest for TypeScript]

**What to test**:
- [ ] All business logic functions
- [ ] Edge cases and boundary conditions
- [ ] Error handling paths
- [ ] Input validation

**Example Test**:
```python
def test_create_payment_method_validates_token():
    # Given: Invalid token
    invalid_token = "invalid"

    # When: Attempt to create payment method
    result = payment_service.create(invalid_token)

    # Then: Expect validation error
    assert result.error == "Invalid token format"
```

### Integration Tests

**Coverage Target**: All API endpoints, all external integrations

**Framework**: [e.g., pytest with testcontainers]

**What to test**:
- [ ] All REST API endpoints (happy path + errors)
- [ ] Database operations (CRUD, transactions)
- [ ] External API integrations (with mocks/stubs)
- [ ] Event publishing and consumption

**Test Environment**:
- Use Docker containers for database, cache
- Mock external services (Stripe, SendGrid)
- Seed database with test data

### End-to-End Tests

**Coverage Target**: Critical user journeys only

**Framework**: [e.g., Playwright for web, Detox for mobile]

**Critical Journeys**:
1. User signup → Add payment method → Make purchase
2. User login → Update payment method → Delete payment method
3. Failed payment → Retry with different method → Success

**Test Environment**:
- Staging environment (production-like)
- Test user accounts
- Test payment tokens (Stripe test mode)

### Performance Tests

**Framework**: [e.g., k6, Locust]

**Scenarios**:
- **Load Test**: Simulate expected peak traffic (1000 concurrent users)
- **Stress Test**: Find breaking point (ramp up until failure)
- **Soak Test**: Sustained load for 24 hours (check for memory leaks)

**Success Criteria**:
- API p95 latency < 200ms under expected load
- Database query p95 < 50ms
- Zero errors under expected load
- < 0.1% errors under 2x expected load

### Security Tests

**Automated**:
- [ ] OWASP dependency check (Snyk, npm audit)
- [ ] Static code analysis (Bandit, ESLint security rules)
- [ ] Container image scanning (Trivy, Clair)

**Manual**:
- [ ] Penetration testing for critical features
- [ ] Security review of authentication/authorization logic
- [ ] Review of secrets management

---

## Monitoring & Observability

### Logging

**Log Structure** (JSON format):
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "service": "payment-service",
  "trace_id": "abc123",
  "span_id": "def456",
  "user_id": "user_xyz",
  "message": "Payment method created",
  "payment_method_id": "pm_abc123"
}
```

**Log Levels**:
- DEBUG: Development only
- INFO: Important business events
- WARN: Recoverable errors, degraded performance
- ERROR: Unrecoverable errors, require attention

**What to Log**:
- [ ] All API requests (method, path, status, duration)
- [ ] All business events (payment created, transaction completed)
- [ ] All errors with stack traces
- [ ] All authentication/authorization events

**What NOT to Log**:
- ❌ Passwords, tokens, API keys
- ❌ Full credit card numbers
- ❌ PII unless absolutely necessary (hash/mask if needed)

### Metrics

**Infrastructure Metrics** (via Prometheus):
- CPU usage, memory usage, disk I/O
- Network I/O, connection pool sizes
- Container restart count

**Application Metrics**:
- Request rate (requests/second)
- Error rate (errors/total requests)
- Latency percentiles (p50, p95, p99)
- Business metrics (payment methods created, transactions completed)

**Custom Metrics**:
```python
payment_method_created_total = Counter(
    'payment_method_created_total',
    'Total payment methods created',
    ['type', 'status']
)

payment_processing_duration_seconds = Histogram(
    'payment_processing_duration_seconds',
    'Time spent processing payment',
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0]
)
```

### Distributed Tracing

**Framework**: [e.g., OpenTelemetry with Jaeger]

**Trace Spans**:
- HTTP request handling
- Database queries
- External API calls
- Background jobs

**Correlation**:
- Generate `trace_id` at API gateway
- Propagate via headers (W3C Trace Context)
- Include in all logs for correlation

### Dashboards

**Dashboard 1: Service Health**
- Request rate, error rate, latency
- Active connections, queue depth
- CPU, memory, pod count

**Dashboard 2: Business Metrics**
- Payment methods created (by type)
- Transaction volume, success rate
- Revenue metrics

**Dashboard 3: Errors**
- Error rate by endpoint
- Top error types
- Error logs in real-time

### Alerts

| Alert | Condition | Severity | Notification | Action |
|-------|-----------|----------|--------------|--------|
| Service Down | Health check failing for 2 min | Critical | PagerDuty | Page on-call, auto-restart |
| High Error Rate | > 5% errors in 5 min | Critical | PagerDuty | Page on-call |
| High Latency | p95 > 500ms for 5 min | Warning | Slack | Investigate |
| External API Failure | Stripe API error rate > 10% | Warning | Slack | Check Stripe status |

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|--------|-----------|------------|-------|
| **Stripe API downtime** | High | Low | Implement retry logic with exponential backoff, queue failed requests, monitor Stripe status page | Backend Lead |
| **Database performance degradation** | High | Medium | Add indexes, implement caching, set up read replicas, monitor slow queries | DBA |
| **Security vulnerability in dependency** | High | Medium | Automated dependency scanning, subscribe to security advisories, rapid patching process | Security |
| **Insufficient test coverage** | Medium | Medium | Enforce coverage gates in CI, code review focus on tests | QA Lead |
| **API rate limit exceeded** | Medium | Low | Implement client-side rate limiting, use connection pooling, cache aggressively | Backend Lead |
| **Scalability bottleneck** | Medium | Low | Load test early, horizontal scaling plan, identify single points of failure | DevOps |

**Risk Review Cadence**: Weekly during implementation, monthly post-launch

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Goals**:
- Set up infrastructure
- Implement core data models
- Establish testing framework

**Deliverables**:
- [ ] Database schema created and migrated
- [ ] Repository layer implemented and tested
- [ ] API authentication implemented
- [ ] CI/CD pipeline configured
- [ ] Monitoring infrastructure set up

**Dependencies**: None

---

### Phase 2: Core Functionality (Week 3-4)

**Goals**:
- Implement P0 requirements
- Integrate with external services

**Deliverables**:
- [ ] Payment method CRUD APIs
- [ ] Stripe integration
- [ ] Transaction processing
- [ ] Error handling
- [ ] Unit + integration tests > 80% coverage

**Dependencies**: Phase 1 complete

---

### Phase 3: Polish & Testing (Week 5-6)

**Goals**:
- P1 requirements
- Performance optimization
- Security hardening

**Deliverables**:
- [ ] E2E tests for critical journeys
- [ ] Performance tests passing
- [ ] Security review completed
- [ ] Documentation complete
- [ ] Staging environment validated

**Dependencies**: Phase 2 complete

---

### Phase 4: Launch (Week 7)

**Goals**:
- Production deployment
- Monitoring validation
- Gradual rollout

**Deliverables**:
- [ ] Feature flag deployed
- [ ] Gradual rollout to 5% → 25% → 50% → 100%
- [ ] Monitoring dashboards validated
- [ ] Runbook created
- [ ] Team training completed

**Dependencies**: Phase 3 complete

---

## Rollback Plan

**Triggers for Rollback**:
- Error rate > 5%
- p95 latency > 2x baseline
- Data corruption detected
- Security incident

**Rollback Procedure**:
1. Disable feature flag (immediate, < 1 min)
2. If database migration: Revert migration (< 5 min)
3. If code deployment: Rollback to previous version (< 10 min)
4. Verify rollback successful: Check metrics, run smoke tests
5. Post-mortem: Document what went wrong, how to prevent

**Testing Rollback**:
- [ ] Practice rollback in staging
- [ ] Document steps clearly
- [ ] Assign roles (who presses the button)

---

## Documentation

### Developer Documentation

- [ ] API reference (auto-generated from OpenAPI spec)
- [ ] Architecture diagrams (C4 model)
- [ ] Database schema (auto-generated from migrations)
- [ ] Local development setup guide
- [ ] Testing guide

### Operational Documentation

- [ ] Runbook for common incidents
- [ ] Deployment guide
- [ ] Rollback guide
- [ ] Monitoring dashboard guide
- [ ] Alert response guide

### User Documentation

- [ ] Feature guide for end users
- [ ] API documentation for integrators
- [ ] FAQ
- [ ] Troubleshooting guide

---

## Sign-off

Plan approved by:
- [ ] Tech Lead: [Name] - [Date]
- [ ] Product Manager: [Name] - [Date]
- [ ] Security: [Name] - [Date]
- [ ] DevOps: [Name] - [Date]

**Approved Date**: [YYYY-MM-DD]

---

## Appendices

### Appendix A: Technology Research

[Detailed research notes on technology choices]

### Appendix B: API Specifications

[Full OpenAPI/Swagger specifications]

### Appendix C: Database Migrations

[SQL migration scripts]

### Appendix D: Configuration

[Environment variable reference, configuration templates]

# Data Model: Phase IV - Local Kubernetes Deployment

**Feature**: 001-k8s-minikube-deployment
**Date**: 2025-12-24
**Status**: Complete

## Overview

Phase IV is infrastructure-focused and introduces **NO new data entities**. All data entities (User, Task, ChatSession) remain from Phase III unchanged per constitutional requirement IV (Backward Compatibility) and FR-027 (Database schema and data model MUST remain unchanged from Phase III).

This document serves as confirmation that Phase IV deployment does not alter the Phase III data model.

---

## Phase III Data Entities (Preserved)

### Entity: User

**Purpose**: Represents authenticated users of the Todo application

**Attributes** (from Phase III):
- `id` (UUID, Primary Key): Unique identifier
- `email` (String, Unique, Not Null): User email address
- `password_hash` (String, Not Null): Hashed password (Better Auth)
- `name` (String, Nullable): Display name
- `created_at` (Timestamp, Not Null): Account creation timestamp
- `updated_at` (Timestamp, Not Null): Last update timestamp

**Relationships**:
- One-to-Many with Task (user owns multiple tasks)
- One-to-Many with ChatSession (user has multiple chat sessions)

**Phase IV Impact**: None - entity unchanged

---

### Entity: Task

**Purpose**: Represents todo items created and managed by users

**Attributes** (from Phase III):
- `id` (UUID, Primary Key): Unique identifier
- `user_id` (UUID, Foreign Key → User.id, Not Null): Task owner
- `title` (String, Not Null): Task description
- `completed` (Boolean, Default False): Completion status
- `priority` (Enum: Low/Medium/High, Default Medium): Task priority
- `due_date` (Timestamp, Nullable): Optional due date
- `created_at` (Timestamp, Not Null): Task creation timestamp
- `updated_at` (Timestamp, Not Null): Last update timestamp

**Relationships**:
- Many-to-One with User (task belongs to one user)

**Phase IV Impact**: None - entity unchanged

---

### Entity: ChatSession

**Purpose**: Represents conversational sessions between user and AI chatbot

**Attributes** (from Phase III):
- `id` (UUID, Primary Key): Unique identifier
- `user_id` (UUID, Foreign Key → User.id, Not Null): Session owner
- `messages` (JSONB, Not Null): Array of chat messages (user + assistant)
- `context` (JSONB, Nullable): Session context and metadata
- `created_at` (Timestamp, Not Null): Session start timestamp
- `updated_at` (Timestamp, Not Null): Last message timestamp

**Relationships**:
- Many-to-One with User (session belongs to one user)

**Phase IV Impact**: None - entity unchanged

---

## Data Persistence

### Database: Neon PostgreSQL

**Connection**: External service (Phase III instance)
- **URL**: Injected at runtime via Kubernetes Secret (FR-018)
- **Access**: Backend pods connect via public internet
- **Schema**: Phase III schema unchanged (FR-027)

**Phase IV Changes**:
- ✅ Connection method: Environment variable injection (was: hardcoded or .env file)
- ✅ Retry logic: Exponential backoff added (FR-033)
- ✅ Failure handling: HTTP 503 on unavailable database (FR-034)
- ❌ Schema changes: None
- ❌ Data migrations: None
- ❌ New entities: None

---

## State Management

### Stateless Design (Constitutional Requirement V)

**Phase IV Enforcement**:
- ✅ No in-memory session storage
- ✅ All session state persisted to Neon PostgreSQL
- ✅ Pod restarts do not cause data loss (FR-028, SC-004)
- ✅ Multiple replicas can run concurrently without conflicts (SC-003)

**Validation**:
- User Story P2: System Survives Pod Restarts
- User Story P3: Backend Scales to Multiple Replicas
- Acceptance Scenario: Pod deletion → automatic recreation → data preserved

---

## Data Flow (Infrastructure View)

```
┌──────────────────┐
│   Frontend Pod   │ (Next.js UI)
│   (Stateless)    │
└────────┬─────────┘
         │ HTTP
         ↓
┌──────────────────┐
│  Backend Pod(s)  │ (FastAPI + OpenAI Agents + MCP)
│   (Stateless)    │
└────────┬─────────┘
         │ PostgreSQL Protocol
         │ (with retry + backoff)
         ↓
┌──────────────────┐
│ Neon PostgreSQL  │ (External, managed)
│   (Stateful)     │ - Users
└──────────────────┘ - Tasks
                     - ChatSessions
```

**Key Characteristics**:
- Frontend: Stateless (no local storage, session cookies only)
- Backend: Stateless (no in-memory state, database-backed)
- Database: Stateful (single source of truth)

---

## Concurrency and Consistency

### Multi-Replica Safety

**Phase III Design** (carried forward to Phase IV):
- Database transactions ensure ACID properties
- Optimistic locking via `updated_at` timestamps
- No file-based locks or in-memory coordination

**Phase IV Validation**:
- User Story P3 tests concurrent requests across multiple backend replicas
- No data conflicts expected (database handles serialization)
- Acceptance Scenario: "Given multiple replicas are handling requests, When chatbot queries database, Then no data conflicts or race conditions occur"

---

## No Schema Migrations Required

Phase IV introduces zero schema changes:

❌ **No new tables**
❌ **No new columns**
❌ **No altered indexes**
❌ **No constraint changes**
❌ **No data type modifications**

**Rationale**:
- Phase IV focuses solely on deployment infrastructure
- Application behavior frozen (Constitutional Requirement IV)
- Database schema unchanged (FR-027)

---

## Data Model Summary

| Entity | Status | Phase III Attributes | Phase IV Changes |
|--------|--------|---------------------|------------------|
| User | ✅ Unchanged | id, email, password_hash, name, created_at, updated_at | None |
| Task | ✅ Unchanged | id, user_id, title, completed, priority, due_date, created_at, updated_at | None |
| ChatSession | ✅ Unchanged | id, user_id, messages, context, created_at, updated_at | None |

**Database**: Neon PostgreSQL (external, Phase III instance)
**Schema Version**: Phase III (no migrations)
**Data Persistence**: External database only (no local storage)
**Concurrency Model**: Database-enforced ACID transactions

---

## Validation Checklist

- [x] ✅ No new entities introduced
- [x] ✅ No schema changes from Phase III
- [x] ✅ No data migrations required
- [x] ✅ Stateless design enforced (no in-memory state)
- [x] ✅ Database connection via Kubernetes Secrets (FR-018)
- [x] ✅ Retry logic implemented (FR-033)
- [x] ✅ Multi-replica safety validated (SC-003)
- [x] ✅ Pod restart data preservation validated (SC-004)

**Data Model Status**: ✅ COMPLETE - Phase III data model preserved unchanged

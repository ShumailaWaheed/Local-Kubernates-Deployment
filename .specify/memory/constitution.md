# Hackathon II – Todo Project Constitution
## Phase IV: Local Kubernetes Deployment

<!--
SYNC IMPACT REPORT
==================
Version: [NEW] → 1.0.0
Rationale: Initial constitution ratification for Phase IV Kubernetes deployment
  - MAJOR version (1.x.x): First formal constitution establishment
  - This constitution defines immutable principles for cloud-native deployment

Modified Principles:
  - All principles are NEW (first ratification)

Added Sections:
  - Core Principles (11 principles)
  - Phase Scope Boundaries
  - Phase IV Hard Requirements
  - AI-Assisted DevOps (AIOps) Enforcement
  - Architecture Invariants
  - Kubernetes Design Rules
  - Configuration & Secrets Management
  - Explicit Exclusions
  - Compliance & Acceptance Criteria
  - Constitutional Hierarchy
  - Governance

Removed Sections:
  - None (initial version)

Templates Status:
  ✅ spec-template.md - Verified: No constitution-specific conflicts
  ✅ plan-template.md - Verified: Constitution Check section present and compatible
  ✅ tasks-template.md - Verified: Task organization aligns with principles
  ⚠️  No command files found - No updates needed

Follow-up TODOs:
  - None: All placeholders filled with concrete values from user input
==================
-->

## Core Principles

### I. Spec-First Enforcement (NON-NEGOTIABLE)

No code, configuration, container, Helm chart, or Kubernetes resource may be created without an approved specification.

**Workflow order is immutable**: Specify → Plan → Tasks → Implement

**Rationale**: Prevents scope creep, ensures architectural review before implementation, maintains single source of truth for all decisions.

---

### II. No Manual Coding (NON-NEGOTIABLE)

All implementation artifacts (code, Dockerfiles, Helm charts, YAMLs) MUST be generated or refined via **Claude Code** or approved AI tools.

Humans may edit specifications only.

**Rationale**: Ensures consistency, leverages AI-assisted development best practices, maintains reproducibility and audit trail.

---

### III. Single Source of Truth (NON-NEGOTIABLE)

Specifications override all generated output.

If implementation conflicts with specs, the implementation MUST be regenerated.

**Rationale**: Prevents documentation drift, ensures specifications remain authoritative, enables reliable rollback and versioning.

---

### IV. Backward Compatibility (NON-NEGOTIABLE)

Phase IV MUST NOT change or break Phase II or Phase III behavior.

APIs, chatbot responses, and task semantics MUST remain identical.

**Rationale**: Validates infrastructure changes don't alter application behavior, protects existing user workflows, enables safe deployment.

---

### V. Stateless Design (NON-NEGOTIABLE)

No runtime state may exist in application memory.

All state MUST be persisted in external systems (database or services).

**Rationale**: Enables horizontal scaling, supports multiple replicas, ensures pod restart safety, critical for Kubernetes deployments.

---

### VI. Container Runtime Mandate (NON-NEGOTIABLE)

**Docker Desktop is required** for Phase IV.

All containers MUST be built and run via Docker Desktop.

**Rationale**: Standardizes container runtime, ensures Windows compatibility, provides consistent development environment.

---

### VII. Kubernetes Target Lock (NON-NEGOTIABLE)

**Minikube is the ONLY permitted Kubernetes environment** for Phase IV.

kind, k3s, cloud clusters, or managed services are forbidden.

**Rationale**: Simplifies local development, ensures reproducible environment, focuses validation on core Kubernetes concepts.

---

### VIII. Helm-Only Deployment (NON-NEGOTIABLE)

All Kubernetes resources MUST be deployed via Helm charts.

Raw `kubectl apply` YAML deployments are not allowed.

**Rationale**: Enforces templating, enables environment-specific configuration, supports versioned deployments and rollbacks.

---

### IX. AI-Assisted DevOps (AIOps) Priority

Docker AI (Gordon) is first preference for Docker operations.

Helm charts MUST be created or refined using **kubectl-ai** and/or **kagent**.

Manual operations are last-resort only.

**Rationale**: Leverages AI-assisted operations, reduces manual errors, demonstrates AI-first DevOps practices for hackathon judging.

---

### X. Architecture Invariants (FROZEN)

The following decisions are frozen and MUST NOT change in Phase IV:
- FastAPI backend
- OpenAI Agents SDK for reasoning
- MCP SDK as the agent-to-tool interface
- Neon PostgreSQL as the primary datastore
- Stateless request–response lifecycle

Phase IV may only **wrap**, not replace, these components.

**Rationale**: Phase IV validates infrastructure only, not architecture changes. Maintains continuity with Phase III implementation.

---

### XI. Secrets Management (SECURITY)

No secrets may be committed to GitHub.

API keys and DB URLs MUST be injected via:
- Environment variables
- Kubernetes Secrets

Helm `values.yaml` MUST separate environment-specific configuration.

**Rationale**: Prevents credential exposure, follows security best practices, enables secure CI/CD pipelines.

---

## Phase Scope Boundaries

### Phase I – Console Todo
- Python-only
- In-memory storage
- No web, no AI, no containers, no deployment
- Purpose: validate domain logic only

### Phase II – Full-Stack Web App
- Next.js frontend
- FastAPI backend
- Neon PostgreSQL
- JWT authentication (Better Auth)
- REST APIs
- Deployment may be local or Vercel-based (non-cloud-native)

### Phase III – AI Todo Chatbot
- Natural language task management
- OpenAI ChatKit frontend
- OpenAI Agents SDK for reasoning
- Official MCP SDK for tool exposure
- Stateless chat endpoints
- Database-backed persistence

**Phase III defines final user-facing behavior.**

### Phase IV – Local Kubernetes Deployment

Phase IV introduces **NO new features**.

It adds:
- Containerization
- Kubernetes orchestration
- Helm-based deployment
- AI-assisted DevOps practices

**Purpose**: Prove production readiness through infrastructure, not to add features or alter application behavior.

---

## Phase IV Hard Requirements

### 1. Application Code Freeze
Phase III application logic, agents, and MCP tools MUST NOT be modified.

Any deployment-driven change MUST be justified in specs.

### 2. Containerization Rules
- Frontend and backend MUST run in separate containers
- Images MUST be reproducible and environment-agnostic

### 3. Kubernetes Design Rules

**Single Responsibility Containers**:
- Frontend container: UI only
- Backend container: API + Agents + MCP

**Service Isolation**:
- Frontend may be externally exposed
- Backend MUST use **ClusterIP only**

**Replica Safety**:
- Backend MUST support multiple replicas
- No shared filesystem or local state

**Failure Recovery**:
- Pod restarts MUST NOT cause data loss
- System MUST recover automatically

### 4. Evidence Requirement
Usage of Docker AI (Gordon), kubectl-ai, or kagent MUST be documented via logs, commands, or screenshots.

---

## AI-Assisted DevOps (AIOps) Enforcement

### Docker AI (Gordon) Hierarchy
1. **First preference**: Docker AI (Gordon)
2. **If unavailable**: Claude Code–generated Docker instructions
3. **Manual Docker commands**: Last-resort only

### Helm Chart Generation
Helm charts MUST be created or refined using **kubectl-ai** and/or **kagent**.

Manual Helm authoring is not permitted.

### Operational Debugging
Pod failures, scaling, and configuration issues MUST be investigated using AI DevOps tools first.

---

## Configuration & Secrets Management

- No secrets may be committed to GitHub
- API keys and DB URLs MUST be injected via:
  - Environment variables
  - Kubernetes Secrets
- Helm `values.yaml` MUST separate environment-specific configuration

---

## Explicit Exclusions (NOT ALLOWED IN PHASE IV)

Phase IV explicitly excludes:
- No Kafka
- No Dapr
- No cloud provider deployment
- No new chatbot capabilities
- No performance optimization beyond stability
- No feature expansion of any kind

These are reserved for Phase V.

---

## Compliance & Acceptance Criteria

Phase IV is complete ONLY if:

1. ✅ Frontend runs inside Minikube
2. ✅ Backend runs inside Minikube
3. ✅ All resources are deployed via Helm
4. ✅ Chatbot behavior matches Phase III exactly
5. ✅ System survives pod restarts
6. ✅ Docker Desktop is used
7. ✅ AI DevOps tools were used and documented
8. ✅ No manual coding occurred outside specs

---

## Constitutional Hierarchy

In case of conflict, precedence is:

1. **This Constitution** (highest authority)
2. **Phase IV Specification** (feature-level requirements)
3. **Phase IV Plan** (technical design decisions)
4. **Phase IV Tasks** (implementation details)

Lower-level documents MUST NOT contradict higher-level documents.

---

## Governance

### Amendment Process

1. **Proposal**: Amendments MUST be documented with rationale and impact analysis
2. **Review**: Constitutional changes require explicit approval before implementation
3. **Migration**: Breaking changes MUST include migration plan for existing artifacts
4. **Version Increment**: Follow semantic versioning (MAJOR.MINOR.PATCH)

### Compliance Verification

- All PRs and reviews MUST verify constitutional compliance
- Violations MUST be justified in Complexity Tracking (plan.md)
- Unjustified complexity is grounds for rejection

### Constitutional Authority

This constitution supersedes all other practices, conventions, and informal agreements.

When specifications, plans, or tasks conflict with constitutional principles, the constitution takes precedence.

---

**Version**: 1.0.0 | **Ratified**: 2025-12-24 | **Last Amended**: 2025-12-24

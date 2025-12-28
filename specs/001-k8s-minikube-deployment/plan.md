# Implementation Plan: Phase IV - Local Kubernetes Deployment

**Branch**: `001-k8s-minikube-deployment` | **Date**: 2025-12-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-k8s-minikube-deployment/spec.md`

## Summary

Phase IV deploys the Phase III Todo AI Chatbot to local Kubernetes (Minikube) using Docker Desktop and Helm charts. This is an infrastructure-only phase with zero application behavior changes. The deployment must validate stateless architecture, pod resilience, horizontal scalability, and secrets management while leveraging AI-assisted DevOps tooling (Docker AI, kubectl-ai, kagent) for all deployment operations.

## Technical Context

**Language/Version**:
- Frontend: Next.js (existing Phase III version)
- Backend: Python 3.11+ with FastAPI (existing Phase III version)

**Primary Dependencies**:
- Docker Desktop (Windows) - container runtime
- Minikube - local Kubernetes distribution
- Helm 3.x - Kubernetes package manager
- kubectl - Kubernetes CLI
- AI DevOps tools: Docker AI (Gordon), kubectl-ai, kagent

**Storage**:
- Neon PostgreSQL (external, Phase III instance - unchanged)
- No local filesystem storage (stateless design)

**Testing**:
- Manual validation via kubectl commands
- Chatbot functionality testing (Phase III acceptance tests)
- Pod restart and recovery testing
- Scalability testing (2+ replicas)

**Target Platform**:
- Local Kubernetes (Minikube on Windows with Docker Desktop)
- Kubernetes version: 1.28+ (Minikube default)

**Project Type**: Web application (frontend + backend microservices)

**Performance Goals**:
- Frontend UI load: <5 seconds
- Pod restart recovery: <30 seconds
- No performance regression from Phase III

**Constraints**:
- No application code changes (Phase III frozen)
- Docker Desktop mandatory (no alternatives)
- Minikube only (no kind, k3s, cloud)
- Helm required (no raw kubectl YAML)
- AI tooling usage: 80%+ of deployment tasks
- Zero hardcoded secrets

**Scale/Scope**:
- 2 containers (frontend, backend)
- 2 Helm charts
- Minimum 2 backend replicas for scalability validation
- 1 hour stable operation required

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Constitutional Compliance

✅ **I. Spec-First Enforcement**: Specification complete and approved before plan creation
✅ **II. No Manual Coding**: AI-assisted DevOps tools mandated (FR-036, FR-037, FR-038, FR-039)
✅ **III. Single Source of Truth**: Specification is authoritative source
✅ **IV. Backward Compatibility**: 100% Phase III functionality preservation (FR-024, FR-025, FR-026)
✅ **V. Stateless Design**: Pod restart validation required (FR-028, User Story P2)
✅ **VI. Container Runtime Mandate**: Docker Desktop required (FR-029)
✅ **VII. Kubernetes Target Lock**: Minikube only (FR-030)
✅ **VIII. Helm-Only Deployment**: Helm charts mandatory (FR-013, FR-014, FR-015)
✅ **IX. AI-Assisted DevOps Priority**: Docker AI, kubectl-ai, kagent usage required
✅ **X. Architecture Invariants**: No changes to FastAPI, OpenAI Agents SDK, MCP, Neon PostgreSQL
✅ **XI. Secrets Management**: Runtime injection only (FR-018, FR-019, FR-020, FR-021, FR-022, FR-023)

**Gate Status**: ✅ PASSED - All constitutional principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/001-k8s-minikube-deployment/
├── spec.md                    # Feature specification (complete)
├── plan.md                    # This file (/sp.plan command output)
├── research.md                # Phase 0 output (Docker/Helm/Minikube best practices)
├── data-model.md              # Phase 1 output (No new entities - Phase III preserved)
├── quickstart.md              # Phase 1 output (Deployment steps)
├── contracts/                 # Phase 1 output (Kubernetes resource specs)
│   ├── backend-deployment.yaml    # Backend Deployment spec
│   ├── backend-service.yaml       # Backend ClusterIP Service spec
│   ├── frontend-deployment.yaml   # Frontend Deployment spec
│   └── frontend-service.yaml      # Frontend NodePort/LoadBalancer Service spec
├── checklists/
│   └── requirements.md        # Specification quality checklist (complete)
└── tasks.md                   # Phase 2 output (/sp.tasks command - NOT created by /sp.plan)
```

### Source Code (repository root)

**Note**: Phase IV is deployment-focused. Application source code remains in Phase III structure (unchanged).

```text
# Phase III Application Structure (READ-ONLY for Phase IV)
frontend/                      # Next.js application
backend/                       # FastAPI + OpenAI Agents + MCP

# Phase IV Deployment Artifacts (NEW)
docker/
├── frontend/
│   └── Dockerfile             # Frontend container image definition
└── backend/
    └── Dockerfile             # Backend container image definition

helm/
├── frontend-chart/
│   ├── Chart.yaml             # Frontend Helm chart metadata
│   ├── values.yaml            # Frontend configuration values
│   └── templates/
│       ├── deployment.yaml    # Frontend Deployment template
│       └── service.yaml       # Frontend Service template
└── backend-chart/
    ├── Chart.yaml             # Backend Helm chart metadata
    ├── values.yaml            # Backend configuration values
    └── templates/
        ├── deployment.yaml    # Backend Deployment template
        └── service.yaml       # Backend Service template

docs/
└── phase-iv/
    ├── deployment-guide.md    # Step-by-step deployment instructions
    ├── aiops-evidence.md      # AI DevOps tool usage documentation
    └── validation-results.md  # Acceptance criteria validation results
```

**Structure Decision**: Web application structure with separate deployment artifacts directory. Application code remains unchanged per constitutional requirement IV.

## Complexity Tracking

**No violations**: This phase introduces infrastructure deployment only. All constitutional principles are satisfied without exceptions.

## Implementation Plan

---

## 1. Plan Objective

This plan defines the **exact execution steps** required to implement Phase IV deployment for the Todo AI Chatbot using Docker Desktop, Minikube, Helm, and AI-assisted DevOps tools.

The plan translates the Phase IV specification into an ordered, non-ambiguous workflow with clear entry/exit criteria for each phase.

---

## 2. Plan Principles

- Execute steps **exactly in order**
- Do not skip phases
- Do not improvise
- Use AI DevOps tools as first resort (Docker AI, kubectl-ai, kagent)
- Document all AI tool usage
- Validate constitutional compliance at each phase
- No application code modifications

---

## 3. Implementation Phases

### Phase 4.0 – Prerequisites Validation

**Goal:** Verify environment readiness.

**Steps:**
1. Confirm Docker Desktop installed and running
2. Confirm Minikube installed (run `minikube version`)
3. Confirm Helm 3.x installed (run `helm version`)
4. Confirm kubectl installed (run `kubectl version --client`)
5. Verify Phase III application is functional
6. Check availability of AI DevOps tools (Docker AI, kubectl-ai, kagent)

**Exit Criteria:**
- All tools accessible
- Phase III chatbot confirmed working
- AI tools availability documented

---

### Phase 4.1 – Environment Setup

**Goal:** Prepare deployment environment.

**Steps:**
1. Start Docker Desktop
2. Allocate resources to Docker Desktop (minimum 8GB RAM, 4 CPU cores)
3. Start Minikube cluster: `minikube start --driver=docker`
4. Verify Minikube cluster health: `kubectl cluster-info`
5. Create Kubernetes namespace (if needed): `kubectl create namespace todo-app`

**Exit Criteria:**
- Minikube cluster running
- kubectl can communicate with cluster
- Namespace created

---

### Phase 4.2 – Secrets Preparation

**Goal:** Prepare secrets for deployment (WITHOUT committing to Git).

**Steps:**
1. Create Kubernetes Secret for database connection:
   ```bash
   kubectl create secret generic db-secret \
     --from-literal=DATABASE_URL=<neon-postgres-url> \
     --namespace=todo-app
   ```
2. Create Kubernetes Secret for OpenAI API key:
   ```bash
   kubectl create secret generic openai-secret \
     --from-literal=OPENAI_API_KEY=<api-key> \
     --namespace=todo-app
   ```
3. Verify secrets created: `kubectl get secrets -n todo-app`
4. Document secret names in values.yaml (reference only, not values)

**Exit Criteria:**
- Secrets created in Kubernetes
- No secrets committed to Git
- Secret references documented

---

### Phase 4.3 – Frontend Containerization

**Goal:** Build frontend Docker image using AI-assisted tooling.

**Steps:**
1. **Use Docker AI (Gordon) if available**, fallback to Claude Code
2. Generate Dockerfile for Next.js frontend (multi-stage build recommended)
3. Build frontend image: `docker build -t todo-frontend:latest ./frontend`
4. Test image locally: `docker run -p 3000:3000 todo-frontend:latest`
5. Verify frontend loads at http://localhost:3000
6. Load image into Minikube: `minikube image load todo-frontend:latest`
7. Document Docker AI usage (commands, outputs)

**Exit Criteria:**
- Frontend Dockerfile created
- Frontend image built and loaded into Minikube
- AI tool usage documented

---

### Phase 4.4 – Backend Containerization

**Goal:** Build backend Docker image using AI-assisted tooling.

**Steps:**
1. **Use Docker AI (Gordon) if available**, fallback to Claude Code
2. Generate Dockerfile for FastAPI backend (include health check endpoint)
3. Implement startup validation for required secrets (FR-023)
4. Implement database retry logic with exponential backoff (FR-033)
5. Implement HTTP 503 response for unavailable database (FR-034)
6. Implement health check failure marking (FR-035)
7. Build backend image: `docker build -t todo-backend:latest ./backend`
8. Test image locally: `docker run -p 8000:8000 todo-backend:latest`
9. Load image into Minikube: `minikube image load todo-backend:latest`
10. Document Docker AI usage (commands, outputs)

**Exit Criteria:**
- Backend Dockerfile created with failure handling
- Backend image built and loaded into Minikube
- AI tool usage documented

---

### Phase 4.5 – Helm Chart Generation (Backend)

**Goal:** Create backend Helm chart using AI-assisted tooling.

**Steps:**
1. **Use kubectl-ai and/or kagent** for Helm chart generation
2. Create backend Helm chart structure:
   - Chart.yaml (metadata)
   - values.yaml (configurable parameters)
   - templates/deployment.yaml (Deployment resource)
   - templates/service.yaml (ClusterIP Service)
3. Configure Deployment template:
   - Image: todo-backend:latest
   - Replicas: configurable via values.yaml (default 2)
   - Environment variables from Secrets (FR-018, FR-019)
   - Liveness and readiness probes
   - Resource requests/limits
4. Configure Service template:
   - Type: ClusterIP (FR-010)
   - Port: 8000
5. Generate values.yaml with environment separation
6. Document AI tool usage

**Exit Criteria:**
- Backend Helm chart created
- No hardcoded secrets
- AI tool usage documented

---

### Phase 4.6 – Helm Chart Generation (Frontend)

**Goal:** Create frontend Helm chart using AI-assisted tooling.

**Steps:**
1. **Use kubectl-ai and/or kagent** for Helm chart generation
2. Create frontend Helm chart structure:
   - Chart.yaml (metadata)
   - values.yaml (configurable parameters)
   - templates/deployment.yaml (Deployment resource)
   - templates/service.yaml (NodePort or LoadBalancer Service)
3. Configure Deployment template:
   - Image: todo-frontend:latest
   - Replicas: configurable via values.yaml (default 1)
   - Environment variable for backend service URL
   - Liveness and readiness probes
   - Resource requests/limits
4. Configure Service template:
   - Type: NodePort or LoadBalancer (FR-009)
   - Port: 3000
5. Generate values.yaml with env separation
6. Document AI tool usage

**Exit Criteria:**
- Frontend Helm chart created
- No hardcoded secrets
- AI tool usage documented

---

### Phase 4.7 – Kubernetes Deployment via Helm

**Goal:** Deploy system to Minikube.

**Steps:**
1. Install backend Helm chart:
   ```bash
   helm install todo-backend ./helm/backend-chart \
     --namespace=todo-app \
     --values=./helm/backend-chart/values.yaml
   ```
2. Verify backend pods running: `kubectl get pods -n todo-app`
3. Verify backend service created: `kubectl get svc -n todo-app`
4. Install frontend Helm chart:
   ```bash
   helm install todo-frontend ./helm/frontend-chart \
     --namespace=todo-app \
     --values=./helm/frontend-chart/values.yaml
   ```
5. Verify frontend pods running: `kubectl get pods -n todo-app`
6. Verify frontend service created: `kubectl get svc -n todo-app`
7. Get frontend service URL: `minikube service todo-frontend --namespace=todo-app --url`
8. Confirm frontend-to-backend connectivity

**Exit Criteria:**
- All pods running (STATUS: Running)
- Services reachable
- Frontend can communicate with backend

---

### Phase 4.8 – Stability & Recovery Testing

**Goal:** Validate resilience and stateless design.

**Steps:**
1. Identify backend pod name: `kubectl get pods -n todo-app`
2. Delete backend pod manually: `kubectl delete pod <backend-pod-name> -n todo-app`
3. Observe automatic recreation: `kubectl get pods -n todo-app --watch`
4. Verify pod recreated within 30 seconds (SC-004)
5. Test chatbot functionality (verify no data loss)
6. Delete frontend pod manually: `kubectl delete pod <frontend-pod-name> -n todo-app`
7. Observe automatic recreation
8. Verify frontend reconnects without errors
9. Test chatbot end-to-end (add/update/delete/list tasks via natural language)

**Exit Criteria:**
- System recovers automatically (FR-032)
- Pod restart completes within 30 seconds
- No data loss (FR-028)
- Chatbot functionality identical to Phase III (SC-005)

---

### Phase 4.9 – Scalability Testing

**Goal:** Validate horizontal scalability.

**Steps:**
1. Scale backend to 3 replicas:
   ```bash
   helm upgrade todo-backend ./helm/backend-chart \
     --set replicaCount=3 \
     --namespace=todo-app
   ```
2. Verify 3 backend pods running: `kubectl get pods -n todo-app`
3. Test chatbot with multiple concurrent users (simulate load)
4. Verify load distribution across replicas
5. Scale backend back to 2 replicas
6. Verify no user-facing disruption during scaling

**Exit Criteria:**
- Backend supports 2+ replicas (SC-003)
- No data conflicts or race conditions
- Load distributed across replicas

---

### Phase 4.10 – AI-Assisted Operations Validation

**Goal:** Prove AIOps usage and collect evidence.

**Steps:**
1. Use kubectl-ai to inspect pod status:
   ```bash
   kubectl-ai "Show me the health of all pods in todo-app namespace"
   ```
2. Use kagent to analyze deployment health:
   ```bash
   kagent analyze deployment todo-backend --namespace=todo-app
   ```
3. Record commands, outputs, and screenshots
4. Document AI tool responses in `docs/phase-iv/aiops-evidence.md`
5. Calculate AI tooling usage percentage (target: 80%+)

**Exit Criteria:**
- kubectl-ai commands executed and documented
- kagent analysis completed and documented
- Evidence collected with screenshots
- AI usage meets 80% threshold (SC-008)

---

### Phase 4.11 – Final Acceptance Validation

**Goal:** Confirm Phase IV success against all acceptance criteria.

**Steps:**
1. Access chatbot UI via Minikube service URL
2. Execute sample todo commands:
   - "Add task: Buy groceries"
   - "List all tasks"
   - "Update task 1 to: Buy groceries and cook dinner"
   - "Delete task 1"
3. Verify all Phase III functionality works identically
4. Run through specification acceptance scenarios (User Stories P1, P2, P3)
5. Verify all success criteria (SC-001 through SC-011)
6. Check constitution compliance checklist
7. Document validation results in `docs/phase-iv/validation-results.md`

**Exit Criteria:**
- All acceptance criteria satisfied (SC-001 through SC-011)
- All user stories validated (P1, P2, P3)
- Constitutional compliance confirmed
- Phase IV complete

---

## 4. Deliverables

Phase IV must produce:

1. **Dockerfiles**:
   - `docker/frontend/Dockerfile` (Frontend containerization)
   - `docker/backend/Dockerfile` (Backend containerization with failure handling)

2. **Docker Images**:
   - `todo-frontend:latest` (loaded into Minikube)
   - `todo-backend:latest` (loaded into Minikube)

3. **Helm Charts**:
   - `helm/frontend-chart/` (Chart.yaml, values.yaml, templates/)
   - `helm/backend-chart/` (Chart.yaml, values.yaml, templates/)

4. **Documentation**:
   - `docs/phase-iv/deployment-guide.md` (Step-by-step instructions)
   - `docs/phase-iv/aiops-evidence.md` (AI DevOps tool usage evidence)
   - `docs/phase-iv/validation-results.md` (Acceptance criteria validation)

5. **Kubernetes Resources** (deployed via Helm):
   - Backend Deployment (2+ replicas)
   - Backend ClusterIP Service
   - Frontend Deployment
   - Frontend NodePort/LoadBalancer Service
   - Kubernetes Secrets (db-secret, openai-secret)

---

## 5. Risk Mitigation

| Risk | Mitigation Strategy |
|------|---------------------|
| Docker AI (Gordon) unavailable | Fallback to Claude Code for Dockerfile generation |
| kubectl-ai or kagent unavailable | Fallback to Claude Code with manual validation |
| Pod failures during deployment | Debug via kubectl-ai; check logs with `kubectl logs` |
| Database connectivity issues | Verify network access from Minikube to Neon PostgreSQL |
| Secrets misconfiguration | Use kubectl describe/logs to diagnose; update Secrets if needed |
| Resource exhaustion | Increase Docker Desktop resource allocation; monitor with `kubectl top` |
| Helm chart errors | Use `helm lint` and `helm template` for validation before install |
| Configuration errors | Adjust values.yaml only (no hardcoded changes) |

---

## 6. Validation Checklist

Before declaring Phase IV complete, verify:

- [ ] ✅ Frontend UI loads successfully via Minikube service (SC-001)
- [ ] ✅ Chatbot responds within Phase III performance envelope (SC-002)
- [ ] ✅ System supports minimum 2 concurrent backend replicas (SC-003)
- [ ] ✅ Pod restart completes within 30 seconds with zero data loss (SC-004)
- [ ] ✅ 100% of Phase III chatbot features function identically (SC-005)
- [ ] ✅ Helm chart installation succeeds on first attempt (SC-006)
- [ ] ✅ All secrets and configuration externalized (SC-007)
- [ ] ✅ AI DevOps tooling used for minimum 80% of deployment tasks (SC-008)
- [ ] ✅ Complete deployment flow completes within 30 minutes (SC-009)
- [ ] ✅ All Kubernetes resources reach healthy state (SC-010)
- [ ] ✅ System remains stable for minimum 1 hour (SC-011)

---

## 7. Plan Lock

This plan is **LOCKED** per constitutional requirement.

Any deviation requires:
1. Specification update
2. Plan revision
3. Re-approval

**Do not skip phases. Do not improvise. Execute steps exactly in order.**

---

## 8. Next Steps

After plan completion:

1. **Review this plan** for accuracy and completeness
2. **Generate Phase 0 artifacts**: research.md (Docker/Helm/Kubernetes best practices)
3. **Generate Phase 1 artifacts**: data-model.md (no new entities), contracts/ (K8s resource specs), quickstart.md
4. **Run `/sp.tasks`** to generate tasks.md with dependency-ordered implementation tasks

**Command to proceed**: `/sp.tasks`

---

**Plan Status**: ✅ COMPLETE AND LOCKED

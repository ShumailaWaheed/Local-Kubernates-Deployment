---
description: "Task list for Phase IV - Local Kubernetes Deployment"
---

# Tasks: Phase IV - Local Kubernetes Deployment

**Input**: Design documents from `/specs/001-k8s-minikube-deployment/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are NOT requested for Phase IV. This is an infrastructure validation phase using manual testing.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Phase III Application**: `frontend/`, `backend/` at repository root (READ-ONLY)
- **Phase IV Deployment**: `docker/`, `helm/`, `docs/phase-iv/`
- Paths shown below assume repository root as working directory

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Environment validation and directory structure creation

- [ ] T001 Verify Docker Desktop installed and running on Windows
- [ ] T002 [P] Verify Minikube installed (run `minikube version`)
- [ ] T003 [P] Verify Helm 3.x installed (run `helm version`)
- [ ] T004 [P] Verify kubectl installed (run `kubectl version --client`)
- [ ] T005 Verify Phase III application code exists in frontend/ and backend/ directories
- [ ] T006 Create deployment directory structure: docker/, helm/, docs/phase-iv/
- [ ] T007 [P] Create docker/frontend/ and docker/backend/ subdirectories
- [ ] T008 [P] Create helm/frontend-chart/ and helm/backend-chart/ subdirectories
- [ ] T009 Document AI DevOps tool availability (Docker AI, kubectl-ai, kagent) in docs/phase-iv/aiops-evidence.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T010 Start Minikube cluster with Docker driver: `minikube start --driver=docker --cpus=4 --memory=8192 --kubernetes-version=v1.28.0`
- [ ] T011 Verify Minikube cluster running: `kubectl cluster-info`
- [ ] T012 Create Kubernetes namespace: `kubectl create namespace todo-app`
- [ ] T013 Create Kubernetes Secret for database connection in todo-app namespace (manual kubectl create secret)
- [ ] T014 Create Kubernetes Secret for OpenAI API key in todo-app namespace (manual kubectl create secret)
- [ ] T015 Verify secrets created: `kubectl get secrets -n todo-app`
- [ ] T016 Document secret creation commands (WITHOUT values) in docs/phase-iv/deployment-guide.md

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - DevOps Engineer Deploys System (Priority: P1) 🎯 MVP

**Goal**: Successfully deploy Phase III Todo AI Chatbot to Minikube via Helm charts

**Independent Test**: Deploy Helm charts to Minikube and access chatbot UI through exposed service. All Phase III functionality works identically.

### Backend Containerization (US1)

- [ ] T017 [P] [US1] Use Docker AI (Gordon) to generate backend Dockerfile in docker/backend/Dockerfile (or Claude Code if Gordon unavailable)
- [ ] T018 [US1] Implement startup secrets validation in backend code (exit with error if DATABASE_URL or OPENAI_API_KEY missing/invalid per ADR-004)
- [ ] T019 [US1] Implement database connection retry with exponential backoff in backend code (per ADR-003, FR-033)
- [ ] T020 [US1] Implement HTTP 503 response for unavailable database in backend code (per ADR-003, FR-034)
- [ ] T021 [US1] Implement health check endpoints in backend code: /health/live (always 200 OK) and /health/ready (fails when DB unavailable per ADR-003, FR-035)
- [ ] T022 [US1] Build backend Docker image: `docker build -t todo-backend:latest -f docker/backend/Dockerfile backend/`
- [ ] T023 [US1] Test backend image locally: `docker run -p 8000:8000 todo-backend:latest`
- [ ] T024 [US1] Load backend image into Minikube: `minikube image load todo-backend:latest`
- [ ] T025 [US1] Document Docker AI usage for backend in docs/phase-iv/aiops-evidence.md

### Frontend Containerization (US1)

- [ ] T026 [P] [US1] Use Docker AI (Gordon) to generate frontend Dockerfile in docker/frontend/Dockerfile (or Claude Code if Gordon unavailable)
- [ ] T027 [US1] Build frontend Docker image: `docker build -t todo-frontend:latest -f docker/frontend/Dockerfile frontend/`
- [ ] T028 [US1] Test frontend image locally: `docker run -p 3000:3000 todo-frontend:latest`
- [ ] T029 [US1] Load frontend image into Minikube: `minikube image load todo-frontend:latest`
- [ ] T030 [US1] Document Docker AI usage for frontend in docs/phase-iv/aiops-evidence.md

### Backend Helm Chart (US1)

- [ ] T031 [US1] Use kubectl-ai and/or kagent to generate backend Helm chart structure in helm/backend-chart/
- [ ] T032 [US1] Create helm/backend-chart/Chart.yaml with metadata (name: todo-backend, version: 0.1.0, appVersion: "1.0")
- [ ] T033 [US1] Create helm/backend-chart/values.yaml with defaults (replicaCount: 2, image: todo-backend:latest, service: ClusterIP, port: 8000, secrets refs per ADR-004)
- [ ] T034 [US1] Create helm/backend-chart/templates/deployment.yaml with Deployment resource (2 replicas, liveness/readiness probes per ADR-003, secrets injection per ADR-004, resource limits)
- [ ] T035 [US1] Create helm/backend-chart/templates/service.yaml with ClusterIP Service (port 8000 per FR-010)
- [ ] T036 [US1] Create helm/backend-chart/templates/_helpers.tpl with template helpers
- [ ] T037 [US1] Validate backend Helm chart: `helm lint helm/backend-chart/`
- [ ] T038 [US1] Document kubectl-ai/kagent usage for backend chart in docs/phase-iv/aiops-evidence.md

### Frontend Helm Chart (US1)

- [ ] T039 [US1] Use kubectl-ai and/or kagent to generate frontend Helm chart structure in helm/frontend-chart/
- [ ] T040 [US1] Create helm/frontend-chart/Chart.yaml with metadata (name: todo-frontend, version: 0.1.0, appVersion: "1.0")
- [ ] T041 [US1] Create helm/frontend-chart/values.yaml with defaults (replicaCount: 1, image: todo-frontend:latest, service: NodePort, port: 3000, nodePort: 30080, backend URL env var)
- [ ] T042 [US1] Create helm/frontend-chart/templates/deployment.yaml with Deployment resource (1 replica, liveness/readiness probes, backend URL env var, resource limits)
- [ ] T043 [US1] Create helm/frontend-chart/templates/service.yaml with NodePort Service (port 3000, nodePort 30080 per ADR-002, FR-009)
- [ ] T044 [US1] Create helm/frontend-chart/templates/_helpers.tpl with template helpers
- [ ] T045 [US1] Validate frontend Helm chart: `helm lint helm/frontend-chart/`
- [ ] T046 [US1] Document kubectl-ai/kagent usage for frontend chart in docs/phase-iv/aiops-evidence.md

### Deployment & Validation (US1)

- [ ] T047 [US1] Install backend Helm chart: `helm install todo-backend helm/backend-chart/ --namespace=todo-app --wait --timeout=5m`
- [ ] T048 [US1] Verify backend pods running: `kubectl get pods -n todo-app -l app=todo-backend`
- [ ] T049 [US1] Verify backend service created: `kubectl get svc -n todo-app todo-backend`
- [ ] T050 [US1] Check backend pod logs for startup success: `kubectl logs -n todo-app -l app=todo-backend --tail=50`
- [ ] T051 [US1] Install frontend Helm chart: `helm install todo-frontend helm/frontend-chart/ --namespace=todo-app --wait --timeout=5m`
- [ ] T052 [US1] Verify frontend pod running: `kubectl get pods -n todo-app -l app=todo-frontend`
- [ ] T053 [US1] Verify frontend service created: `kubectl get svc -n todo-app todo-frontend`
- [ ] T054 [US1] Get frontend service URL: `minikube service todo-frontend --namespace=todo-app --url`
- [ ] T055 [US1] Access chatbot UI via Minikube service URL and verify it loads within 5 seconds (SC-001)
- [ ] T056 [US1] Test Phase III chatbot functionality (add/update/delete/list tasks via natural language) and verify 100% feature parity (SC-005)
- [ ] T057 [US1] Verify frontend-to-backend connectivity by testing chatbot operations end-to-end
- [ ] T058 [US1] Document deployment validation results in docs/phase-iv/validation-results.md

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. MVP is complete!

---

## Phase 4: User Story 2 - System Survives Pod Restarts (Priority: P2)

**Goal**: Validate stateless design and pod resilience

**Independent Test**: Manually delete pods and observe automatic recreation within 30 seconds with zero data loss

- [ ] T059 [US2] Identify backend pod name: `kubectl get pods -n todo-app -l app=todo-backend`
- [ ] T060 [US2] Delete backend pod manually: `kubectl delete pod <backend-pod-name> -n todo-app --force --grace-period=0`
- [ ] T061 [US2] Observe automatic pod recreation: `kubectl get pods -n todo-app -l app=todo-backend --watch` (verify <30 seconds per SC-004)
- [ ] T062 [US2] Verify new backend pod reaches Running state
- [ ] T063 [US2] Test chatbot functionality after backend pod restart (verify no data loss, session state preserved per acceptance scenario)
- [ ] T064 [US2] Delete frontend pod manually: `kubectl delete pod <frontend-pod-name> -n todo-app --force --grace-period=0`
- [ ] T065 [US2] Observe automatic pod recreation: `kubectl get pods -n todo-app -l app=todo-frontend --watch`
- [ ] T066 [US2] Verify frontend pod reaches Running state
- [ ] T067 [US2] Verify users can reconnect to frontend without errors
- [ ] T068 [US2] Test chatbot end-to-end after both pod restarts (verify Phase III functionality intact)
- [ ] T069 [US2] Document pod restart validation results in docs/phase-iv/validation-results.md

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Stateless design validated!

---

## Phase 5: User Story 3 - Backend Scales to Multiple Replicas (Priority: P3)

**Goal**: Validate horizontal scalability

**Independent Test**: Scale backend to 3 replicas via Helm values and verify all replicas serve requests without conflicts

- [ ] T070 [US3] Scale backend to 3 replicas: `helm upgrade todo-backend helm/backend-chart/ --set replicaCount=3 --namespace=todo-app --wait`
- [ ] T071 [US3] Verify 3 backend pods running: `kubectl get pods -n todo-app -l app=todo-backend` (should show 3 pods)
- [ ] T072 [US3] Check pod distribution: `kubectl describe pods -n todo-app -l app=todo-backend | grep Node:`
- [ ] T073 [US3] Test chatbot with multiple concurrent requests (simulate multiple users) to verify load distribution
- [ ] T074 [US3] Verify no data conflicts or race conditions in chatbot responses (FR-008, acceptance scenario: "no data conflicts")
- [ ] T075 [US3] Scale backend back to 2 replicas: `helm upgrade todo-backend helm/backend-chart/ --set replicaCount=2 --namespace=todo-app --wait`
- [ ] T076 [US3] Verify scaling down completes without user-facing disruption (test chatbot during scale-down)
- [ ] T077 [US3] Document scalability validation results in docs/phase-iv/validation-results.md

**Checkpoint**: All user stories (US1, US2, US3) should now be independently functional. Scalability validated!

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [ ] T078 [P] Use kubectl-ai to inspect all pods in todo-app namespace: `kubectl-ai "Show me all pods in todo-app namespace with their status and restarts"`
- [ ] T079 [P] Use kagent to analyze backend deployment health: `kagent analyze deployment todo-backend --namespace=todo-app`
- [ ] T080 [P] Use kagent to analyze frontend deployment health: `kagent analyze deployment todo-frontend --namespace=todo-app`
- [ ] T081 [P] Document all kubectl-ai and kagent usage in docs/phase-iv/aiops-evidence.md
- [ ] T082 Calculate AI DevOps tooling usage percentage: (AI-assisted tasks / total deployment tasks) × 100% (target: 80%+ per SC-008)
- [ ] T083 Run 1 hour stable operation test: Monitor pods continuously with `kubectl get pods -n todo-app --watch` (SC-011)
- [ ] T084 Verify all Kubernetes resources healthy: `kubectl get all -n todo-app` (SC-010)
- [ ] T085 Validate all acceptance criteria from spec.md (SC-001 through SC-011)
- [ ] T086 Verify constitutional compliance: Review all 11 constitutional principles from plan.md
- [ ] T087 Create deployment guide in docs/phase-iv/deployment-guide.md (step-by-step instructions from quickstart.md)
- [ ] T088 Finalize AIops evidence documentation in docs/phase-iv/aiops-evidence.md (commands, outputs, screenshots)
- [ ] T089 Finalize validation results in docs/phase-iv/validation-results.md (all success criteria validated)
- [ ] T090 Run quickstart.md validation (verify documented steps match actual deployment process)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T001-T009) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion (T010-T016)
  - Can start after T016 completes
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (T017-T058)
  - Tests pod restart behavior, requires deployed system from US1
- **User Story 3 (Phase 5)**: Depends on User Story 1 completion (T017-T058)
  - Tests scaling, requires deployed system from US1
  - US2 and US3 could run in parallel if staffed (both depend on US1 only)
- **Polish (Phase 6)**: Depends on all desired user stories being complete (T017-T077)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories ✅ TRUE MVP
- **User Story 2 (P2)**: Depends on User Story 1 (needs deployed system to test pod restarts)
- **User Story 3 (P3)**: Depends on User Story 1 (needs deployed system to test scaling)

**Note**: US2 and US3 are independent of each other (both depend only on US1)

### Within Each User Story

**User Story 1 (Deployment)**:
1. Backend containerization → Backend Helm chart → Backend deployment
2. Frontend containerization → Frontend Helm chart → Frontend deployment (can happen in parallel with backend)
3. Validation after both deployed

**Parallelization Within US1**:
- T017-T025 (Backend containerization) can run in parallel with T026-T030 (Frontend containerization)
- T031-T038 (Backend Helm chart) can run in parallel with T039-T046 (Frontend Helm chart)
- Backend deployment (T047-T050) must complete before frontend deployment (T051-T053) to ensure backend service exists

### Parallel Opportunities

- **Setup phase**: T002, T003, T004, T007, T008 can all run in parallel
- **Foundational phase**: T013, T014 can run in parallel
- **User Story 1**:
  - Backend containerization (T017-T025) parallel with Frontend containerization (T026-T030)
  - Backend Helm chart (T031-T038) parallel with Frontend Helm chart (T039-T046)
- **User Story 2 and User Story 3**: Can be worked on in parallel by different team members (both only depend on US1)
- **Polish phase**: T078, T079, T080, T081 can all run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch backend and frontend containerization together:
Task T017-T025: Backend containerization (Docker AI + build + test + load)
Task T026-T030: Frontend containerization (Docker AI + build + test + load)

# Launch backend and frontend Helm chart creation together:
Task T031-T038: Backend Helm chart (kubectl-ai/kagent + templates + validation)
Task T039-T046: Frontend Helm chart (kubectl-ai/kagent + templates + validation)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T009)
2. Complete Phase 2: Foundational (T010-T016) - CRITICAL, blocks all stories
3. Complete Phase 3: User Story 1 (T017-T058)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Run deployment validation, access chatbot, verify Phase III functionality
6. **MVP ACHIEVED**: System deployed to Kubernetes with full chatbot functionality

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (T001-T016)
2. Add User Story 1 → Test independently → Validate (T017-T058) ✅ **MVP DEPLOYED**
3. Add User Story 2 → Test independently → Validate pod restarts (T059-T069)
4. Add User Story 3 → Test independently → Validate scaling (T070-T077)
5. Polish & finalize → AI tool validation, documentation (T078-T090)
6. Each story adds capability without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T016)
2. Once Foundational is done:
   - **Developer A**: Backend containerization + Helm chart (T017-T025, T031-T038)
   - **Developer B**: Frontend containerization + Helm chart (T026-T030, T039-T046)
3. Sync point: Deploy backend then frontend (T047-T058)
4. Validate User Story 1 together
5. Split again:
   - **Developer A**: User Story 2 (pod restart testing, T059-T069)
   - **Developer B**: User Story 3 (scaling testing, T070-T077)
6. Team finalizes together: Polish phase (T078-T090)

---

## Task Statistics

**Total Tasks**: 90
- Setup: 9 tasks (T001-T009)
- Foundational: 7 tasks (T010-T016)
- User Story 1 (P1 - MVP): 42 tasks (T017-T058)
- User Story 2 (P2 - Resilience): 11 tasks (T059-T069)
- User Story 3 (P3 - Scalability): 8 tasks (T070-T077)
- Polish & Cross-Cutting: 13 tasks (T078-T090)

**Parallel Opportunities**: 18 tasks marked [P]

**User Story Distribution**:
- US1 (Deployment): 42 tasks (47% of total)
- US2 (Resilience): 11 tasks (12% of total)
- US3 (Scalability): 8 tasks (9% of total)
- Infrastructure (Setup + Foundational + Polish): 29 tasks (32% of total)

---

## Notes

- [P] tasks = different files/commands, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- No tests requested - Phase IV uses manual validation (kubectl commands, chatbot testing)
- Commit after each logical task group (e.g., after backend containerization complete)
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- AI DevOps tools (Docker AI, kubectl-ai, kagent) usage documented throughout for 80%+ target

# ADR-003: Failure Handling & Resilience Strategy

> **Scope**: Document decision clusters, not individual technology choices. Group related decisions that work together (e.g., "Frontend Stack" not separate ADRs for framework, styling, deployment).

- **Status:** Accepted
- **Date:** 2025-12-24
- **Feature:** 001-k8s-minikube-deployment
- **Context:** Phase IV must validate stateless architecture and production-readiness through resilience testing. The application must handle pod restarts, database connectivity failures, and resource exhaustion gracefully. Specification clarifications (FR-033, FR-034, FR-035) define required behaviors for failure scenarios. This decision cluster integrates health checks, retry logic, and graceful degradation patterns.

## Decision

Adopt **integrated failure handling strategy** combining Kubernetes health checks, exponential backoff retry, and graceful degradation:

**Health Check Strategy**:
- **Liveness probe**: HTTP GET `/health/live` - checks if process is alive (always returns 200 OK)
- **Readiness probe**: HTTP GET `/health/ready` - checks if pod can serve traffic (fails when database unavailable)
- **Probe separation rationale**: Prevents unnecessary pod restarts during temporary failures (database outages)

**Database Retry Logic**:
- **Pattern**: Exponential backoff with jitter
- **Schedule**: 1s, 2s, 4s, 8s, 16s, 32s, 60s (max), 60s... (up to 10 attempts)
- **Jitter**: Random 0-25% of wait time to prevent synchronized retry storms
- **Behavior**: Pods stay running during retry, readiness probe fails, HTTP 503 returned to clients

**Graceful Degradation**:
- **Database unavailable**: Backend returns HTTP 503 Service Unavailable (not 500)
- **Startup validation**: Pods exit with error code if required secrets missing (FR-023)
- **Resource exhaustion**: New pods remain Pending with "Insufficient resources" error (existing pods continue)

**Self-Healing**:
- **Pod failures**: Kubernetes Deployment controller automatically recreates failed pods
- **Target recovery**: <30 seconds from pod deletion to new pod Running state
- **Data preservation**: All state in external Neon PostgreSQL (no in-memory state lost)

## Consequences

### Positive

- **Production-ready resilience**: Handles common failure modes (DB outage, pod crash, resource pressure) gracefully
- **No data loss**: Stateless design + external DB ensures pod restarts preserve user data
- **Operational visibility**: Clear health check failures + HTTP 503 responses aid debugging
- **Prevents cascading failures**: Exponential backoff + jitter prevent thundering herd on database restart
- **Kubernetes-native**: Leverages built-in self-healing, no custom operators or sidecars
- **Testable**: Clear acceptance criteria for pod restart and scaling (User Stories P2, P3)
- **Client-friendly errors**: HTTP 503 (temporary failure) vs 500 (server error) allows client retry logic

### Negative

- **Implementation complexity**: Requires separate health check endpoints, retry logic, startup validation code
- **Temporary unavailability**: Database outages cause 503 responses until connection restored (by design)
- **Debugging overhead**: Need to distinguish between liveness/readiness failures in logs
- **Retry delays**: Database reconnection can take 1-2 minutes with full exponential backoff
- **Testing challenges**: Must simulate failure scenarios (kubectl delete pod, database unreachable) for validation

## Alternatives Considered

**Alternative A: Single Health Check + Immediate Pod Restart**
- Approach: Single `/health` endpoint that fails when database unavailable, triggering pod restart
- Rejected because:
  - Unnecessary pod restarts during temporary database outages
  - Wastes resources (pod termination + restart overhead)
  - Doesn't allow database connection retry before giving up
  - Spec clarification explicitly requires pods to "stay running" (FR-033, FR-034)

**Alternative B: Circuit Breaker Pattern**
- Approach: Implement circuit breaker (open/half-open/closed states) for database calls
- Rejected because:
  - Overkill for Phase IV local deployment (single database dependency)
  - Adds complexity (state machine, threshold tuning, timeout management)
  - Better suited for microservices with multiple external dependencies
  - Exponential backoff + readiness probes sufficient for current scope

**Alternative C: Fail-Fast on Startup Issues**
- Approach: Exit immediately if database unreachable at startup (no retry logic)
- Partially adopted:
  - Missing secrets: Pods DO fail fast (CrashLoopBackOff) per FR-023
  - Database connectivity: Pods retry with backoff (not fail-fast) per FR-033
- Rationale: Database may be temporarily unavailable during cluster startup (race condition), but missing secrets indicate configuration error requiring operator intervention

**Alternative D: In-Memory Request Queuing**
- Approach: Queue requests in memory during database outages, replay when connection restored
- Rejected because:
  - Violates stateless design (constitutional requirement V)
  - Memory limits cause pod OOMKills under high load
  - Data loss on pod restart during outage
  - Spec clarification explicitly requires HTTP 503 (not queuing) per FR-034

## References

- Feature Spec: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md) (FR-023, FR-028, FR-032, FR-033, FR-034, FR-035; Edge Cases section)
- Implementation Plan: [specs/001-k8s-minikube-deployment/plan.md](../../specs/001-k8s-minikube-deployment/plan.md) (Phase 4.4, Phase 4.8)
- Research: [specs/001-k8s-minikube-deployment/research.md](../../specs/001-k8s-minikube-deployment/research.md#2-kubernetes-health-checks) (Sections 2, 3, 9)
- Clarifications: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md#clarifications) (Session 2025-12-24, Q1-Q3)
- Related ADRs: ADR-001 (Container Strategy - health check endpoints in images), ADR-004 (Secrets Management - startup validation)

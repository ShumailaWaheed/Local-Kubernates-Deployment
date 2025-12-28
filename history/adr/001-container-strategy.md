# ADR-001: Container Strategy

> **Scope**: Document decision clusters, not individual technology choices. Group related decisions that work together (e.g., "Frontend Stack" not separate ADRs for framework, styling, deployment).

- **Status:** Accepted
- **Date:** 2025-12-24
- **Feature:** 001-k8s-minikube-deployment
- **Context:** Phase IV requires containerizing the Phase III Todo AI Chatbot (Next.js frontend + FastAPI backend) for deployment to Kubernetes. The containerization strategy must balance image size, build time, security, and deployment efficiency while maintaining Phase III application behavior unchanged.

## Decision

Adopt **multi-stage Docker builds with Alpine Linux base images** for both frontend and backend containers:

**Frontend (Next.js)**:
- Base: `node:18-alpine`
- Stages: Dependencies → Builder → Runner
- Build approach: Separate production dependencies from build tools
- Runtime: Minimal Node.js runtime with built Next.js artifacts

**Backend (FastAPI)**:
- Base: `python:3.11-slim`
- Stages: Builder → Runner
- Build approach: User-local pip install, copy to slim runtime
- Runtime: Python runtime with compiled dependencies only

**Common Strategy**:
- Multi-stage builds to separate build-time and runtime dependencies
- Alpine/slim base images for minimal image size
- Health check endpoints built into containers
- No secrets or environment-specific configuration in images

## Consequences

### Positive

- **Reduced image size**: 60-70% smaller than single-stage builds (Alpine: ~50MB base vs. ~900MB full Node/Python images)
- **Improved security**: Build tools excluded from production images, reducing attack surface
- **Faster deployments**: Smaller images mean faster pulls to Minikube and quicker pod startup
- **Layer caching**: Multi-stage builds optimize Docker layer caching, speeding up rebuilds
- **Production-ready**: Images contain only runtime dependencies, matching production best practices

### Negative

- **Build complexity**: Multi-stage Dockerfiles more complex than single-stage (3 stages vs. 1 for frontend)
- **Alpine compatibility**: Some Python packages may have issues with Alpine's musl libc (mitigated by using python:slim for backend)
- **Debugging overhead**: Minimal images lack debugging tools (must install at runtime if needed)
- **Build time**: Initial builds slower due to multi-stage compilation (offset by layer caching on subsequent builds)

## Alternatives Considered

**Alternative A: Single-Stage Builds with Full Base Images**
- Approach: Use `node:18` and `python:3.11` without multi-stage
- Rejected because:
  - 3-4x larger image sizes (~400MB frontend, ~1GB backend)
  - Security risk: includes build tools, compilers, unnecessary packages
  - Slower Minikube image loads and pod startup times

**Alternative B: Debian-Based Slim Images Throughout**
- Approach: Use `debian:bullseye-slim` as base for both frontend and backend
- Rejected because:
  - Larger base image size (~70MB vs. ~5MB Alpine)
  - More packages to maintain and patch
  - Less Docker ecosystem optimization (Alpine has better layer caching)

**Alternative C: Distroless Images**
- Approach: Use Google's distroless images (no shell, no package manager)
- Rejected because:
  - Extremely difficult to debug (no shell access)
  - Overkill for Phase IV local deployment
  - Better suited for production cloud deployments (reserved for Phase V)

## References

- Feature Spec: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md) (FR-001, FR-002, FR-003)
- Implementation Plan: [specs/001-k8s-minikube-deployment/plan.md](../../specs/001-k8s-minikube-deployment/plan.md) (Phase 4.3, Phase 4.4)
- Research: [specs/001-k8s-minikube-deployment/research.md](../../specs/001-k8s-minikube-deployment/research.md#1-docker-containerization-best-practices)
- Related ADRs: ADR-003 (Failure Handling & Resilience - health checks)

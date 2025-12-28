# ADR-002: Kubernetes Deployment Platform

> **Scope**: Document decision clusters, not individual technology choices. Group related decisions that work together (e.g., "Frontend Stack" not separate ADRs for framework, styling, deployment).

- **Status:** Accepted
- **Date:** 2025-12-24
- **Feature:** 001-k8s-minikube-deployment
- **Context:** Phase IV validates production-readiness through local Kubernetes deployment. The platform choice affects development workflow, resource requirements, deployment complexity, and ability to simulate production Kubernetes behavior. The decision is constrained by constitutional requirements (Docker Desktop + Minikube mandatory) but the integrated toolchain approach is architecturally significant.

## Decision

Adopt **Minikube + Docker Desktop + Helm** as integrated local Kubernetes deployment platform:

**Kubernetes Distribution**:
- Platform: Minikube (single-node local cluster)
- Driver: Docker (using Docker Desktop as container runtime)
- Version: Kubernetes 1.28+
- Configuration: 8GB RAM, 4 CPU cores minimum

**Package Management**:
- Tool: Helm 3.x
- Chart structure: Separate charts for frontend and backend
- Values management: Environment-specific `values.yaml` overrides

**Resource Management**:
- Backend: 2+ replicas with ClusterIP Service
- Frontend: 1 replica with NodePort Service (port 30080)
- Resource requests/limits defined for all pods

**Integrated Workflow**:
1. Build images with Docker Desktop
2. Load images into Minikube (`minikube image load`)
3. Deploy via Helm charts (no raw kubectl YAML)
4. Expose frontend via Minikube service tunneling

## Consequences

### Positive

- **Production-like environment**: Minikube closely simulates real Kubernetes clusters with standard API
- **Docker Desktop integration**: Seamless image building and loading without external registry
- **Helm templating**: Reusable charts with environment-specific configuration via `values.yaml`
- **Local development**: No cloud costs, full control over cluster lifecycle
- **Resource isolation**: Docker Desktop provides controlled resource allocation preventing host system impact
- **Standard tooling**: kubectl, Helm work identically to production workflows
- **Rapid iteration**: Quick cluster start/stop, fast image loading (<1 minute for typical changes)

### Negative

- **Resource overhead**: 8GB RAM + 4 CPU cores required (may strain older development machines)
- **Windows-specific setup**: Docker Desktop required on Windows (adds license consideration for teams)
- **Single-node limitations**: Cannot test multi-node features (node affinity, pod anti-affinity) in Phase IV
- **Limited scalability testing**: Minikube constrained by local machine resources (cannot stress-test 100+ pods)
- **Network complexity**: Minikube networking differs from cloud providers (requires `minikube service` tunneling for external access)
- **Learning curve**: Developers unfamiliar with Kubernetes must learn Minikube-specific commands

## Alternatives Considered

**Alternative A: kind (Kubernetes in Docker) + Docker Desktop + Helm**
- Approach: Use kind instead of Minikube for local Kubernetes
- Rejected because:
  - Constitutional requirement VII explicitly mandates Minikube
  - kind has different networking model (more complex service exposure)
  - Minikube has better Windows Docker Desktop integration
  - Minikube provides richer addon ecosystem (metrics-server, dashboard)

**Alternative B: k3s (Lightweight Kubernetes) + Helm**
- Approach: Use Rancher's k3s for minimal Kubernetes distribution
- Rejected because:
  - Constitutional requirement VII forbids k3s for Phase IV
  - k3s uses Traefik by default (requires different ingress patterns)
  - Less familiar to most Kubernetes practitioners
  - Not a standard test target for cloud-native applications

**Alternative C: Raw kubectl YAML Deployment (No Helm)**
- Approach: Deploy using plain Kubernetes YAML manifests
- Rejected because:
  - Constitutional requirement VIII mandates Helm-only deployment
  - No templating or environment-specific configuration
  - Harder to manage secrets and configuration values
  - Not reusable across environments (dev, staging, prod)
  - Manual kubectl apply error-prone and not reproducible

**Alternative D: Docker Compose (No Kubernetes)**
- Approach: Use Docker Compose for multi-container orchestration
- Rejected because:
  - Doesn't validate Kubernetes deployment patterns
  - Missing core K8s features: Services, Deployments, health checks, replica management
  - Phase IV goal is production-readiness validation, requiring real Kubernetes

## References

- Feature Spec: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md) (FR-006 through FR-017, FR-029, FR-030)
- Implementation Plan: [specs/001-k8s-minikube-deployment/plan.md](../../specs/001-k8s-minikube-deployment/plan.md) (Phase 4.1, Phase 4.5, Phase 4.6, Phase 4.7)
- Research: [specs/001-k8s-minikube-deployment/research.md](../../specs/001-k8s-minikube-deployment/research.md#5-helm-chart-structure) (Sections 5 and 6)
- Constitution: [.specify/memory/constitution.md](../../.specify/memory/constitution.md) (Principles VI, VII, VIII)
- Related ADRs: None (foundational platform decision)

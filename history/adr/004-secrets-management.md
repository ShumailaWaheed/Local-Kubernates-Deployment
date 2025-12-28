# ADR-004: Secrets Management Strategy

> **Scope**: Document decision clusters, not individual technology choices. Group related decisions that work together (e.g., "Frontend Stack" not separate ADRs for framework, styling, deployment).

- **Status:** Accepted
- **Date:** 2025-12-24
- **Feature:** 001-k8s-minikube-deployment
- **Context:** Phase IV requires secure management of sensitive configuration (Neon PostgreSQL URL, OpenAI API keys) for Kubernetes deployment. Constitutional requirement XI mandates no secrets in Git, container images, or Helm templates. The secrets management approach must balance security, operational simplicity, and Phase IV's local deployment scope.

## Decision

Adopt **Kubernetes Secrets with environment variable injection** as integrated secrets management strategy:

**Secret Storage**:
- **Mechanism**: Native Kubernetes Secrets (stored encrypted in etcd)
- **Creation**: Manual `kubectl create secret` commands (not committed to Git)
- **Namespacing**: Secrets scoped to `todo-app` namespace

**Secret Injection**:
- **Method**: Environment variables via `secretKeyRef` in Deployment specs
- **Helm templating**: Secret names/keys referenced in `values.yaml`, not values themselves
- **Runtime binding**: Secrets mounted as env vars when pods start

**Startup Validation**:
- **Requirement**: Pods MUST validate presence and format of required secrets during initialization (FR-023)
- **Behavior**: Exit with error code if validation fails → CrashLoopBackOff
- **Required secrets**: `DATABASE_URL`, `OPENAI_API_KEY`

**Operational Workflow**:
1. Operator creates Kubernetes Secrets manually (one-time setup)
2. Helm charts reference secret names in templates (via `values.yaml`)
3. Pods read secrets from environment variables at startup
4. Startup validation checks secrets before application initialization
5. Secret updates require pod restart (via `kubectl rollout restart`)

## Consequences

### Positive

- **Native Kubernetes solution**: No external dependencies (no Vault, no cloud KMS)
- **Encrypted at rest**: Secrets stored encrypted in etcd (Kubernetes built-in)
- **Easy updates**: Change secrets without rebuilding images (`kubectl create secret --dry-run | kubectl apply`)
- **Namespace isolation**: Secrets scoped to `todo-app` namespace (not cluster-wide)
- **Constitutional compliance**: Zero secrets in Git, images, or Helm templates (requirements FR-018 through FR-022)
- **Fail-fast validation**: Missing/invalid secrets cause immediate pod failure with clear error messages (FR-023)
- **Helm compatibility**: Secret references in `values.yaml` allow environment-specific overrides

### Negative

- **Base64 encoding only**: Kubernetes Secrets are base64-encoded, not encrypted in transit (mitigated by etcd encryption at rest)
- **Manual secret creation**: Operators must run kubectl commands (no GitOps-friendly declarative approach)
- **No secret rotation**: Updating secrets requires pod restart (not dynamic reload)
- **Limited RBAC granularity**: All pods in namespace can access all secrets in that namespace (acceptable for Phase IV single-tenant deployment)
- **No audit trail**: Secret access not logged by default (would require admission controller)
- **Debugging visibility**: Cannot easily view secret values via kubectl get (must use `-o json` and decode)

## Alternatives Considered

**Alternative A: External Secrets Operator + Cloud KMS**
- Approach: Use External Secrets Operator to sync from AWS Secrets Manager / Azure Key Vault
- Rejected because:
  - Adds external dependency (cloud provider account required)
  - Overkill for Phase IV local deployment
  - Increases complexity (operator installation, cloud IAM configuration)
  - Better suited for Phase V production cloud deployment

**Alternative B: Sealed Secrets (GitOps-Friendly)**
- Approach: Use Bitnami Sealed Secrets to commit encrypted secrets to Git
- Rejected because:
  - Requires additional controller installation in Minikube
  - Phase IV scope doesn't require Git-based secret management
  - Manual kubectl approach simpler for local development
  - Sealed Secrets decrypt to native Secrets anyway (same runtime model)

**Alternative C: ConfigMaps for Configuration**
- Approach: Use ConfigMaps instead of Secrets (since it's local deployment)
- Rejected because:
  - ConfigMaps are not encrypted (even in local etcd)
  - Violates security best practices (sensitive data in plain text)
  - Constitutional requirement XI explicitly mandates Secrets mechanism
  - No benefit over Secrets (same API, same injection method)

**Alternative D: Mounted Secret Files**
- Approach: Mount secrets as files in `/etc/secrets/` instead of environment variables
- Rejected because:
  - More complex application code (file reading vs environment variable access)
  - No significant security advantage for Phase IV local deployment
  - Environment variable approach more portable (same pattern used in cloud platforms)
  - Spec research.md explicitly chose env var pattern for simplicity

**Alternative E: Hardcoded Secrets in values.yaml**
- Approach: Put secret values directly in Helm values.yaml
- Rejected because:
  - Violates constitutional requirement XI (no secrets in Git)
  - Would require `.gitignore` for values.yaml (breaks chart reusability)
  - Dangerous if values.yaml accidentally committed
  - Spec requirements FR-020, FR-021 explicitly forbid this

## References

- Feature Spec: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md) (FR-018 through FR-023, Edge Cases)
- Implementation Plan: [specs/001-k8s-minikube-deployment/plan.md](../../specs/001-k8s-minikube-deployment/plan.md) (Phase 4.2)
- Research: [specs/001-k8s-minikube-deployment/research.md](../../specs/001-k8s-minikube-deployment/research.md#4-secrets-management-in-kubernetes)
- Constitution: [.specify/memory/constitution.md](../../.specify/memory/constitution.md) (Principle XI)
- Clarifications: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md#clarifications) (Session 2025-12-24, Q3 - missing secrets behavior)
- Related ADRs: ADR-003 (Failure Handling - startup validation integration)

# ADR-005: AI-Assisted DevOps Toolchain

> **Scope**: Document decision clusters, not individual technology choices. Group related decisions that work together (e.g., "Frontend Stack" not separate ADRs for framework, styling, deployment).

- **Status:** Accepted
- **Date:** 2025-12-24
- **Feature:** 001-k8s-minikube-deployment
- **Context:** Constitutional requirement IX and specification requirements FR-036 through FR-039 mandate AI-assisted DevOps for Phase IV deployment. The toolchain choice affects Dockerfile generation, Helm chart creation, operational debugging, and evidence documentation. The integrated toolchain must achieve 80%+ usage target (SC-008) while providing fallback options for tool unavailability.

## Decision

Adopt **Docker AI → kubectl-ai → kagent priority hierarchy** as integrated AI-assisted DevOps toolchain:

**Dockerfile Generation**:
- **Primary**: Docker AI (Gordon) - specialized Dockerfile generation from natural language
- **Fallback**: Claude Code - AI-assisted Dockerfile creation if Gordon unavailable
- **Scope**: Frontend (Next.js) and Backend (FastAPI) container images

**Helm Chart Generation & Kubernetes Operations**:
- **Primary**: kubectl-ai - natural language Kubernetes operations and manifest generation
- **Primary**: kagent - deployment health analysis and recommendations
- **Fallback**: Claude Code with manual validation
- **Scope**: Backend chart, Frontend chart, debugging, validation

**Operational Debugging**:
- **kubectl-ai**: Natural language pod inspection, troubleshooting, scaling
- **kagent**: Deployment analysis, issue diagnosis, optimization recommendations
- **Standard kubectl**: Fallback for unavailable AI tools

**Evidence Documentation**:
- **Requirement**: All AI tool usage MUST be documented (commands, outputs, decisions) per FR-039
- **Format**: Logs, screenshots, command transcripts in `docs/phase-iv/aiops-evidence.md`
- **Target**: 80%+ of deployment tasks use AI tooling (SC-008)

**Toolchain Workflow**:
1. Docker AI generates Dockerfiles → build images → load into Minikube
2. kubectl-ai + kagent generate Helm charts → install via Helm
3. kubectl-ai inspects pod status → kagent analyzes deployment health
4. Document all tool interactions with commands + outputs
5. Calculate usage percentage: (AI-assisted tasks / total tasks) × 100%

## Consequences

### Positive

- **Reduced manual effort**: AI tools generate boilerplate Dockerfiles and Helm templates
- **Natural language interface**: kubectl-ai allows non-expert Kubernetes operations ("scale backend to 3 replicas")
- **Best practices enforcement**: Docker AI incorporates multi-stage build patterns automatically
- **Operational insights**: kagent provides deployment health analysis beyond basic kubectl describe
- **Constitutional compliance**: Satisfies "No Manual Coding" principle II for infrastructure code
- **Hackathon differentiation**: AI-first DevOps approach demonstrates innovation (judge appeal)
- **Learning opportunity**: Team gains experience with emerging AI DevOps tools

### Negative

- **Tool availability**: Docker AI, kubectl-ai, kagent may not be installed or accessible in all environments
- **Inconsistent quality**: AI-generated Dockerfiles/charts may require manual review and correction
- **Limited context**: AI tools lack full project context (Phase III architecture, constitutional requirements)
- **Evidence overhead**: Documenting all tool usage (screenshots, logs) adds operational burden
- **Fallback complexity**: Must maintain Claude Code fallback paths for all operations
- **80% target pressure**: Target may incentivize AI usage over optimal manual solutions
- **Debugging AI outputs**: Errors in AI-generated artifacts harder to debug than manually written code

## Alternatives Considered

**Alternative A: Manual Dockerfile and Helm Chart Authoring**
- Approach: Engineers manually write all Dockerfiles and Helm templates
- Rejected because:
  - Violates constitutional requirement II (No Manual Coding)
  - Violates specification requirements FR-036, FR-037 (AI tooling mandatory)
  - Doesn't demonstrate AI-assisted DevOps capability (Phase IV objective)
  - Manual approach error-prone for complex multi-stage builds

**Alternative B: GitHub Copilot for Infrastructure Code**
- Approach: Use Copilot autocomplete for Dockerfile and Helm template generation
- Rejected because:
  - Copilot is code-completion, not full generation (doesn't satisfy "AI-assisted" requirement)
  - Requires manual IDE setup and GitHub account
  - Less targeted than specialized tools (Docker AI, kubectl-ai) for infrastructure
  - Doesn't provide operational debugging (no equivalent to kagent analysis)

**Alternative C: ChatGPT Web Interface for Ad-Hoc Generation**
- Approach: Use ChatGPT website to generate Dockerfiles/Helm charts, copy-paste results
- Rejected because:
  - Not integrated with Docker/kubectl workflows (manual copy-paste error-prone)
  - No command-line automation or scripting capability
  - Harder to document for evidence (screenshots of web browser)
  - Doesn't satisfy "kubectl-ai/kagent usage" specification requirement FR-037

**Alternative D: Terraform/Pulumi for Infrastructure as Code**
- Approach: Use Terraform Kubernetes provider or Pulumi for declarative infrastructure
- Rejected because:
  - Overkill for Phase IV local deployment (adds significant complexity)
  - Doesn't replace Helm charts (would duplicate functionality)
  - Constitutional requirement VIII mandates Helm-only deployment
  - IaC tools better suited for Phase V cloud deployment

**Alternative E: 100% AI Tooling (No Manual Fallback)**
- Approach: Require Docker AI, kubectl-ai, kagent availability, fail deployment if unavailable
- Rejected because:
  - Unrealistic for environments where AI tools cannot be installed
  - Blocks Phase IV completion if tools unavailable
  - Specification allows "fallback to Claude Code" (FR-036)
  - 80% target (not 100%) acknowledges some manual operations acceptable

## References

- Feature Spec: [specs/001-k8s-minikube-deployment/spec.md](../../specs/001-k8s-minikube-deployment/spec.md) (FR-036 through FR-039, SC-008)
- Implementation Plan: [specs/001-k8s-minikube-deployment/plan.md](../../specs/001-k8s-minikube-deployment/plan.md) (Phase 4.3, Phase 4.4, Phase 4.5, Phase 4.6, Phase 4.10)
- Research: [specs/001-k8s-minikube-deployment/research.md](../../specs/001-k8s-minikube-deployment/research.md#8-ai-assisted-devops-tooling)
- Constitution: [.specify/memory/constitution.md](../../.specify/memory/constitution.md) (Principle II - No Manual Coding, Principle IX - AI-Assisted DevOps Priority)
- Quickstart: [specs/001-k8s-minikube-deployment/quickstart.md](../../specs/001-k8s-minikube-deployment/quickstart.md#ai-devops-tools-optional)
- Related ADRs: ADR-001 (Container Strategy - Docker AI generates Dockerfiles), ADR-002 (Kubernetes Platform - kubectl-ai/kagent for Helm charts)

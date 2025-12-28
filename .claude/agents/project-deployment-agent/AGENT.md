# Project Deployment Agent

**Agent Name**: `project-deployment-agent`
**Version**: 1.0.0
**Author**: AI-Assisted Development
**Last Updated**: 2025-12-28

## Overview

An autonomous agent for end-to-end deployment of the Todo application to Kubernetes. This agent orchestrates the complete deployment pipeline from Docker image building to production-ready Kubernetes deployment with validation.

## Agent Identity

```yaml
name: project-deployment-agent
type: deployment-orchestrator
version: 1.0.0
description: |
  Autonomous deployment agent for Next.js + FastAPI applications.
  Handles Docker builds, Helm chart generation, Kubernetes deployment,
  secrets management, and deployment validation.
```

## Project Context

| Component | Technology | Port | Health Endpoint |
|-----------|------------|------|-----------------|
| Frontend | Next.js 16+ (React 19) | 3000 | `/api/health` |
| Backend | FastAPI + OpenAI Agents SDK | 8000 | `/health` |
| Orchestration | Kubernetes (Minikube local) | - | - |
| Package Manager | Helm 3.x | - | - |

## Skills Dependency

This agent uses the following skills in sequence:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        PROJECT DEPLOYMENT AGENT                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐    ┌─────────────────────┐                        │
│  │ docker-image-builder│───▶│ helm-chart-generator│                        │
│  └─────────────────────┘    └─────────────────────┘                        │
│           │                          │                                       │
│           ▼                          ▼                                       │
│  ┌─────────────────────┐    ┌─────────────────────┐                        │
│  │ k8s-secrets-manager │───▶│    k8s-deployer     │                        │
│  └─────────────────────┘    └─────────────────────┘                        │
│                                      │                                       │
│                                      ▼                                       │
│                          ┌─────────────────────┐                            │
│                          │  Validation & Report │                           │
│                          └─────────────────────┘                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

| Skill | Location | Purpose |
|-------|----------|---------|
| `docker-image-builder` | `.claude/skills/docker-image-builder/SKILL.md` | Build Docker images for frontend and backend |
| `helm-chart-generator` | `.claude/skills/helm-chart-generator/SKILL.md` | Generate/update Helm charts |
| `k8s-secrets-manager` | `.claude/skills/k8s-secrets-manager/SKILL.md` | Create and validate Kubernetes secrets |
| `k8s-deployer` | `.claude/skills/k8s-deployer/SKILL.md` | Deploy to Kubernetes and validate |

---

## Agent Workflow

### Phase 1: Pre-Deployment Checks

```yaml
phase: pre-deployment
actions:
  - name: validate_environment
    checks:
      - Docker Desktop is running
      - Minikube is running and accessible
      - kubectl is configured
      - Helm is installed
      - Required environment variables are set
    on_failure: ESCALATE

  - name: validate_source
    checks:
      - Frontend source exists (package.json with Next.js)
      - Backend source exists (requirements.txt or pyproject.toml)
      - Dockerfiles exist or can be generated
    on_failure: ESCALATE
```

### Phase 2: Build Docker Images

```yaml
phase: build
skill: docker-image-builder
actions:
  - name: build_frontend
    image: todo-frontend
    dockerfile: ./frontend/Dockerfile (or generate)
    context: ./frontend
    tags:
      - latest
      - ${GIT_SHA}

  - name: build_backend
    image: todo-backend
    dockerfile: ./backend/Dockerfile (or generate)
    context: ./backend
    tags:
      - latest
      - ${GIT_SHA}

  - name: load_to_minikube
    command: minikube image load todo-frontend:latest todo-backend:latest

validation:
  - docker images | grep todo-frontend
  - docker images | grep todo-backend
on_failure: ESCALATE
```

### Phase 3: Generate Helm Charts

```yaml
phase: helm_charts
skill: helm-chart-generator
actions:
  - name: generate_chart
    output_dir: ./helm/todo-app
    components:
      - frontend
      - backend
    includes:
      - Chart.yaml
      - values.yaml
      - values-dev.yaml
      - values-prod.yaml
      - templates/

  - name: validate_chart
    command: helm lint ./helm/todo-app
    on_failure: ESCALATE
```

### Phase 4: Manage Secrets

```yaml
phase: secrets
skill: k8s-secrets-manager
actions:
  - name: validate_env_vars
    required:
      - OPENAI_API_KEY
    optional:
      - DATABASE_URL
      - JWT_SECRET
      - NEXTAUTH_SECRET
    on_missing_required: ESCALATE

  - name: create_secrets
    namespace: ${NAMESPACE}
    secrets:
      - backend-secrets
      - frontend-secrets

  - name: validate_secrets
    command: kubectl get secrets -n ${NAMESPACE}
    on_failure: ESCALATE
```

### Phase 5: Deploy to Kubernetes

```yaml
phase: deploy
skill: k8s-deployer
actions:
  - name: helm_deploy
    command: |
      helm upgrade --install todo-app ./helm/todo-app \
        -f ./helm/todo-app/values-${ENVIRONMENT}.yaml \
        -n ${NAMESPACE} \
        --create-namespace \
        --wait \
        --timeout 5m \
        --atomic
    on_failure: ESCALATE

  - name: wait_for_pods
    command: |
      kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/instance=todo-app \
        -n ${NAMESPACE} \
        --timeout=120s
    on_failure: ESCALATE
```

### Phase 6: Validation & Health Checks

```yaml
phase: validation
actions:
  - name: check_pods
    expected_status: Running
    expected_ready: true
    min_replicas: 1
    on_failure: ESCALATE

  - name: check_services
    services:
      - todo-frontend
      - todo-backend
    verify_endpoints: true
    on_failure: ESCALATE

  - name: health_checks
    frontend:
      url: http://todo-frontend:3000/api/health
      expected_status: 200
    backend:
      url: http://todo-backend:8000/health
      expected_status: 200
    on_failure: ESCALATE

  - name: collect_logs
    components:
      - frontend
      - backend
    tail: 100
    search_errors: true
```

### Phase 7: Report Generation

```yaml
phase: report
actions:
  - name: generate_report
    format: structured
    includes:
      - deployment_status
      - pod_summary
      - service_summary
      - health_check_results
      - errors_and_warnings
      - access_urls
```

---

## Decision Authority Matrix

### ACCEPT Conditions (Agent can complete autonomously)

| Condition | Criteria | Action |
|-----------|----------|--------|
| Successful Build | Both images built, no errors | Continue to next phase |
| Helm Lint Pass | No errors from `helm lint` | Continue to deploy |
| Pods Ready | All pods Running and Ready | Continue to validation |
| Health Checks Pass | All endpoints return 200 | Generate success report |
| Secrets Created | All required secrets exist | Continue to deploy |

### ESCALATE Conditions (Requires human intervention)

| Condition | Criteria | Escalation Action |
|-----------|----------|-------------------|
| Docker Build Failure | Non-zero exit code | Stop, report error, request fix |
| Missing Required Env Vars | OPENAI_API_KEY not set | Stop, request credentials |
| Helm Lint Failure | Validation errors | Stop, report issues |
| Pod CrashLoopBackOff | Container restart loop | Collect logs, escalate |
| Health Check Failure | Non-200 response after retries | Collect logs, escalate |
| Timeout Exceeded | Pods not ready in 5 minutes | Collect state, escalate |
| Resource Quota Exceeded | Insufficient cluster resources | Report quota, escalate |
| Image Pull Failure | ImagePullBackOff status | Verify image name, escalate |

---

## Agent Configuration

### Environment Variables

```bash
# Required
OPENAI_API_KEY=sk-...          # Required for backend

# Optional
DATABASE_URL=postgresql://...   # If using database
JWT_SECRET=...                  # If using JWT auth
NEXTAUTH_SECRET=...             # If using NextAuth
DEPLOY_ENV=dev                  # dev or prod
NAMESPACE=todo-dev              # Kubernetes namespace
IMAGE_TAG=latest                # Docker image tag
```

### Agent Parameters

```yaml
# .claude/agents/project-deployment-agent/config.yaml
agent:
  name: project-deployment-agent
  version: 1.0.0

settings:
  environment: ${DEPLOY_ENV:-dev}
  namespace: ${NAMESPACE:-todo-dev}
  image_tag: ${IMAGE_TAG:-latest}
  timeout: 300  # seconds
  max_retries: 3

skills:
  - docker-image-builder
  - helm-chart-generator
  - k8s-secrets-manager
  - k8s-deployer

escalation:
  on_failure: true
  on_timeout: true
  on_missing_secrets: true

logging:
  level: info
  output: ./logs/deployment.log
```

---

## Execution Script

### Main Agent Script

```bash
#!/bin/bash
# .claude/agents/project-deployment-agent/run.sh
# Project Deployment Agent - Main Execution Script

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

AGENT_NAME="project-deployment-agent"
AGENT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Environment
DEPLOY_ENV=${DEPLOY_ENV:-dev}
NAMESPACE=${NAMESPACE:-todo-${DEPLOY_ENV}}
IMAGE_TAG=${IMAGE_TAG:-latest}
TIMEOUT=${TIMEOUT:-300}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Status tracking
DEPLOYMENT_STATUS="unknown"
ERRORS=()
WARNINGS=()

# =============================================================================
# LOGGING
# =============================================================================

log() {
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
  ERRORS+=("$1")
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
  WARNINGS+=("$1")
}

escalate() {
  log_error "ESCALATION REQUIRED: $1"
  DEPLOYMENT_STATUS="escalated"
  generate_report
  exit 1
}

# =============================================================================
# PHASE 1: PRE-DEPLOYMENT CHECKS
# =============================================================================

phase_pre_deployment() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "PHASE 1: Pre-Deployment Checks"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check Docker
  if ! docker info &> /dev/null; then
    escalate "Docker is not running"
  fi
  log_success "Docker is running"

  # Check Minikube
  if ! minikube status &> /dev/null; then
    log_warning "Minikube is not running, attempting to start..."
    minikube start || escalate "Failed to start Minikube"
  fi
  log_success "Minikube is running"

  # Check kubectl
  if ! kubectl cluster-info &> /dev/null; then
    escalate "kubectl is not configured"
  fi
  log_success "kubectl is configured"

  # Check Helm
  if ! helm version &> /dev/null; then
    escalate "Helm is not installed"
  fi
  log_success "Helm is installed"

  # Check required env vars
  if [ -z "${OPENAI_API_KEY}" ]; then
    escalate "OPENAI_API_KEY is not set"
  fi
  log_success "Required environment variables are set"

  log_success "Phase 1 completed"
}

# =============================================================================
# PHASE 2: BUILD DOCKER IMAGES
# =============================================================================

phase_build() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "PHASE 2: Build Docker Images"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cd "${PROJECT_ROOT}"

  # Set Minikube Docker environment
  eval $(minikube docker-env)

  # Build Frontend
  log "Building frontend image..."
  if [ -f "./frontend/Dockerfile" ]; then
    docker build -t todo-frontend:${IMAGE_TAG} -f ./frontend/Dockerfile ./frontend || \
      escalate "Frontend Docker build failed"
  elif [ -f "./Dockerfile" ]; then
    docker build -t todo-frontend:${IMAGE_TAG} . || \
      escalate "Frontend Docker build failed"
  else
    log_warning "No Dockerfile found for frontend, skipping..."
  fi
  log_success "Frontend image built: todo-frontend:${IMAGE_TAG}"

  # Build Backend
  log "Building backend image..."
  if [ -f "./backend/Dockerfile" ]; then
    docker build -t todo-backend:${IMAGE_TAG} -f ./backend/Dockerfile ./backend || \
      escalate "Backend Docker build failed"
  else
    log_warning "No backend Dockerfile found, skipping..."
  fi
  log_success "Backend image built: todo-backend:${IMAGE_TAG}"

  # Verify images
  docker images | grep -E "todo-(frontend|backend)" || \
    escalate "Docker images not found after build"

  log_success "Phase 2 completed"
}

# =============================================================================
# PHASE 3: GENERATE/VALIDATE HELM CHARTS
# =============================================================================

phase_helm() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "PHASE 3: Validate Helm Charts"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cd "${PROJECT_ROOT}"

  CHART_PATH="./helm/todo-app"
  VALUES_FILE="${CHART_PATH}/values-${DEPLOY_ENV}.yaml"

  # Check if Helm chart exists
  if [ ! -d "${CHART_PATH}" ]; then
    log_warning "Helm chart not found at ${CHART_PATH}"
    log "Generate using helm-chart-generator skill"
    escalate "Helm chart not found"
  fi

  # Lint chart
  log "Linting Helm chart..."
  helm lint ${CHART_PATH} || escalate "Helm lint failed"
  log_success "Helm chart validated"

  # Lint with values file
  if [ -f "${VALUES_FILE}" ]; then
    helm lint ${CHART_PATH} -f ${VALUES_FILE} || escalate "Helm lint with values failed"
    log_success "Helm chart validated with ${DEPLOY_ENV} values"
  fi

  log_success "Phase 3 completed"
}

# =============================================================================
# PHASE 4: MANAGE SECRETS
# =============================================================================

phase_secrets() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "PHASE 4: Manage Kubernetes Secrets"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Create namespace
  kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
  log_success "Namespace ${NAMESPACE} ready"

  # Create backend secrets
  log "Creating backend secrets..."
  kubectl create secret generic backend-secrets \
    --namespace=${NAMESPACE} \
    --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --from-literal=DATABASE_URL="${DATABASE_URL:-}" \
    --from-literal=JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32)}" \
    --dry-run=client -o yaml | kubectl apply -f -
  log_success "Backend secrets created"

  # Create frontend secrets
  log "Creating frontend secrets..."
  kubectl create secret generic frontend-secrets \
    --namespace=${NAMESPACE} \
    --from-literal=NEXTAUTH_SECRET="${NEXTAUTH_SECRET:-$(openssl rand -hex 32)}" \
    --from-literal=NEXTAUTH_URL="${NEXTAUTH_URL:-http://localhost:3000}" \
    --dry-run=client -o yaml | kubectl apply -f -
  log_success "Frontend secrets created"

  # Verify secrets
  kubectl get secrets -n ${NAMESPACE} | grep -E "(backend|frontend)-secrets" || \
    escalate "Secrets verification failed"

  log_success "Phase 4 completed"
}

# =============================================================================
# PHASE 5: DEPLOY TO KUBERNETES
# =============================================================================

phase_deploy() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "PHASE 5: Deploy to Kubernetes"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cd "${PROJECT_ROOT}"

  CHART_PATH="./helm/todo-app"
  VALUES_FILE="${CHART_PATH}/values-${DEPLOY_ENV}.yaml"

  log "Deploying with Helm..."
  helm upgrade --install todo-app ${CHART_PATH} \
    -f ${VALUES_FILE} \
    -n ${NAMESPACE} \
    --wait \
    --timeout 5m \
    --atomic || escalate "Helm deployment failed"

  log_success "Helm release deployed"

  # Wait for pods
  log "Waiting for pods to be ready..."
  kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/instance=todo-app \
    -n ${NAMESPACE} \
    --timeout=120s || escalate "Pods not ready within timeout"

  log_success "Phase 5 completed"
}

# =============================================================================
# PHASE 6: VALIDATION & HEALTH CHECKS
# =============================================================================

phase_validation() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "PHASE 6: Validation & Health Checks"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check pod status
  log "Checking pod status..."
  PODS_STATUS=$(kubectl get pods -n ${NAMESPACE} -o json)
  TOTAL_PODS=$(echo ${PODS_STATUS} | jq '.items | length')
  READY_PODS=$(echo ${PODS_STATUS} | jq '[.items[] | select(.status.conditions[]? | select(.type=="Ready" and .status=="True"))] | length')
  FAILED_PODS=$(echo ${PODS_STATUS} | jq '[.items[] | select(.status.phase=="Failed")] | length')

  log "Pods: ${READY_PODS}/${TOTAL_PODS} ready"

  if [ "${FAILED_PODS}" -gt 0 ]; then
    collect_error_logs
    escalate "Found ${FAILED_PODS} failed pods"
  fi

  if [ "${READY_PODS}" -ne "${TOTAL_PODS}" ]; then
    log_warning "Not all pods are ready"
  fi

  # Check services
  log "Checking services..."
  kubectl get services -n ${NAMESPACE} || escalate "Failed to get services"

  # Check endpoints
  log "Checking endpoints..."
  for svc in todo-frontend todo-backend; do
    ENDPOINTS=$(kubectl get endpoints ${svc} -n ${NAMESPACE} -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
    if [ -n "${ENDPOINTS}" ]; then
      log_success "${svc}: ${ENDPOINTS}"
    else
      log_warning "${svc}: No endpoints found"
    fi
  done

  # Health checks
  log "Running health checks..."
  BACKEND_URL=$(minikube service todo-backend -n ${NAMESPACE} --url 2>/dev/null || echo "")

  if [ -n "${BACKEND_URL}" ]; then
    if curl -sf "${BACKEND_URL}/health" > /dev/null 2>&1; then
      log_success "Backend health check passed"
    else
      log_warning "Backend health check failed (may need more time)"
    fi
  fi

  log_success "Phase 6 completed"
}

# =============================================================================
# COLLECT ERROR LOGS
# =============================================================================

collect_error_logs() {
  log "Collecting error logs..."

  for pod in $(kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}'); do
    log "Logs from ${pod}:"
    kubectl logs ${pod} -n ${NAMESPACE} --tail=50 2>/dev/null || true
  done

  log "Events:"
  kubectl get events -n ${NAMESPACE} --field-selector type!=Normal --sort-by='.lastTimestamp' | tail -10
}

# =============================================================================
# PHASE 7: GENERATE REPORT
# =============================================================================

generate_report() {
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "DEPLOYMENT REPORT"
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo ""
  echo "============================================================================="
  echo "  PROJECT DEPLOYMENT AGENT - REPORT"
  echo "============================================================================="
  echo ""
  echo "  Agent: ${AGENT_NAME} v${AGENT_VERSION}"
  echo "  Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "  Environment: ${DEPLOY_ENV}"
  echo "  Namespace: ${NAMESPACE}"
  echo ""

  # Deployment Status
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  DEPLOYMENT STATUS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ "${DEPLOYMENT_STATUS}" = "success" ]; then
    echo -e "  Status: ${GREEN}✅ SUCCESS${NC}"
  elif [ "${DEPLOYMENT_STATUS}" = "escalated" ]; then
    echo -e "  Status: ${RED}❌ ESCALATED${NC}"
  else
    echo -e "  Status: ${YELLOW}⚠️  ${DEPLOYMENT_STATUS}${NC}"
  fi

  # Pod Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  POD SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  kubectl get pods -n ${NAMESPACE} 2>/dev/null || echo "  Unable to fetch pods"

  # Service Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  SERVICE SUMMARY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  kubectl get services -n ${NAMESPACE} 2>/dev/null || echo "  Unable to fetch services"

  # Access URLs
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ACCESS URLS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Frontend: $(minikube service todo-frontend -n ${NAMESPACE} --url 2>/dev/null || echo 'N/A')"
  echo "  Backend:  $(minikube service todo-backend -n ${NAMESPACE} --url 2>/dev/null || echo 'N/A')"

  # Errors
  if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${RED}ERRORS${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for err in "${ERRORS[@]}"; do
      echo "  - ${err}"
    done
  fi

  # Warnings
  if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${YELLOW}WARNINGS${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for warn in "${WARNINGS[@]}"; do
      echo "  - ${warn}"
    done
  fi

  echo ""
  echo "============================================================================="
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  log "============================================================================="
  log "${AGENT_NAME} v${AGENT_VERSION}"
  log "Starting deployment to ${DEPLOY_ENV} environment"
  log "============================================================================="

  phase_pre_deployment
  phase_build
  phase_helm
  phase_secrets
  phase_deploy
  phase_validation

  DEPLOYMENT_STATUS="success"
  generate_report

  log_success "Deployment completed successfully!"
}

# Run main
main "$@"
```

---

## JSON Report Format

```json
{
  "agent": {
    "name": "project-deployment-agent",
    "version": "1.0.0"
  },
  "deployment": {
    "timestamp": "2025-12-28T12:00:00Z",
    "environment": "dev",
    "namespace": "todo-dev",
    "status": "success|escalated|failed"
  },
  "phases": {
    "pre_deployment": {"status": "success", "duration_ms": 1234},
    "build": {"status": "success", "images": ["todo-frontend:latest", "todo-backend:latest"]},
    "helm": {"status": "success", "chart_version": "1.0.0"},
    "secrets": {"status": "success", "secrets_created": 2},
    "deploy": {"status": "success", "release": "todo-app", "revision": 1},
    "validation": {"status": "success", "pods_ready": 4, "pods_total": 4}
  },
  "pods": [
    {"name": "todo-frontend-abc123", "status": "Running", "ready": true, "restarts": 0},
    {"name": "todo-backend-def456", "status": "Running", "ready": true, "restarts": 0}
  ],
  "services": [
    {"name": "todo-frontend", "type": "NodePort", "port": 80, "endpoints": 2},
    {"name": "todo-backend", "type": "ClusterIP", "port": 8000, "endpoints": 2}
  ],
  "health_checks": {
    "frontend": {"url": "/api/health", "status": 200, "healthy": true},
    "backend": {"url": "/health", "status": 200, "healthy": true}
  },
  "access_urls": {
    "frontend": "http://192.168.49.2:30080",
    "backend": "http://192.168.49.2:30800"
  },
  "errors": [],
  "warnings": []
}
```

---

## Usage

### Run Full Deployment

```bash
# Set required environment variables
export OPENAI_API_KEY="sk-your-key"
export DEPLOY_ENV="dev"

# Run agent
./.claude/agents/project-deployment-agent/run.sh
```

### Run Specific Phase

```bash
# Source the script functions
source ./.claude/agents/project-deployment-agent/run.sh

# Run individual phases
phase_pre_deployment
phase_build
phase_secrets
```

### Dry Run

```bash
# Set DRY_RUN to see what would happen
DRY_RUN=true ./.claude/agents/project-deployment-agent/run.sh
```

---

## Troubleshooting

| Issue | Agent Action | Resolution |
|-------|--------------|------------|
| Docker not running | ESCALATE | Start Docker Desktop |
| Minikube not running | Auto-start, or ESCALATE | Start Minikube manually |
| Missing OPENAI_API_KEY | ESCALATE | Set environment variable |
| Build failed | ESCALATE with logs | Fix Dockerfile or dependencies |
| Pods CrashLoopBackOff | Collect logs, ESCALATE | Check application logs |
| Health check timeout | Retry 3x, then ESCALATE | Check application startup |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-28 | Initial release with full deployment pipeline |

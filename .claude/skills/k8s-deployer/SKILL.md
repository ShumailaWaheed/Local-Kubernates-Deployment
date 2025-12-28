# Kubernetes Deployer Skill

**Skill Name**: `k8s-deployer`
**Version**: 1.0.0
**Author**: AI-Assisted Development
**Last Updated**: 2025-12-28

## Purpose

A reusable skill for deploying and validating applications on Kubernetes clusters:
- **Deploy**: Install or upgrade Helm releases for frontend and backend
- **Validate**: Check pods, services, deployments, secrets, and endpoints
- **Debug**: Collect logs and identify deployment issues
- **Target**: Minikube/local clusters for development, extensible to production

## Prerequisites

### Required Tools
```bash
# Verify all tools are installed
helm version --short          # Helm 3.x required
kubectl version --client      # kubectl configured
minikube status               # Minikube running (for local dev)
```

### Required Files
- Helm chart at `./helm/todo-app/` (from helm-chart-generator skill)
- Docker images built and loaded into Minikube (from docker-image-builder skill)

### Pre-Deployment Checklist
```bash
# 1. Minikube is running
minikube status

# 2. Docker images are available
minikube image list | grep todo

# 3. Helm chart exists and is valid
helm lint ./helm/todo-app
```

---

## Step 1: Helm Install/Upgrade Commands

### Environment Variables Setup

```bash
# =============================================================================
# DEPLOYMENT CONFIGURATION
# =============================================================================

# Set environment (dev or prod)
export DEPLOY_ENV=${DEPLOY_ENV:-dev}
export NAMESPACE="todo-${DEPLOY_ENV}"
export RELEASE_NAME="todo-app"
export CHART_PATH="./helm/todo-app"
export VALUES_FILE="${CHART_PATH}/values-${DEPLOY_ENV}.yaml"

# Timeouts and retries
export HELM_TIMEOUT="5m"
export WAIT_TIMEOUT="300s"
export MAX_RETRIES=3
```

### Fresh Installation

```bash
# =============================================================================
# HELM INSTALL (Fresh Deployment)
# =============================================================================

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install with Helm
helm install ${RELEASE_NAME} ${CHART_PATH} \
  -f ${VALUES_FILE} \
  -n ${NAMESPACE} \
  --wait \
  --timeout ${HELM_TIMEOUT} \
  --atomic \
  --debug

# Check installation status
helm status ${RELEASE_NAME} -n ${NAMESPACE}
```

### Upgrade Existing Deployment

```bash
# =============================================================================
# HELM UPGRADE (Update Existing Deployment)
# =============================================================================

# Upgrade with rollback on failure
helm upgrade ${RELEASE_NAME} ${CHART_PATH} \
  -f ${VALUES_FILE} \
  -n ${NAMESPACE} \
  --wait \
  --timeout ${HELM_TIMEOUT} \
  --atomic \
  --history-max 5

# View upgrade history
helm history ${RELEASE_NAME} -n ${NAMESPACE}
```

### Install or Upgrade (Idempotent)

```bash
# =============================================================================
# HELM UPGRADE --INSTALL (Recommended for CI/CD)
# =============================================================================

helm upgrade --install ${RELEASE_NAME} ${CHART_PATH} \
  -f ${VALUES_FILE} \
  -n ${NAMESPACE} \
  --create-namespace \
  --wait \
  --timeout ${HELM_TIMEOUT} \
  --atomic
```

### With Secrets Override

```bash
# Pass secrets via command line (don't commit to git!)
helm upgrade --install ${RELEASE_NAME} ${CHART_PATH} \
  -f ${VALUES_FILE} \
  -n ${NAMESPACE} \
  --create-namespace \
  --set backend.secrets.data.OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --set backend.secrets.data.DATABASE_URL="${DATABASE_URL}" \
  --wait \
  --atomic
```

---

## Step 2: Verify Pod Status and Readiness

### Quick Pod Status Check

```bash
# =============================================================================
# POD STATUS VERIFICATION
# =============================================================================

# List all pods in namespace
kubectl get pods -n ${NAMESPACE} -o wide

# Watch pods until ready
kubectl get pods -n ${NAMESPACE} -w

# Detailed pod status
kubectl get pods -n ${NAMESPACE} -o json | jq -r '
  .items[] |
  "\(.metadata.name) | Status: \(.status.phase) | Ready: \(.status.conditions[]? | select(.type=="Ready") | .status) | Restarts: \(.status.containerStatuses[]?.restartCount // 0)"
'
```

### Detailed Pod Health Check Script

```bash
#!/bin/bash
# scripts/check-pods.sh

NAMESPACE=${1:-todo-dev}
TIMEOUT=${2:-300}

echo "=== Pod Status Check for ${NAMESPACE} ==="

# Function to check if all pods are ready
check_pods_ready() {
  local ready_pods=$(kubectl get pods -n ${NAMESPACE} -o json | jq -r '
    [.items[] | select(.status.phase == "Running") |
     select(.status.conditions[] | select(.type == "Ready" and .status == "True"))] | length
  ')
  local total_pods=$(kubectl get pods -n ${NAMESPACE} --no-headers | wc -l)

  echo "Ready: ${ready_pods}/${total_pods}"
  [ "$ready_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]
}

# Wait for pods to be ready
echo "Waiting for pods to be ready (timeout: ${TIMEOUT}s)..."
start_time=$(date +%s)

while true; do
  if check_pods_ready; then
    echo "✅ All pods are ready!"
    break
  fi

  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if [ $elapsed -ge $TIMEOUT ]; then
    echo "❌ Timeout waiting for pods to be ready"
    kubectl get pods -n ${NAMESPACE}
    exit 1
  fi

  sleep 5
done

# Display final pod status
echo ""
echo "=== Final Pod Status ==="
kubectl get pods -n ${NAMESPACE} -o wide

# Check for any pods with issues
echo ""
echo "=== Pod Health Summary ==="
kubectl get pods -n ${NAMESPACE} -o json | jq -r '
  .items[] |
  "Pod: \(.metadata.name)
   Status: \(.status.phase)
   Ready: \(.status.conditions[]? | select(.type=="Ready") | .status)
   Restarts: \(.status.containerStatuses[]?.restartCount // 0)
   Node: \(.spec.nodeName)
   ---"
'
```

### Check Pod Readiness Conditions

```bash
# Check all readiness conditions for each pod
kubectl get pods -n ${NAMESPACE} -o json | jq -r '
  .items[] |
  "=== \(.metadata.name) ===",
  (.status.conditions[] | "  \(.type): \(.status) (Reason: \(.reason // "N/A"))"),
  ""
'

# Check container statuses
kubectl get pods -n ${NAMESPACE} -o json | jq -r '
  .items[] |
  "=== \(.metadata.name) ===",
  (.status.containerStatuses[]? |
    "  Container: \(.name)
     Ready: \(.ready)
     Started: \(.started)
     Restarts: \(.restartCount)
     State: \(.state | keys[0])"),
  ""
'
```

---

## Step 3: Check Services and Endpoints

### Service Status

```bash
# =============================================================================
# SERVICE VERIFICATION
# =============================================================================

# List all services
kubectl get services -n ${NAMESPACE}

# Detailed service info
kubectl get services -n ${NAMESPACE} -o wide

# Describe services for troubleshooting
kubectl describe services -n ${NAMESPACE}
```

### Endpoint Verification

```bash
# Check endpoints are properly assigned
kubectl get endpoints -n ${NAMESPACE}

# Detailed endpoint check
kubectl get endpoints -n ${NAMESPACE} -o json | jq -r '
  .items[] |
  "Service: \(.metadata.name)
   Endpoints: \(.subsets[]?.addresses[]?.ip // "None"):\(.subsets[]?.ports[]?.port // "None")
   ---"
'

# Verify endpoints have backing pods
for svc in $(kubectl get svc -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== Service: ${svc} ==="
  kubectl get endpoints ${svc} -n ${NAMESPACE}
  echo ""
done
```

### Service Connectivity Test

```bash
# =============================================================================
# SERVICE CONNECTIVITY TESTS
# =============================================================================

# For Minikube: Get service URLs
echo "=== Frontend URL ==="
minikube service todo-frontend -n ${NAMESPACE} --url

echo "=== Backend URL ==="
minikube service todo-backend -n ${NAMESPACE} --url

# Port forward for testing (run in background)
echo "=== Port Forwarding ==="
kubectl port-forward svc/todo-frontend 3000:80 -n ${NAMESPACE} &
kubectl port-forward svc/todo-backend 8000:8000 -n ${NAMESPACE} &

# Test endpoints
sleep 3
echo "=== Health Check Tests ==="
echo "Frontend:"
curl -s http://localhost:3000/api/health | jq . || echo "Frontend not responding"

echo "Backend:"
curl -s http://localhost:8000/health | jq . || echo "Backend not responding"

# Cleanup port forwards
pkill -f "port-forward"
```

### Internal DNS Resolution Test

```bash
# Test DNS resolution from within the cluster
kubectl run dns-test --rm -it --restart=Never \
  --image=busybox:1.36 \
  -n ${NAMESPACE} \
  -- nslookup todo-backend

kubectl run dns-test --rm -it --restart=Never \
  --image=busybox:1.36 \
  -n ${NAMESPACE} \
  -- nslookup todo-frontend
```

---

## Step 4: Collect Logs for Errors

### Pod Logs Collection

```bash
# =============================================================================
# LOG COLLECTION
# =============================================================================

# Frontend logs (all pods)
echo "=== Frontend Logs ==="
kubectl logs -l app.kubernetes.io/component=frontend -n ${NAMESPACE} --tail=100

# Backend logs (all pods)
echo "=== Backend Logs ==="
kubectl logs -l app.kubernetes.io/component=backend -n ${NAMESPACE} --tail=100

# Logs from specific pod
kubectl logs <pod-name> -n ${NAMESPACE} --tail=200

# Follow logs in real-time
kubectl logs -f deployment/todo-frontend -n ${NAMESPACE}
kubectl logs -f deployment/todo-backend -n ${NAMESPACE}

# Previous container logs (after restart)
kubectl logs <pod-name> -n ${NAMESPACE} --previous
```

### Error Detection Script

```bash
#!/bin/bash
# scripts/collect-errors.sh

NAMESPACE=${1:-todo-dev}
OUTPUT_DIR="./logs/${NAMESPACE}-$(date +%Y%m%d-%H%M%S)"

mkdir -p ${OUTPUT_DIR}

echo "=== Collecting Deployment Logs ==="

# Collect pod descriptions
echo "Collecting pod descriptions..."
kubectl describe pods -n ${NAMESPACE} > "${OUTPUT_DIR}/pod-descriptions.txt"

# Collect pod logs
echo "Collecting pod logs..."
for pod in $(kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}'); do
  echo "  - ${pod}"
  kubectl logs ${pod} -n ${NAMESPACE} --tail=500 > "${OUTPUT_DIR}/${pod}.log" 2>&1

  # Also get previous logs if container restarted
  kubectl logs ${pod} -n ${NAMESPACE} --previous --tail=500 > "${OUTPUT_DIR}/${pod}-previous.log" 2>&1
done

# Collect events
echo "Collecting cluster events..."
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' > "${OUTPUT_DIR}/events.txt"

# Collect service info
echo "Collecting service info..."
kubectl describe services -n ${NAMESPACE} > "${OUTPUT_DIR}/services.txt"

# Search for errors in logs
echo ""
echo "=== Error Summary ==="
echo "Searching for errors in logs..."

grep -rn -i "error\|exception\|fatal\|panic\|failed" ${OUTPUT_DIR}/*.log | head -50

echo ""
echo "Logs collected in: ${OUTPUT_DIR}"
```

### Event Monitoring

```bash
# Get recent events sorted by time
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n ${NAMESPACE} -w

# Filter warning/error events
kubectl get events -n ${NAMESPACE} --field-selector type!=Normal

# Get events for specific pod
kubectl get events -n ${NAMESPACE} --field-selector involvedObject.name=<pod-name>
```

---

## Step 5: Structured Deployment Status Output

### Deployment Status Script

```bash
#!/bin/bash
# scripts/deployment-status.sh
# Outputs structured deployment status in JSON format

NAMESPACE=${1:-todo-dev}
RELEASE_NAME=${2:-todo-app}

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================================="
echo "  KUBERNETES DEPLOYMENT STATUS REPORT"
echo "  Namespace: ${NAMESPACE}"
echo "  Release: ${RELEASE_NAME}"
echo "  Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "============================================================================="

# -----------------------------------------------------------------------------
# 1. Helm Release Status
# -----------------------------------------------------------------------------
echo ""
echo "=== HELM RELEASE STATUS ==="
HELM_STATUS=$(helm status ${RELEASE_NAME} -n ${NAMESPACE} -o json 2>/dev/null)

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Release found${NC}"
  echo "   Status: $(echo ${HELM_STATUS} | jq -r '.info.status')"
  echo "   Revision: $(echo ${HELM_STATUS} | jq -r '.version')"
  echo "   Last Deployed: $(echo ${HELM_STATUS} | jq -r '.info.last_deployed')"
else
  echo -e "${RED}❌ Release not found${NC}"
fi

# -----------------------------------------------------------------------------
# 2. Pod Status Summary
# -----------------------------------------------------------------------------
echo ""
echo "=== POD STATUS ==="

PODS_JSON=$(kubectl get pods -n ${NAMESPACE} -o json)
TOTAL_PODS=$(echo ${PODS_JSON} | jq '.items | length')
RUNNING_PODS=$(echo ${PODS_JSON} | jq '[.items[] | select(.status.phase == "Running")] | length')
READY_PODS=$(echo ${PODS_JSON} | jq '[.items[] | select(.status.conditions[]? | select(.type == "Ready" and .status == "True"))] | length')
FAILED_PODS=$(echo ${PODS_JSON} | jq '[.items[] | select(.status.phase == "Failed")] | length')
PENDING_PODS=$(echo ${PODS_JSON} | jq '[.items[] | select(.status.phase == "Pending")] | length')

echo "   Total Pods: ${TOTAL_PODS}"
echo "   Running: ${RUNNING_PODS}"
echo "   Ready: ${READY_PODS}"
echo "   Pending: ${PENDING_PODS}"
echo "   Failed: ${FAILED_PODS}"

if [ "${READY_PODS}" -eq "${TOTAL_PODS}" ] && [ "${TOTAL_PODS}" -gt 0 ]; then
  echo -e "   ${GREEN}✅ All pods healthy${NC}"
  POD_STATUS="healthy"
else
  echo -e "   ${YELLOW}⚠️  Some pods not ready${NC}"
  POD_STATUS="degraded"
fi

# Pod details table
echo ""
echo "   Pod Details:"
echo "   -----------------------------------------------------------------------"
printf "   %-40s %-10s %-8s %-10s\n" "NAME" "STATUS" "READY" "RESTARTS"
echo "   -----------------------------------------------------------------------"

echo ${PODS_JSON} | jq -r '.items[] |
  "\(.metadata.name) \(.status.phase) \(.status.conditions[]? | select(.type=="Ready") | .status) \(.status.containerStatuses[]?.restartCount // 0)"
' | while read name phase ready restarts; do
  printf "   %-40s %-10s %-8s %-10s\n" "${name}" "${phase}" "${ready}" "${restarts}"
done

# -----------------------------------------------------------------------------
# 3. Deployment Status
# -----------------------------------------------------------------------------
echo ""
echo "=== DEPLOYMENT STATUS ==="

kubectl get deployments -n ${NAMESPACE} -o json | jq -r '.items[] |
  "   \(.metadata.name):
      Desired: \(.spec.replicas)
      Current: \(.status.replicas // 0)
      Ready: \(.status.readyReplicas // 0)
      Available: \(.status.availableReplicas // 0)
      "
'

# -----------------------------------------------------------------------------
# 4. Service Status
# -----------------------------------------------------------------------------
echo ""
echo "=== SERVICE STATUS ==="

kubectl get services -n ${NAMESPACE} -o json | jq -r '.items[] |
  "   \(.metadata.name):
      Type: \(.spec.type)
      ClusterIP: \(.spec.clusterIP)
      Ports: \(.spec.ports | map("\(.port):\(.targetPort)") | join(", "))
      "
'

# -----------------------------------------------------------------------------
# 5. Endpoint Status
# -----------------------------------------------------------------------------
echo ""
echo "=== ENDPOINT STATUS ==="

ENDPOINTS_JSON=$(kubectl get endpoints -n ${NAMESPACE} -o json)
ENDPOINTS_OK=true

echo ${ENDPOINTS_JSON} | jq -r '.items[] |
  "   \(.metadata.name): \(if .subsets then (.subsets[].addresses | length | tostring) + " endpoints" else "NO ENDPOINTS" end)"
' | while read line; do
  echo "${line}"
  if [[ "${line}" == *"NO ENDPOINTS"* ]]; then
    ENDPOINTS_OK=false
  fi
done

# -----------------------------------------------------------------------------
# 6. Secrets Status
# -----------------------------------------------------------------------------
echo ""
echo "=== SECRETS STATUS ==="

kubectl get secrets -n ${NAMESPACE} -o json | jq -r '.items[] |
  select(.metadata.name | test("todo|app")) |
  "   \(.metadata.name): \(.data | keys | join(", "))"
'

# -----------------------------------------------------------------------------
# 7. Recent Events (Warnings/Errors)
# -----------------------------------------------------------------------------
echo ""
echo "=== RECENT ISSUES (Last 10 Warning/Error Events) ==="

WARNINGS=$(kubectl get events -n ${NAMESPACE} --field-selector type!=Normal -o json | jq -r '
  .items | sort_by(.lastTimestamp) | reverse | .[0:10] | .[] |
  "   [\(.lastTimestamp)] \(.reason): \(.message)"
')

if [ -z "${WARNINGS}" ]; then
  echo -e "   ${GREEN}✅ No warnings or errors${NC}"
  ISSUES_FOUND=false
else
  echo -e "${YELLOW}${WARNINGS}${NC}"
  ISSUES_FOUND=true
fi

# -----------------------------------------------------------------------------
# 8. Final Status Summary
# -----------------------------------------------------------------------------
echo ""
echo "============================================================================="
echo "  DEPLOYMENT SUMMARY"
echo "============================================================================="

# Determine overall status
if [ "${POD_STATUS}" = "healthy" ] && [ "${ISSUES_FOUND}" = false ]; then
  OVERALL_STATUS="SUCCESS"
  STATUS_COLOR="${GREEN}"
  STATUS_ICON="✅"
elif [ "${FAILED_PODS}" -gt 0 ]; then
  OVERALL_STATUS="FAILED"
  STATUS_COLOR="${RED}"
  STATUS_ICON="❌"
else
  OVERALL_STATUS="DEGRADED"
  STATUS_COLOR="${YELLOW}"
  STATUS_ICON="⚠️"
fi

echo -e "  Status: ${STATUS_COLOR}${STATUS_ICON} ${OVERALL_STATUS}${NC}"
echo "  Pods: ${READY_PODS}/${TOTAL_PODS} ready"
echo "  Deployments: $(kubectl get deployments -n ${NAMESPACE} --no-headers | wc -l)"
echo "  Services: $(kubectl get services -n ${NAMESPACE} --no-headers | wc -l)"
echo ""

# -----------------------------------------------------------------------------
# 9. Access URLs (for Minikube)
# -----------------------------------------------------------------------------
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
  echo "=== ACCESS URLS (Minikube) ==="
  echo "   Frontend: $(minikube service todo-frontend -n ${NAMESPACE} --url 2>/dev/null || echo 'N/A')"
  echo "   Backend: $(minikube service todo-backend -n ${NAMESPACE} --url 2>/dev/null || echo 'N/A')"
  echo ""
fi

echo "============================================================================="

# Return exit code based on status
if [ "${OVERALL_STATUS}" = "SUCCESS" ]; then
  exit 0
elif [ "${OVERALL_STATUS}" = "DEGRADED" ]; then
  exit 1
else
  exit 2
fi
```

### JSON Output Format

```bash
#!/bin/bash
# scripts/deployment-status-json.sh
# Outputs deployment status as JSON for programmatic use

NAMESPACE=${1:-todo-dev}
RELEASE_NAME=${2:-todo-app}

# Collect all data
HELM_STATUS=$(helm status ${RELEASE_NAME} -n ${NAMESPACE} -o json 2>/dev/null || echo '{"info":{"status":"not-found"}}')
PODS=$(kubectl get pods -n ${NAMESPACE} -o json)
SERVICES=$(kubectl get services -n ${NAMESPACE} -o json)
DEPLOYMENTS=$(kubectl get deployments -n ${NAMESPACE} -o json)
EVENTS=$(kubectl get events -n ${NAMESPACE} --field-selector type!=Normal -o json)

# Calculate metrics
TOTAL_PODS=$(echo ${PODS} | jq '.items | length')
READY_PODS=$(echo ${PODS} | jq '[.items[] | select(.status.conditions[]? | select(.type == "Ready" and .status == "True"))] | length')
FAILED_PODS=$(echo ${PODS} | jq '[.items[] | select(.status.phase == "Failed")] | length')
WARNING_COUNT=$(echo ${EVENTS} | jq '.items | length')

# Determine status
if [ "${READY_PODS}" -eq "${TOTAL_PODS}" ] && [ "${TOTAL_PODS}" -gt 0 ] && [ "${WARNING_COUNT}" -eq 0 ]; then
  STATUS="success"
elif [ "${FAILED_PODS}" -gt 0 ]; then
  STATUS="failed"
else
  STATUS="degraded"
fi

# Output JSON
cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "namespace": "${NAMESPACE}",
  "release": "${RELEASE_NAME}",
  "status": "${STATUS}",
  "summary": {
    "pods": {
      "total": ${TOTAL_PODS},
      "ready": ${READY_PODS},
      "failed": ${FAILED_PODS}
    },
    "deployments": $(echo ${DEPLOYMENTS} | jq '.items | length'),
    "services": $(echo ${SERVICES} | jq '.items | length'),
    "warnings": ${WARNING_COUNT}
  },
  "pods": $(echo ${PODS} | jq '[.items[] | {
    name: .metadata.name,
    status: .status.phase,
    ready: (.status.conditions[]? | select(.type=="Ready") | .status),
    restarts: (.status.containerStatuses[]?.restartCount // 0)
  }]'),
  "services": $(echo ${SERVICES} | jq '[.items[] | {
    name: .metadata.name,
    type: .spec.type,
    clusterIP: .spec.clusterIP,
    ports: [.spec.ports[] | "\(.port):\(.targetPort)"]
  }]'),
  "issues": $(echo ${EVENTS} | jq '[.items[] | {
    timestamp: .lastTimestamp,
    reason: .reason,
    message: .message,
    object: .involvedObject.name
  }]')
}
EOF
```

---

## Complete Deployment Workflow

### Full Deployment Script

```bash
#!/bin/bash
# scripts/deploy-and-validate.sh
# Complete deployment and validation workflow

set -e

# Configuration
DEPLOY_ENV=${1:-dev}
NAMESPACE="todo-${DEPLOY_ENV}"
RELEASE_NAME="todo-app"
CHART_PATH="./helm/todo-app"
VALUES_FILE="${CHART_PATH}/values-${DEPLOY_ENV}.yaml"

echo "============================================================================="
echo "  KUBERNETES DEPLOYMENT WORKFLOW"
echo "  Environment: ${DEPLOY_ENV}"
echo "  Namespace: ${NAMESPACE}"
echo "============================================================================="

# -----------------------------------------------------------------------------
# Step 0: Pre-flight checks
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 0: Pre-flight Checks ==="

# Check Minikube status
if ! minikube status &> /dev/null; then
  echo "❌ Minikube is not running. Starting..."
  minikube start
fi
echo "✅ Minikube is running"

# Check Helm chart
if ! helm lint ${CHART_PATH} -f ${VALUES_FILE} &> /dev/null; then
  echo "❌ Helm chart validation failed"
  helm lint ${CHART_PATH} -f ${VALUES_FILE}
  exit 1
fi
echo "✅ Helm chart is valid"

# Check images exist
if ! minikube image list | grep -q "todo-frontend"; then
  echo "⚠️  Warning: todo-frontend image not found in Minikube"
fi
if ! minikube image list | grep -q "todo-backend"; then
  echo "⚠️  Warning: todo-backend image not found in Minikube"
fi

# -----------------------------------------------------------------------------
# Step 1: Deploy with Helm
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 1: Helm Install/Upgrade ==="

helm upgrade --install ${RELEASE_NAME} ${CHART_PATH} \
  -f ${VALUES_FILE} \
  -n ${NAMESPACE} \
  --create-namespace \
  --wait \
  --timeout 5m \
  --atomic

echo "✅ Helm deployment completed"

# -----------------------------------------------------------------------------
# Step 2: Verify Pods
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 2: Verify Pod Status ==="

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=${RELEASE_NAME} \
  -n ${NAMESPACE} \
  --timeout=120s

echo "✅ All pods are ready"
kubectl get pods -n ${NAMESPACE}

# -----------------------------------------------------------------------------
# Step 3: Check Services
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 3: Verify Services ==="

kubectl get services -n ${NAMESPACE}

# Verify endpoints have IPs
for svc in todo-frontend todo-backend; do
  ENDPOINTS=$(kubectl get endpoints ${svc} -n ${NAMESPACE} -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
  if [ -n "${ENDPOINTS}" ]; then
    echo "✅ ${svc}: ${ENDPOINTS}"
  else
    echo "❌ ${svc}: No endpoints"
  fi
done

# -----------------------------------------------------------------------------
# Step 4: Health Checks
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 4: Health Checks ==="

# Get Minikube service URLs
FRONTEND_URL=$(minikube service todo-frontend -n ${NAMESPACE} --url 2>/dev/null || echo "")
BACKEND_URL=$(minikube service todo-backend -n ${NAMESPACE} --url 2>/dev/null || echo "")

if [ -n "${BACKEND_URL}" ]; then
  echo "Testing backend health: ${BACKEND_URL}/health"
  if curl -sf "${BACKEND_URL}/health" > /dev/null 2>&1; then
    echo "✅ Backend health check passed"
  else
    echo "⚠️  Backend health check failed (may need more time)"
  fi
fi

if [ -n "${FRONTEND_URL}" ]; then
  echo "Testing frontend: ${FRONTEND_URL}"
  if curl -sf "${FRONTEND_URL}" > /dev/null 2>&1; then
    echo "✅ Frontend is responding"
  else
    echo "⚠️  Frontend not responding (may need more time)"
  fi
fi

# -----------------------------------------------------------------------------
# Step 5: Collect Any Errors
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 5: Check for Issues ==="

WARNINGS=$(kubectl get events -n ${NAMESPACE} --field-selector type!=Normal --no-headers 2>/dev/null | wc -l)
if [ "${WARNINGS}" -gt 0 ]; then
  echo "⚠️  Found ${WARNINGS} warning events:"
  kubectl get events -n ${NAMESPACE} --field-selector type!=Normal --sort-by='.lastTimestamp' | tail -5
else
  echo "✅ No warning events found"
fi

# -----------------------------------------------------------------------------
# Final Status
# -----------------------------------------------------------------------------
echo ""
echo "============================================================================="
echo "  DEPLOYMENT COMPLETE"
echo "============================================================================="
echo ""
echo "  Namespace: ${NAMESPACE}"
echo "  Release: ${RELEASE_NAME}"
echo ""
echo "  Access URLs:"
echo "    Frontend: ${FRONTEND_URL:-'Use port-forward'}"
echo "    Backend: ${BACKEND_URL:-'Use port-forward'}"
echo ""
echo "  Useful Commands:"
echo "    kubectl get pods -n ${NAMESPACE}"
echo "    kubectl logs -f deployment/todo-frontend -n ${NAMESPACE}"
echo "    kubectl logs -f deployment/todo-backend -n ${NAMESPACE}"
echo ""
echo "============================================================================="
```

---

## Quick Reference Commands

```bash
# =============================================================================
# QUICK REFERENCE
# =============================================================================

# Deploy
helm upgrade --install todo-app ./helm/todo-app -f ./helm/todo-app/values-dev.yaml -n todo-dev --create-namespace --wait

# Check status
kubectl get all -n todo-dev

# View logs
kubectl logs -f deployment/todo-frontend -n todo-dev
kubectl logs -f deployment/todo-backend -n todo-dev

# Port forward
kubectl port-forward svc/todo-frontend 3000:80 -n todo-dev
kubectl port-forward svc/todo-backend 8000:8000 -n todo-dev

# Get Minikube URLs
minikube service list -n todo-dev

# Rollback
helm rollback todo-app 1 -n todo-dev

# Uninstall
helm uninstall todo-app -n todo-dev

# Delete namespace (cleanup)
kubectl delete namespace todo-dev
```

---

## Troubleshooting Guide

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Pods stuck in `Pending` | No node resources | Check `kubectl describe pod <name>`, scale down or increase resources |
| Pods in `CrashLoopBackOff` | Container keeps restarting | Check logs: `kubectl logs <pod> --previous` |
| `ImagePullBackOff` | Can't pull image | Verify image name, check `imagePullPolicy: IfNotPresent` for Minikube |
| Service has no endpoints | Selector mismatch | Compare service selector with pod labels |
| Health checks failing | App not ready | Increase `initialDelaySeconds`, check app startup logs |
| Helm upgrade fails | Immutable field changed | Delete and reinstall, or use `--force` carefully |

### Debug Commands

```bash
# Describe pod for detailed status
kubectl describe pod <pod-name> -n todo-dev

# Get pod events
kubectl get events --field-selector involvedObject.name=<pod-name> -n todo-dev

# Shell into running pod
kubectl exec -it <pod-name> -n todo-dev -- /bin/sh

# Test DNS resolution
kubectl run debug --rm -it --image=busybox -n todo-dev -- nslookup todo-backend

# Check resource usage
kubectl top pods -n todo-dev
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-28 | Initial release with full deployment and validation workflow |

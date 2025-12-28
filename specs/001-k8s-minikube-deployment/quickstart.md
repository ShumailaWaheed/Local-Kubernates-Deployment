# Quickstart: Phase IV - Local Kubernetes Deployment

**Feature**: 001-k8s-minikube-deployment
**Date**: 2025-12-24
**Target**: Developers deploying Todo AI Chatbot to Minikube

## Prerequisites

Before starting, ensure you have:

- ✅ Docker Desktop installed and running (Windows)
- ✅ Minikube installed (`minikube version`)
- ✅ Helm 3.x installed (`helm version`)
- ✅ kubectl installed (`kubectl version --client`)
- ✅ Phase III application code ready
- ✅ Neon PostgreSQL URL and OpenAI API key available

---

## Quick Deployment (10 Steps)

### 1. Start Minikube

```bash
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --kubernetes-version=v1.28.0
```

**Expected**: Cluster starts in 2-3 minutes, `kubectl cluster-info` shows running cluster

---

### 2. Create Namespace

```bash
kubectl create namespace todo-app
```

---

### 3. Create Secrets

```bash
# Database connection (replace with your Neon PostgreSQL URL)
kubectl create secret generic db-secret \
  --from-literal=DATABASE_URL='postgresql://user:pass@host.neon.tech/db' \
  --namespace=todo-app

# OpenAI API key (replace with your key)
kubectl create secret generic openai-secret \
  --from-literal=OPENAI_API_KEY='sk-...' \
  --namespace=todo-app
```

**Verify**:
```bash
kubectl get secrets -n todo-app
```

---

### 4. Build Frontend Image

```bash
cd frontend
docker build -t todo-frontend:latest -f ../docker/frontend/Dockerfile .
minikube image load todo-frontend:latest
```

---

### 5. Build Backend Image

```bash
cd backend
docker build -t todo-backend:latest -f ../docker/backend/Dockerfile .
minikube image load todo-backend:latest
```

---

### 6. Install Backend Helm Chart

```bash
helm install todo-backend ./helm/backend-chart \
  --namespace=todo-app \
  --wait --timeout=5m
```

**Verify**:
```bash
kubectl get pods -n todo-app
# Expected: 2 backend pods in Running state
```

---

### 7. Install Frontend Helm Chart

```bash
helm install todo-frontend ./helm/frontend-chart \
  --namespace=todo-app \
  --wait --timeout=5m
```

**Verify**:
```bash
kubectl get pods -n todo-app
# Expected: 1 frontend pod + 2 backend pods in Running state
```

---

### 8. Get Frontend URL

```bash
minikube service todo-frontend --namespace=todo-app --url
```

**Expected Output**: `http://192.168.49.2:30080` (or similar)

---

### 9. Access Chatbot

Open the URL from step 8 in your browser. You should see the Todo AI Chatbot UI.

---

### 10. Test Functionality

Try these commands in the chatbot:
- "Add task: Buy groceries"
- "List all tasks"
- "Mark task 1 as complete"
- "Delete task 1"

**Expected**: All Phase III functionality works identically

---

## Validation Tests

### Test 1: Pod Restart Recovery

```bash
# Delete a backend pod
kubectl delete pod -n todo-app -l app=todo-backend --force --grace-period=0 | head -1

# Wait 30 seconds
sleep 30

# Verify new pod is running
kubectl get pods -n todo-app
# Expected: 2 backend pods in Running state

# Test chatbot still works
# Expected: No data loss, chat history intact
```

---

### Test 2: Backend Scaling

```bash
# Scale to 3 replicas
helm upgrade todo-backend ./helm/backend-chart \
  --set replicaCount=3 \
  --namespace=todo-app

# Verify 3 pods running
kubectl get pods -n todo-app -l app=todo-backend
# Expected: 3 backend pods in Running state

# Test chatbot with concurrent users
# Expected: Load distributed across replicas
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n todo-app

# Check logs
kubectl logs <pod-name> -n todo-app
```

**Common Issues**:
- Missing secrets: Verify secrets exist with `kubectl get secrets -n todo-app`
- Image not found: Reload image with `minikube image load <image>:latest`
- Resource limits: Check Minikube resources with `kubectl top nodes`

---

### Database Connection Failures

```bash
# Check backend logs for connection errors
kubectl logs -l app=todo-backend -n todo-app --tail=50

# Verify secret contains correct URL
kubectl get secret db-secret -n todo-app -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

**Expected Behavior** (per FR-033, FR-034, FR-035):
- Backend logs show retry attempts with exponential backoff
- Health check `/health/ready` returns 503
- Frontend shows "Service Unavailable" errors
- Pods stay running (not crashing)

---

### Frontend Can't Reach Backend

```bash
# Verify backend service exists
kubectl get svc todo-backend -n todo-app

# Test backend connectivity from frontend pod
kubectl exec -it <frontend-pod-name> -n todo-app -- curl http://todo-backend:8000/health/live
# Expected: HTTP 200 OK
```

---

## Cleanup

```bash
# Uninstall Helm releases
helm uninstall todo-frontend --namespace=todo-app
helm uninstall todo-backend --namespace=todo-app

# Delete secrets
kubectl delete secret db-secret openai-secret --namespace=todo-app

# Delete namespace
kubectl delete namespace todo-app

# Stop Minikube
minikube stop
```

---

## AI DevOps Tools (Optional)

If you have Docker AI, kubectl-ai, or kagent installed:

### Docker AI (Gordon)

```bash
# Generate Dockerfile (if not already created)
docker ai generate dockerfile --language=python --framework=fastapi
```

### kubectl-ai

```bash
# Inspect pods with natural language
kubectl-ai "Show me all pods in todo-app namespace with their status"

# Debug issues
kubectl-ai "Why is pod todo-backend-xyz not starting?"
```

### kagent

```bash
# Analyze deployment health
kagent analyze deployment todo-backend --namespace=todo-app

# Get recommendations
kagent recommend --namespace=todo-app
```

---

## Next Steps

After successful deployment:

1. ✅ Verify all acceptance criteria (see spec.md Success Criteria section)
2. ✅ Run stability tests (1 hour continuous operation)
3. ✅ Document AI DevOps tool usage
4. ✅ Validate constitutional compliance
5. ✅ Proceed to `/sp.tasks` for implementation task breakdown

---

## Reference

- **Specification**: [spec.md](./spec.md)
- **Implementation Plan**: [plan.md](./plan.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **Contracts**: [contracts/](./contracts/)

**Quickstart Status**: ✅ COMPLETE

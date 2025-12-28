# Research: Phase IV - Local Kubernetes Deployment

**Feature**: 001-k8s-minikube-deployment
**Date**: 2025-12-24
**Status**: Complete

## Research Objective

Identify best practices, patterns, and technical decisions for deploying the Phase III Todo AI Chatbot to local Kubernetes (Minikube) using Docker Desktop, Helm charts, and AI-assisted DevOps tooling.

---

## 1. Docker Containerization Best Practices

### Decision: Multi-Stage Docker Builds

**Rationale**:
- Reduces final image size by separating build and runtime dependencies
- Improves security by excluding build tools from production images
- Faster image pulls and deployments

**Pattern for Next.js Frontend**:
```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Builder
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Runner
FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV production
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
EXPOSE 3000
CMD ["npm", "start"]
```

**Pattern for FastAPI Backend**:
```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runner
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Alternatives Considered**:
- Single-stage builds: Rejected (larger image size, security concerns)
- Alpine-based images: Selected (smaller footprint, faster pulls)
- Debian-based images: Rejected (larger size, unnecessary for stateless apps)

---

## 2. Kubernetes Health Checks

### Decision: Separate Liveness and Readiness Probes

**Rationale**:
- **Liveness probe**: Detects when pod is stuck and needs restart
- **Readiness probe**: Detects when pod is temporarily unable to serve traffic (e.g., database unavailable)
- Separating probes prevents unnecessary pod restarts during temporary failures

**Pattern**:
```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
```

**Implementation Requirements**:
- `/health/live`: Always returns 200 OK (checks if process is alive)
- `/health/ready`: Returns 200 OK only if database connection is healthy (FR-035)
- When database is unavailable: liveness passes, readiness fails (pod marked unhealthy but not restarted)

**Alternatives Considered**:
- Single health check endpoint: Rejected (doesn't distinguish between restart-worthy failures vs. temporary unavailability)
- TCP probes: Rejected (less informative than HTTP checks)

---

## 3. Database Connection Retry Strategy

### Decision: Exponential Backoff with Jitter

**Rationale**:
- Prevents thundering herd problem when database restarts
- Jitter prevents synchronized retry storms from multiple replicas
- Aligns with FR-033 (exponential backoff requirement)

**Pattern**:
```python
import time
import random
from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError

def connect_with_retry(database_url, max_retries=10):
    for attempt in range(max_retries):
        try:
            engine = create_engine(database_url)
            engine.connect()
            return engine
        except OperationalError as e:
            if attempt == max_retries - 1:
                raise

            # Exponential backoff: 2^attempt seconds, max 60 seconds
            wait_time = min(2 ** attempt, 60)

            # Add jitter: random 0-25% of wait time
            jitter = random.uniform(0, wait_time * 0.25)
            total_wait = wait_time + jitter

            print(f"Database connection failed (attempt {attempt+1}/{max_retries}). "
                  f"Retrying in {total_wait:.2f} seconds...")
            time.sleep(total_wait)
```

**Backoff Schedule**:
- Attempt 1: 1 second (+ jitter)
- Attempt 2: 2 seconds (+ jitter)
- Attempt 3: 4 seconds (+ jitter)
- Attempt 4: 8 seconds (+ jitter)
- Attempt 5+: 60 seconds (+ jitter)

**Alternatives Considered**:
- Fixed retry interval: Rejected (doesn't adapt to sustained outages)
- Linear backoff: Rejected (too aggressive for database reconnection)
- No jitter: Rejected (risk of synchronized retry storms)

---

## 4. Secrets Management in Kubernetes

### Decision: Kubernetes Secrets with Environment Variable Injection

**Rationale**:
- Native Kubernetes solution (no external dependencies)
- Secrets stored encrypted at rest in etcd
- Easy to update without rebuilding images
- Aligns with FR-018, FR-019, FR-022, FR-023

**Pattern (Helm values.yaml)**:
```yaml
secrets:
  databaseUrl:
    name: db-secret
    key: DATABASE_URL
  openaiApiKey:
    name: openai-secret
    key: OPENAI_API_KEY
```

**Pattern (Helm Deployment template)**:
```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: {{ .Values.secrets.databaseUrl.name }}
        key: {{ .Values.secrets.databaseUrl.key }}
  - name: OPENAI_API_KEY
    valueFrom:
      secretKeyRef:
        name: {{ .Values.secrets.openaiApiKey.name }}
        key: {{ .Values.secrets.openaiApiKey.key }}
```

**Secret Creation (NOT in Git)**:
```bash
kubectl create secret generic db-secret \
  --from-literal=DATABASE_URL='postgresql://user:pass@host/db' \
  --namespace=todo-app

kubectl create secret generic openai-secret \
  --from-literal=OPENAI_API_KEY='sk-...' \
  --namespace=todo-app
```

**Startup Validation (FR-023)**:
```python
import os
import sys

required_secrets = ['DATABASE_URL', 'OPENAI_API_KEY']

for secret in required_secrets:
    value = os.getenv(secret)
    if not value:
        print(f"ERROR: Required secret {secret} is missing", file=sys.stderr)
        sys.exit(1)
    if len(value) < 10:  # Basic format validation
        print(f"ERROR: Secret {secret} appears invalid (too short)", file=sys.stderr)
        sys.exit(1)

print("✅ All required secrets validated")
```

**Alternatives Considered**:
- External secrets operator: Rejected (adds complexity for local deployment)
- ConfigMaps: Rejected (not designed for sensitive data)
- Mounted secret files: Rejected (environment variables simpler for this use case)

---

## 5. Helm Chart Structure

### Decision: Separate Charts for Frontend and Backend

**Rationale**:
- Independent versioning and release cycles
- Clearer separation of concerns
- Easier to scale components independently
- Aligns with FR-014, FR-015

**Chart Structure**:
```text
helm/
├── backend-chart/
│   ├── Chart.yaml          # Metadata (name, version, description)
│   ├── values.yaml         # Default configuration
│   └── templates/
│       ├── deployment.yaml # Backend Deployment
│       ├── service.yaml    # Backend ClusterIP Service
│       └── _helpers.tpl    # Template helpers
└── frontend-chart/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml # Frontend Deployment
        ├── service.yaml    # Frontend NodePort Service
        └── _helpers.tpl
```

**values.yaml Pattern**:
```yaml
replicaCount: 2

image:
  repository: todo-backend
  tag: latest
  pullPolicy: Never  # For Minikube (images loaded locally)

service:
  type: ClusterIP
  port: 8000

resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

secrets:
  databaseUrl:
    name: db-secret
    key: DATABASE_URL
  openaiApiKey:
    name: openai-secret
    key: OPENAI_API_KEY
```

**Alternatives Considered**:
- Umbrella chart (single chart for both): Rejected (tight coupling, harder to version independently)
- Separate namespaces: Rejected (adds complexity for local deployment)

---

## 6. Minikube Configuration

### Decision: Docker Driver with Resource Allocation

**Rationale**:
- Docker driver is most reliable on Windows with Docker Desktop
- Resource allocation prevents pod evictions due to resource pressure
- Aligns with FR-029, FR-030

**Recommended Minikube Start**:
```bash
minikube start \
  --driver=docker \
  --cpus=4 \
  --memory=8192 \
  --kubernetes-version=v1.28.0 \
  --addons=metrics-server
```

**Configuration Explanation**:
- `--driver=docker`: Use Docker Desktop as container runtime (constitutional requirement)
- `--cpus=4`: Allocate 4 CPU cores (minimum for stable operation)
- `--memory=8192`: Allocate 8GB RAM (sufficient for frontend + backend + overhead)
- `--kubernetes-version=v1.28.0`: Lock to tested Kubernetes version
- `--addons=metrics-server`: Enable resource monitoring (`kubectl top`)

**Alternatives Considered**:
- Hyperkit/Hyper-V drivers: Rejected (less reliable on Windows, Docker driver mandated)
- Lower resource allocation: Rejected (risk of pod evictions under load)

---

## 7. Service Exposure Strategy

### Decision: Backend ClusterIP, Frontend NodePort

**Rationale**:
- Backend doesn't need external access (FR-010)
- Frontend must be externally accessible (FR-009)
- NodePort simplest for Minikube (LoadBalancer requires MetalLB addon)

**Pattern (Backend Service)**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: todo-backend
spec:
  type: ClusterIP
  selector:
    app: todo-backend
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
```

**Pattern (Frontend Service)**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: todo-frontend
spec:
  type: NodePort
  selector:
    app: todo-frontend
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30080  # Optional: specify fixed NodePort
```

**Access Frontend**:
```bash
minikube service todo-frontend --namespace=todo-app --url
```

**Alternatives Considered**:
- LoadBalancer for frontend: Rejected (requires MetalLB addon, adds complexity)
- Ingress: Rejected (overkill for single-frontend deployment)

---

## 8. AI-Assisted DevOps Tooling

### Decision: Docker AI (Gordon) → kubectl-ai → kagent Priority

**Rationale**:
- Docker AI (Gordon) specializes in Dockerfile generation
- kubectl-ai provides natural language Kubernetes operations
- kagent offers deployment health analysis
- Aligns with FR-036, FR-037, FR-038, FR-039

**Usage Patterns**:

**Docker AI (Gordon)**:
```bash
# Generate Dockerfile (if Gordon available)
docker ai generate dockerfile \
  --language=python \
  --framework=fastapi \
  --output=docker/backend/Dockerfile
```

**kubectl-ai**:
```bash
# Natural language pod inspection
kubectl-ai "Show me all pods in todo-app namespace with their status and restarts"

# Natural language debugging
kubectl-ai "Why is pod todo-backend-xyz not starting?"

# Natural language scaling
kubectl-ai "Scale todo-backend deployment to 3 replicas"
```

**kagent**:
```bash
# Analyze deployment health
kagent analyze deployment todo-backend --namespace=todo-app

# Diagnose pod issues
kagent diagnose pod todo-backend-xyz --namespace=todo-app

# Recommend optimizations
kagent recommend --namespace=todo-app
```

**Fallback (if tools unavailable)**:
- Use Claude Code to generate Dockerfiles
- Use standard kubectl commands with manual analysis
- Document fallback usage (still counts toward 80% if AI-assisted generation used)

**Alternatives Considered**:
- Manual Dockerfile authoring: Rejected (violates constitutional principle II)
- ChatGPT for operations: Rejected (not integrated with kubectl)

---

## 9. Pod Failure Recovery Strategy

### Decision: Kubernetes Native Self-Healing

**Rationale**:
- Deployment controller automatically recreates failed pods (FR-032)
- No custom operators or CRDs needed
- Proven reliability pattern
- Aligns with User Story P2

**Configuration**:
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      restartPolicy: Always
      containers:
        - name: backend
          # ... container spec ...
```

**Recovery Behavior**:
1. Pod fails (crash, OOMKill, health check failure)
2. Kubernetes detects failure within seconds
3. Deployment controller creates new pod
4. New pod starts and passes health checks
5. Failed pod is terminated
6. Target: Recovery within 30 seconds (SC-004)

**Alternatives Considered**:
- Custom restart scripts: Rejected (Kubernetes native solution sufficient)
- StatefulSets: Rejected (application is stateless)

---

## 10. Resource Requests and Limits

### Decision: Conservative Requests, Generous Limits

**Rationale**:
- Requests guarantee minimum resources (prevents pod eviction)
- Limits prevent resource hogging (protects other pods)
- Conservative requests ensure pod scheduling on resource-constrained Minikube

**Recommended Values**:

**Backend**:
```yaml
resources:
  requests:
    memory: "256Mi"  # Minimum to run FastAPI + OpenAI SDK
    cpu: "250m"      # 0.25 CPU cores
  limits:
    memory: "512Mi"  # Allow burst for concurrent requests
    cpu: "500m"      # 0.5 CPU cores
```

**Frontend**:
```yaml
resources:
  requests:
    memory: "128Mi"  # Minimum to run Next.js SSR
    cpu: "100m"      # 0.1 CPU cores
  limits:
    memory: "256Mi"  # Allow burst for SSR rendering
    cpu: "200m"      # 0.2 CPU cores
```

**Total Resource Budget** (2 backend replicas + 1 frontend):
- Memory: 256×2 + 128 = 640Mi (requests), 512×2 + 256 = 1280Mi (limits)
- CPU: 250×2 + 100 = 600m (requests), 500×2 + 200 = 1200m (limits)

**Alternatives Considered**:
- No limits: Rejected (risk of resource hogging)
- Higher requests: Rejected (may not fit on 8GB Minikube)
- QoS Guaranteed (requests = limits): Rejected (wastes resources in low-traffic periods)

---

## 11. Logging Strategy

### Decision: Container STDOUT/STDERR with kubectl logs

**Rationale**:
- Standard Kubernetes logging pattern
- No additional infrastructure needed for Phase IV
- `kubectl logs` provides basic log access
- Advanced log aggregation (ELK, Loki) out of scope per specification

**Pattern**:
```python
import logging
import sys

# Configure logging to STDOUT
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)

logger = logging.getLogger(__name__)

# Log startup
logger.info("Backend starting...")
logger.info(f"Environment: {os.getenv('ENV', 'production')}")

# Log database connection
try:
    engine = connect_with_retry(database_url)
    logger.info("✅ Database connection established")
except Exception as e:
    logger.error(f"❌ Database connection failed: {e}", file=sys.stderr)
    sys.exit(1)
```

**Log Access**:
```bash
# View logs from all backend pods
kubectl logs -l app=todo-backend --namespace=todo-app --tail=100

# Stream logs in real-time
kubectl logs -f deployment/todo-backend --namespace=todo-app

# View logs from specific pod
kubectl logs pod/todo-backend-xyz --namespace=todo-app
```

**Alternatives Considered**:
- Centralized logging (ELK, Loki): Rejected (out of scope for Phase IV)
- File-based logging: Rejected (incompatible with stateless design)

---

## Research Summary

All technical decisions align with Phase IV constitutional requirements and specification:

✅ **Constitutional Compliance**:
- AI-assisted tooling (Docker AI, kubectl-ai, kagent) prioritized
- Stateless design enforced (no filesystem dependencies)
- Secrets management via Kubernetes Secrets (no hardcoding)
- Backward compatibility (no application code changes)

✅ **Specification Alignment**:
- Database retry with exponential backoff (FR-033)
- HTTP 503 for unavailable database (FR-034)
- Health check failure marking (FR-035)
- Startup secrets validation (FR-023)
- Pod restart recovery < 30 seconds (SC-004)
- 2+ backend replicas support (SC-003)

✅ **Best Practices**:
- Multi-stage Docker builds
- Separate liveness/readiness probes
- Conservative resource requests
- Native Kubernetes self-healing
- Separate Helm charts for frontend/backend

**Ready to proceed to Phase 1 (Design & Contracts)**.

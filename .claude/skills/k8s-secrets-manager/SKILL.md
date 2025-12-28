# Kubernetes Secrets Manager Skill

**Skill Name**: `k8s-secrets-manager`
**Version**: 1.0.0
**Author**: AI-Assisted Development
**Last Updated**: 2025-12-28

## Purpose

A reusable skill for securely managing Kubernetes secrets:
- **Create**: Generate secret manifests for frontend and backend
- **Update**: Modify existing secrets without downtime
- **Validate**: Verify secrets are correctly applied and accessible
- **Security**: Never hardcode secrets, use environment variables and secure practices

## Prerequisites

### Required Tools
```bash
# Verify tools are installed
kubectl version --client      # kubectl configured
base64 --version              # For encoding secrets
```

### Security Requirements
- Never commit plaintext secrets to git
- Use `.gitignore` for secret value files
- Store secrets in environment variables or secure vaults
- Rotate secrets periodically

---

## Step 1: Identify Required Secrets

### Frontend Secrets

| Secret Name | Key | Description | Required |
|-------------|-----|-------------|----------|
| `frontend-secrets` | `NEXT_PUBLIC_API_KEY` | Public API key (if needed) | Optional |
| `frontend-secrets` | `NEXTAUTH_SECRET` | NextAuth.js session secret | If using auth |
| `frontend-secrets` | `NEXTAUTH_URL` | NextAuth.js URL | If using auth |

### Backend Secrets

| Secret Name | Key | Description | Required |
|-------------|-----|-------------|----------|
| `backend-secrets` | `OPENAI_API_KEY` | OpenAI API key for Agents SDK | Yes |
| `backend-secrets` | `DATABASE_URL` | Database connection string | If using DB |
| `backend-secrets` | `JWT_SECRET` | JWT signing key | If using JWT auth |
| `backend-secrets` | `REDIS_URL` | Redis connection string | If using Redis |
| `backend-secrets` | `AWS_ACCESS_KEY_ID` | AWS credentials | If using AWS |
| `backend-secrets` | `AWS_SECRET_ACCESS_KEY` | AWS credentials | If using AWS |

### Shared Secrets

| Secret Name | Key | Description | Required |
|-------------|-----|-------------|----------|
| `app-secrets` | `ENCRYPTION_KEY` | Shared encryption key | Optional |
| `registry-credentials` | `.dockerconfigjson` | Docker registry auth | If private registry |

---

## Step 2: Create Kubernetes Secret Manifests

### Secret Template Structure

```yaml
# k8s/secrets/secret-template.yaml
apiVersion: v1
kind: Secret
metadata:
  name: <secret-name>
  namespace: <namespace>
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/component: <component>
    app.kubernetes.io/managed-by: kubectl
type: Opaque
data:
  # Base64 encoded values
  KEY_NAME: <base64-encoded-value>
stringData:
  # Plain text values (auto-encoded by Kubernetes)
  KEY_NAME: <plain-text-value>
```

### Backend Secrets Manifest

```yaml
# k8s/secrets/backend-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: todo-dev
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/component: backend
    app.kubernetes.io/managed-by: kubectl
  annotations:
    description: "Backend service secrets"
type: Opaque
stringData:
  # OpenAI Configuration
  OPENAI_API_KEY: "${OPENAI_API_KEY}"
  OPENAI_ORG_ID: "${OPENAI_ORG_ID}"

  # Database (if applicable)
  DATABASE_URL: "${DATABASE_URL}"

  # Authentication
  JWT_SECRET: "${JWT_SECRET}"

  # Redis (if applicable)
  REDIS_URL: "${REDIS_URL}"
```

### Frontend Secrets Manifest

```yaml
# k8s/secrets/frontend-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: frontend-secrets
  namespace: todo-dev
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/component: frontend
    app.kubernetes.io/managed-by: kubectl
  annotations:
    description: "Frontend service secrets"
type: Opaque
stringData:
  # NextAuth.js (if using authentication)
  NEXTAUTH_SECRET: "${NEXTAUTH_SECRET}"
  NEXTAUTH_URL: "${NEXTAUTH_URL}"

  # API Keys (public, but managed as secret for flexibility)
  NEXT_PUBLIC_API_KEY: "${NEXT_PUBLIC_API_KEY}"
```

### Docker Registry Secret

```yaml
# k8s/secrets/registry-credentials.yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
  namespace: todo-dev
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/managed-by: kubectl
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-docker-config>
```

### TLS Secret (for Ingress)

```yaml
# k8s/secrets/tls-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: todo-tls
  namespace: todo-dev
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/managed-by: kubectl
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-private-key>
```

---

## Step 3: Apply Secrets to Cluster

### Method 1: From Environment Variables (Recommended)

```bash
#!/bin/bash
# scripts/create-secrets.sh
# Create secrets from environment variables

set -e

NAMESPACE=${1:-todo-dev}

echo "=== Creating Kubernetes Secrets ==="
echo "Namespace: ${NAMESPACE}"

# Ensure namespace exists
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------------------
# Backend Secrets
# -----------------------------------------------------------------------------
echo ""
echo "Creating backend secrets..."

# Check required environment variables
if [ -z "${OPENAI_API_KEY}" ]; then
  echo "❌ Error: OPENAI_API_KEY is not set"
  exit 1
fi

kubectl create secret generic backend-secrets \
  --namespace=${NAMESPACE} \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --from-literal=OPENAI_ORG_ID="${OPENAI_ORG_ID:-}" \
  --from-literal=DATABASE_URL="${DATABASE_URL:-}" \
  --from-literal=JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32)}" \
  --from-literal=REDIS_URL="${REDIS_URL:-}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Backend secrets created"

# -----------------------------------------------------------------------------
# Frontend Secrets
# -----------------------------------------------------------------------------
echo ""
echo "Creating frontend secrets..."

kubectl create secret generic frontend-secrets \
  --namespace=${NAMESPACE} \
  --from-literal=NEXTAUTH_SECRET="${NEXTAUTH_SECRET:-$(openssl rand -hex 32)}" \
  --from-literal=NEXTAUTH_URL="${NEXTAUTH_URL:-http://localhost:3000}" \
  --from-literal=NEXT_PUBLIC_API_KEY="${NEXT_PUBLIC_API_KEY:-}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Frontend secrets created"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "=== Secrets Created ==="
kubectl get secrets -n ${NAMESPACE} -l app.kubernetes.io/name=todo-app
```

### Method 2: From .env File

```bash
#!/bin/bash
# scripts/create-secrets-from-env.sh
# Create secrets from .env file

set -e

NAMESPACE=${1:-todo-dev}
ENV_FILE=${2:-.env}

if [ ! -f "${ENV_FILE}" ]; then
  echo "❌ Error: ${ENV_FILE} not found"
  exit 1
fi

echo "=== Creating Secrets from ${ENV_FILE} ==="

# Source the env file
set -a
source ${ENV_FILE}
set +a

# Create backend secrets
kubectl create secret generic backend-secrets \
  --namespace=${NAMESPACE} \
  --from-env-file=${ENV_FILE} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created from ${ENV_FILE}"
```

### Method 3: From Manifest Files

```bash
#!/bin/bash
# scripts/apply-secret-manifests.sh
# Apply secret manifests with envsubst

set -e

NAMESPACE=${1:-todo-dev}
SECRETS_DIR="./k8s/secrets"

echo "=== Applying Secret Manifests ==="

# Process and apply each secret file
for file in ${SECRETS_DIR}/*.yaml; do
  if [ -f "$file" ]; then
    echo "Processing: $(basename $file)"
    envsubst < "$file" | kubectl apply -n ${NAMESPACE} -f -
  fi
done

echo "✅ All secret manifests applied"
```

### Method 4: Using kubectl directly

```bash
# =============================================================================
# KUBECTL SECRET COMMANDS
# =============================================================================

NAMESPACE="todo-dev"

# Create namespace
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------------------
# Create secrets from literals
# -----------------------------------------------------------------------------

# Backend secrets
kubectl create secret generic backend-secrets \
  --namespace=${NAMESPACE} \
  --from-literal=OPENAI_API_KEY="sk-your-api-key-here" \
  --from-literal=DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --from-literal=JWT_SECRET="your-jwt-secret-here"

# Frontend secrets
kubectl create secret generic frontend-secrets \
  --namespace=${NAMESPACE} \
  --from-literal=NEXTAUTH_SECRET="your-nextauth-secret" \
  --from-literal=NEXTAUTH_URL="http://localhost:3000"

# -----------------------------------------------------------------------------
# Create secrets from files
# -----------------------------------------------------------------------------

# From a single file
kubectl create secret generic app-config \
  --namespace=${NAMESPACE} \
  --from-file=config.json=./config/config.json

# From multiple files
kubectl create secret generic certs \
  --namespace=${NAMESPACE} \
  --from-file=tls.crt=./certs/server.crt \
  --from-file=tls.key=./certs/server.key

# -----------------------------------------------------------------------------
# Create Docker registry secret
# -----------------------------------------------------------------------------

kubectl create secret docker-registry registry-credentials \
  --namespace=${NAMESPACE} \
  --docker-server=docker.io \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com

# -----------------------------------------------------------------------------
# Create TLS secret
# -----------------------------------------------------------------------------

kubectl create secret tls todo-tls \
  --namespace=${NAMESPACE} \
  --cert=./certs/tls.crt \
  --key=./certs/tls.key
```

---

## Step 4: Update Existing Secrets

### Update Secret Values

```bash
#!/bin/bash
# scripts/update-secret.sh
# Update a specific key in a secret

NAMESPACE=${1:-todo-dev}
SECRET_NAME=${2:-backend-secrets}
KEY_NAME=${3:-OPENAI_API_KEY}
NEW_VALUE=${4}

if [ -z "${NEW_VALUE}" ]; then
  echo "Usage: $0 <namespace> <secret-name> <key-name> <new-value>"
  exit 1
fi

echo "Updating ${KEY_NAME} in ${SECRET_NAME}..."

# Get current secret, update value, apply
kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o json | \
  jq --arg key "${KEY_NAME}" --arg val "$(echo -n ${NEW_VALUE} | base64)" \
  '.data[$key] = $val' | \
  kubectl apply -f -

echo "✅ Secret updated"

# Restart pods to pick up new secret (if not using auto-reload)
echo "Restarting pods to apply changes..."
kubectl rollout restart deployment -n ${NAMESPACE}
```

### Patch Secret

```bash
# Patch a specific key
kubectl patch secret backend-secrets -n todo-dev \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/OPENAI_API_KEY", "value": "'$(echo -n "new-api-key" | base64)'"}]'

# Add a new key
kubectl patch secret backend-secrets -n todo-dev \
  --type='json' \
  -p='[{"op": "add", "path": "/data/NEW_KEY", "value": "'$(echo -n "new-value" | base64)'"}]'

# Remove a key
kubectl patch secret backend-secrets -n todo-dev \
  --type='json' \
  -p='[{"op": "remove", "path": "/data/OLD_KEY"}]'
```

### Replace Entire Secret

```bash
# Delete and recreate (causes brief unavailability)
kubectl delete secret backend-secrets -n todo-dev
kubectl create secret generic backend-secrets \
  --namespace=todo-dev \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --from-literal=DATABASE_URL="${DATABASE_URL}"

# Or use apply with --force
kubectl create secret generic backend-secrets \
  --namespace=todo-dev \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Step 5: Validate Secrets

### Validation Script

```bash
#!/bin/bash
# scripts/validate-secrets.sh
# Comprehensive secret validation

set -e

NAMESPACE=${1:-todo-dev}

echo "============================================================================="
echo "  KUBERNETES SECRETS VALIDATION"
echo "  Namespace: ${NAMESPACE}"
echo "  Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "============================================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# -----------------------------------------------------------------------------
# 1. Check if secrets exist
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 1: Checking Secret Existence ==="

REQUIRED_SECRETS=("backend-secrets" "frontend-secrets")

for secret in "${REQUIRED_SECRETS[@]}"; do
  if kubectl get secret ${secret} -n ${NAMESPACE} &> /dev/null; then
    echo -e "  ${GREEN}✅ ${secret} exists${NC}"
  else
    echo -e "  ${RED}❌ ${secret} NOT FOUND${NC}"
    ((ERRORS++))
  fi
done

# -----------------------------------------------------------------------------
# 2. Validate secret keys
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 2: Validating Secret Keys ==="

# Backend required keys
BACKEND_REQUIRED_KEYS=("OPENAI_API_KEY")
BACKEND_OPTIONAL_KEYS=("DATABASE_URL" "JWT_SECRET" "REDIS_URL")

if kubectl get secret backend-secrets -n ${NAMESPACE} &> /dev/null; then
  echo "  Backend secrets:"

  # Get all keys in the secret
  BACKEND_KEYS=$(kubectl get secret backend-secrets -n ${NAMESPACE} -o jsonpath='{.data}' | jq -r 'keys[]')

  for key in "${BACKEND_REQUIRED_KEYS[@]}"; do
    if echo "${BACKEND_KEYS}" | grep -q "^${key}$"; then
      # Check if value is not empty
      VALUE=$(kubectl get secret backend-secrets -n ${NAMESPACE} -o jsonpath="{.data.${key}}" | base64 -d 2>/dev/null)
      if [ -n "${VALUE}" ]; then
        echo -e "    ${GREEN}✅ ${key}: Set (${#VALUE} chars)${NC}"
      else
        echo -e "    ${RED}❌ ${key}: Empty${NC}"
        ((ERRORS++))
      fi
    else
      echo -e "    ${RED}❌ ${key}: Missing (REQUIRED)${NC}"
      ((ERRORS++))
    fi
  done

  for key in "${BACKEND_OPTIONAL_KEYS[@]}"; do
    if echo "${BACKEND_KEYS}" | grep -q "^${key}$"; then
      VALUE=$(kubectl get secret backend-secrets -n ${NAMESPACE} -o jsonpath="{.data.${key}}" | base64 -d 2>/dev/null)
      if [ -n "${VALUE}" ]; then
        echo -e "    ${GREEN}✅ ${key}: Set${NC}"
      else
        echo -e "    ${YELLOW}⚠️  ${key}: Empty (optional)${NC}"
        ((WARNINGS++))
      fi
    else
      echo -e "    ${YELLOW}⚠️  ${key}: Not configured (optional)${NC}"
    fi
  done
fi

# Frontend keys
FRONTEND_OPTIONAL_KEYS=("NEXTAUTH_SECRET" "NEXTAUTH_URL" "NEXT_PUBLIC_API_KEY")

if kubectl get secret frontend-secrets -n ${NAMESPACE} &> /dev/null; then
  echo ""
  echo "  Frontend secrets:"

  FRONTEND_KEYS=$(kubectl get secret frontend-secrets -n ${NAMESPACE} -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null || echo "")

  for key in "${FRONTEND_OPTIONAL_KEYS[@]}"; do
    if echo "${FRONTEND_KEYS}" | grep -q "^${key}$"; then
      echo -e "    ${GREEN}✅ ${key}: Set${NC}"
    else
      echo -e "    ${YELLOW}⚠️  ${key}: Not configured${NC}"
    fi
  done
fi

# -----------------------------------------------------------------------------
# 3. Verify secrets are mounted in pods
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 3: Verifying Secret Mounts in Pods ==="

# Check backend pods
BACKEND_PODS=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/component=backend -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

if [ -n "${BACKEND_PODS}" ]; then
  for pod in ${BACKEND_PODS}; do
    echo "  Checking pod: ${pod}"

    # Check if secrets are available as env vars
    ENV_CHECK=$(kubectl exec ${pod} -n ${NAMESPACE} -- env 2>/dev/null | grep -c "OPENAI_API_KEY\|DATABASE_URL" || echo "0")

    if [ "${ENV_CHECK}" -gt 0 ]; then
      echo -e "    ${GREEN}✅ Environment variables accessible${NC}"
    else
      echo -e "    ${YELLOW}⚠️  Could not verify environment variables${NC}"
      ((WARNINGS++))
    fi
  done
else
  echo -e "  ${YELLOW}⚠️  No backend pods found${NC}"
fi

# -----------------------------------------------------------------------------
# 4. Check for common security issues
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 4: Security Checks ==="

# Check for default/weak secrets
echo "  Checking for weak secrets..."

# Check if secrets are using default values
for secret in backend-secrets frontend-secrets; do
  if kubectl get secret ${secret} -n ${NAMESPACE} &> /dev/null; then
    # Check for common weak patterns
    KEYS=$(kubectl get secret ${secret} -n ${NAMESPACE} -o json | jq -r '.data | keys[]')

    for key in ${KEYS}; do
      VALUE=$(kubectl get secret ${secret} -n ${NAMESPACE} -o jsonpath="{.data.${key}}" | base64 -d 2>/dev/null)

      # Check for weak patterns
      if [[ "${VALUE}" == "changeme" ]] || [[ "${VALUE}" == "password" ]] || [[ "${VALUE}" == "secret" ]]; then
        echo -e "    ${RED}❌ ${secret}/${key}: Uses weak/default value${NC}"
        ((ERRORS++))
      elif [[ ${#VALUE} -lt 16 ]] && [[ "${key}" =~ (SECRET|KEY|PASSWORD) ]]; then
        echo -e "    ${YELLOW}⚠️  ${secret}/${key}: Value seems short (${#VALUE} chars)${NC}"
        ((WARNINGS++))
      fi
    done
  fi
done

echo -e "  ${GREEN}✅ Security checks complete${NC}"

# -----------------------------------------------------------------------------
# 5. Check secret age and annotations
# -----------------------------------------------------------------------------
echo ""
echo "=== Step 5: Secret Metadata ==="

for secret in backend-secrets frontend-secrets; do
  if kubectl get secret ${secret} -n ${NAMESPACE} &> /dev/null; then
    CREATED=$(kubectl get secret ${secret} -n ${NAMESPACE} -o jsonpath='{.metadata.creationTimestamp}')
    echo "  ${secret}:"
    echo "    Created: ${CREATED}"

    # Check if secret is older than 90 days
    CREATED_EPOCH=$(date -d "${CREATED}" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    AGE_DAYS=$(( (NOW_EPOCH - CREATED_EPOCH) / 86400 ))

    if [ ${AGE_DAYS} -gt 90 ]; then
      echo -e "    ${YELLOW}⚠️  Secret is ${AGE_DAYS} days old (consider rotation)${NC}"
      ((WARNINGS++))
    fi
  fi
done

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "============================================================================="
echo "  VALIDATION SUMMARY"
echo "============================================================================="

if [ ${ERRORS} -eq 0 ] && [ ${WARNINGS} -eq 0 ]; then
  echo -e "  ${GREEN}✅ All validations passed!${NC}"
  EXIT_CODE=0
elif [ ${ERRORS} -eq 0 ]; then
  echo -e "  ${YELLOW}⚠️  Passed with ${WARNINGS} warning(s)${NC}"
  EXIT_CODE=0
else
  echo -e "  ${RED}❌ Failed with ${ERRORS} error(s) and ${WARNINGS} warning(s)${NC}"
  EXIT_CODE=1
fi

echo ""
echo "  Errors: ${ERRORS}"
echo "  Warnings: ${WARNINGS}"
echo ""
echo "============================================================================="

exit ${EXIT_CODE}
```

### Quick Validation Commands

```bash
# =============================================================================
# QUICK VALIDATION COMMANDS
# =============================================================================

NAMESPACE="todo-dev"

# List all secrets
kubectl get secrets -n ${NAMESPACE}

# Describe a secret (shows keys, not values)
kubectl describe secret backend-secrets -n ${NAMESPACE}

# View secret keys
kubectl get secret backend-secrets -n ${NAMESPACE} -o jsonpath='{.data}' | jq 'keys'

# Decode a specific secret value
kubectl get secret backend-secrets -n ${NAMESPACE} \
  -o jsonpath='{.data.OPENAI_API_KEY}' | base64 -d

# View all secret values (BE CAREFUL - exposes secrets)
kubectl get secret backend-secrets -n ${NAMESPACE} -o json | \
  jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'

# Check if secret is being used by pods
kubectl get pods -n ${NAMESPACE} -o json | \
  jq -r '.items[] | select(.spec.containers[].envFrom[]?.secretRef.name == "backend-secrets") | .metadata.name'

# Verify secret in pod environment
kubectl exec -it <pod-name> -n ${NAMESPACE} -- printenv | grep -E "OPENAI|DATABASE|JWT"
```

### JSON Validation Output

```bash
#!/bin/bash
# scripts/validate-secrets-json.sh
# Output validation results as JSON

NAMESPACE=${1:-todo-dev}

# Collect data
SECRETS=$(kubectl get secrets -n ${NAMESPACE} -o json)

# Generate JSON report
cat <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "namespace": "${NAMESPACE}",
  "secrets": $(echo ${SECRETS} | jq '[.items[] | {
    name: .metadata.name,
    type: .type,
    keys: (.data | keys),
    created: .metadata.creationTimestamp,
    labels: .metadata.labels
  }]'),
  "validation": {
    "backend_secrets_exists": $(kubectl get secret backend-secrets -n ${NAMESPACE} &>/dev/null && echo "true" || echo "false"),
    "frontend_secrets_exists": $(kubectl get secret frontend-secrets -n ${NAMESPACE} &>/dev/null && echo "true" || echo "false"),
    "openai_key_set": $(kubectl get secret backend-secrets -n ${NAMESPACE} -o jsonpath='{.data.OPENAI_API_KEY}' 2>/dev/null | base64 -d | grep -q "." && echo "true" || echo "false")
  }
}
EOF
```

---

## Secret Templates

### Complete Backend Secret Template

```yaml
# k8s/secrets/templates/backend-secrets.yaml.tpl
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/component: backend
    app.kubernetes.io/managed-by: kubectl
    app.kubernetes.io/version: "${APP_VERSION}"
  annotations:
    description: "Backend service secrets for Todo App"
    rotated-at: "${ROTATION_DATE}"
type: Opaque
stringData:
  # ==========================================================================
  # OpenAI Configuration (Required)
  # ==========================================================================
  OPENAI_API_KEY: "${OPENAI_API_KEY}"
  OPENAI_ORG_ID: "${OPENAI_ORG_ID}"
  OPENAI_MODEL: "${OPENAI_MODEL:-gpt-4}"

  # ==========================================================================
  # Database Configuration (Optional)
  # ==========================================================================
  DATABASE_URL: "${DATABASE_URL}"
  DATABASE_POOL_SIZE: "${DATABASE_POOL_SIZE:-5}"

  # ==========================================================================
  # Authentication & Security
  # ==========================================================================
  JWT_SECRET: "${JWT_SECRET}"
  JWT_ALGORITHM: "${JWT_ALGORITHM:-HS256}"
  JWT_EXPIRY: "${JWT_EXPIRY:-3600}"

  # Encryption
  ENCRYPTION_KEY: "${ENCRYPTION_KEY}"

  # ==========================================================================
  # Cache & Queue (Optional)
  # ==========================================================================
  REDIS_URL: "${REDIS_URL}"

  # ==========================================================================
  # External Services (Optional)
  # ==========================================================================
  SENTRY_DSN: "${SENTRY_DSN}"

  # AWS (if needed)
  AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
  AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
  AWS_REGION: "${AWS_REGION:-us-east-1}"
```

### Complete Frontend Secret Template

```yaml
# k8s/secrets/templates/frontend-secrets.yaml.tpl
apiVersion: v1
kind: Secret
metadata:
  name: frontend-secrets
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/name: todo-app
    app.kubernetes.io/component: frontend
    app.kubernetes.io/managed-by: kubectl
  annotations:
    description: "Frontend service secrets for Todo App"
type: Opaque
stringData:
  # ==========================================================================
  # NextAuth.js Configuration
  # ==========================================================================
  NEXTAUTH_SECRET: "${NEXTAUTH_SECRET}"
  NEXTAUTH_URL: "${NEXTAUTH_URL}"

  # ==========================================================================
  # OAuth Providers (if using social login)
  # ==========================================================================
  GITHUB_CLIENT_ID: "${GITHUB_CLIENT_ID}"
  GITHUB_CLIENT_SECRET: "${GITHUB_CLIENT_SECRET}"

  GOOGLE_CLIENT_ID: "${GOOGLE_CLIENT_ID}"
  GOOGLE_CLIENT_SECRET: "${GOOGLE_CLIENT_SECRET}"

  # ==========================================================================
  # Analytics & Monitoring (Optional)
  # ==========================================================================
  NEXT_PUBLIC_ANALYTICS_ID: "${NEXT_PUBLIC_ANALYTICS_ID}"
  SENTRY_DSN: "${SENTRY_DSN}"
```

---

## Deployment Integration

### Using Secrets in Deployments

```yaml
# In deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: backend
          image: todo-backend:latest
          # Method 1: Load all keys from secret as env vars
          envFrom:
            - secretRef:
                name: backend-secrets

          # Method 2: Load specific keys
          env:
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: backend-secrets
                  key: OPENAI_API_KEY
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: backend-secrets
                  key: DATABASE_URL
                  optional: true  # Won't fail if key doesn't exist

          # Method 3: Mount as files
          volumeMounts:
            - name: secrets-volume
              mountPath: /etc/secrets
              readOnly: true

      volumes:
        - name: secrets-volume
          secret:
            secretName: backend-secrets
            items:
              - key: OPENAI_API_KEY
                path: openai-api-key
```

---

## Quick Reference Commands

```bash
# =============================================================================
# QUICK REFERENCE
# =============================================================================

NAMESPACE="todo-dev"

# Create secret
kubectl create secret generic backend-secrets \
  --namespace=${NAMESPACE} \
  --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}"

# List secrets
kubectl get secrets -n ${NAMESPACE}

# View secret keys
kubectl get secret backend-secrets -n ${NAMESPACE} -o jsonpath='{.data}' | jq 'keys'

# Decode secret value
kubectl get secret backend-secrets -n ${NAMESPACE} \
  -o jsonpath='{.data.OPENAI_API_KEY}' | base64 -d

# Update secret
kubectl create secret generic backend-secrets \
  --namespace=${NAMESPACE} \
  --from-literal=OPENAI_API_KEY="${NEW_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Delete secret
kubectl delete secret backend-secrets -n ${NAMESPACE}

# Restart pods to pick up secret changes
kubectl rollout restart deployment/todo-backend -n ${NAMESPACE}

# Check secret in pod
kubectl exec -it <pod> -n ${NAMESPACE} -- printenv | grep OPENAI
```

---

## Security Best Practices

### Do's
- Use `stringData` in manifests (auto-encoded)
- Store secret values in environment variables
- Use `--dry-run=client -o yaml | kubectl apply -f -` for idempotent creates
- Rotate secrets periodically
- Use RBAC to limit secret access
- Enable encryption at rest in Kubernetes

### Don'ts
- Never commit plaintext secrets to git
- Never log secret values
- Don't use `kubectl get secret -o yaml` in scripts (exposes base64)
- Don't share secrets across namespaces unnecessarily
- Don't use weak/default secret values

### .gitignore for Secrets

```gitignore
# Secret files
*.secret
*.secrets
.env
.env.*
secrets/
k8s/secrets/*.yaml
!k8s/secrets/*.yaml.tpl
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Pod can't access secret | Wrong namespace or name | Verify secret name and namespace match |
| Secret key not found | Typo in key name | Check exact key names with `kubectl describe secret` |
| Permission denied | RBAC restrictions | Check ServiceAccount permissions |
| Secret not updating | Pod caching env vars | Restart pods with `kubectl rollout restart` |
| Base64 decode errors | Invalid encoding | Re-encode with `echo -n "value" \| base64` |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-28 | Initial release with create, update, validate workflows |

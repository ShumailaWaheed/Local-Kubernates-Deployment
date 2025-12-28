# Helm Chart Generator Skill

**Skill Name**: `helm-chart-generator`
**Version**: 1.0.0
**Author**: AI-Assisted Development
**Last Updated**: 2025-12-28

## Purpose

A reusable skill for generating production-ready Helm charts for full-stack Kubernetes deployments:
- **Frontend**: Next.js application
- **Backend**: FastAPI with OpenAI Agents SDK
- **Features**: Templated deployments, services, configmaps, secrets, and ingress
- **Environments**: Dev and production value files with environment-specific configurations

## Prerequisites

### Required Tools
- Helm 3.x installed (`helm version`)
- kubectl configured with cluster access
- Minikube (for local development)

### Verify Installation
```bash
# Check Helm version
helm version --short

# Check kubectl connection
kubectl cluster-info

# Check Minikube status (local dev)
minikube status
```

---

## Step 1: Generate Helm Chart Directory Structure

### Standard Structure

```
helm/
└── todo-app/
    ├── Chart.yaml                 # Chart metadata
    ├── values.yaml                # Default values
    ├── values-dev.yaml            # Development overrides
    ├── values-prod.yaml           # Production overrides
    ├── .helmignore                # Files to ignore during packaging
    ├── templates/
    │   ├── _helpers.tpl           # Template helpers and functions
    │   ├── NOTES.txt              # Post-install notes
    │   ├── frontend/
    │   │   ├── deployment.yaml    # Frontend deployment
    │   │   ├── service.yaml       # Frontend service
    │   │   ├── configmap.yaml     # Frontend config
    │   │   └── hpa.yaml           # Horizontal Pod Autoscaler (optional)
    │   ├── backend/
    │   │   ├── deployment.yaml    # Backend deployment
    │   │   ├── service.yaml       # Backend service
    │   │   ├── configmap.yaml     # Backend config
    │   │   └── secret.yaml        # Backend secrets
    │   ├── ingress.yaml           # Ingress rules (optional)
    │   └── namespace.yaml         # Namespace (optional)
    └── charts/                    # Subcharts (if needed)
```

### Create Structure Command

```bash
# Create Helm chart structure
mkdir -p helm/todo-app/templates/{frontend,backend}
touch helm/todo-app/{Chart.yaml,values.yaml,values-dev.yaml,values-prod.yaml,.helmignore}
touch helm/todo-app/templates/_helpers.tpl
touch helm/todo-app/templates/NOTES.txt
touch helm/todo-app/templates/frontend/{deployment.yaml,service.yaml,configmap.yaml}
touch helm/todo-app/templates/backend/{deployment.yaml,service.yaml,configmap.yaml,secret.yaml}
touch helm/todo-app/templates/ingress.yaml
```

---

## Step 2: Chart.yaml

```yaml
# helm/todo-app/Chart.yaml
apiVersion: v2
name: todo-app
description: A Helm chart for Todo Application with Next.js frontend and FastAPI backend
type: application

# Chart version - increment on chart changes
version: 1.0.0

# Application version - matches your app release
appVersion: "1.0.0"

# Chart maintainers
maintainers:
  - name: Your Team
    email: team@example.com

# Keywords for searchability
keywords:
  - todo
  - nextjs
  - fastapi
  - kubernetes

# Home and sources
home: https://github.com/ShumailaWaheed/Local-Kubernates-Deployment
sources:
  - https://github.com/ShumailaWaheed/Local-Kubernates-Deployment

# Dependencies (if using subcharts)
dependencies: []
  # - name: postgresql
  #   version: "12.x.x"
  #   repository: "https://charts.bitnami.com/bitnami"
  #   condition: postgresql.enabled
```

---

## Step 3: values.yaml (Default Values)

```yaml
# helm/todo-app/values.yaml
# =============================================================================
# TODO APP HELM CHART - DEFAULT VALUES
# =============================================================================
# Override these values with values-dev.yaml or values-prod.yaml

# -----------------------------------------------------------------------------
# Global Settings
# -----------------------------------------------------------------------------
global:
  # Namespace for all resources (created if createNamespace: true)
  namespace: todo-app
  createNamespace: true

  # Image pull settings
  imagePullPolicy: IfNotPresent
  imagePullSecrets: []

  # Environment label
  environment: development

# -----------------------------------------------------------------------------
# Frontend Configuration (Next.js)
# -----------------------------------------------------------------------------
frontend:
  enabled: true
  name: todo-frontend

  # Replica count
  replicaCount: 2

  # Container image
  image:
    repository: todo-frontend
    tag: "latest"
    pullPolicy: IfNotPresent

  # Container port
  containerPort: 3000

  # Service configuration
  service:
    type: ClusterIP
    port: 80
    targetPort: 3000
    annotations: {}

  # Resource limits and requests
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

  # Environment variables
  env:
    - name: NODE_ENV
      value: "production"
    - name: NEXT_PUBLIC_API_URL
      value: "http://todo-backend:8000"

  # ConfigMap data (mounted as env vars or files)
  configMap:
    enabled: true
    data:
      APP_NAME: "Todo App"
      LOG_LEVEL: "info"

  # Health checks
  livenessProbe:
    enabled: true
    httpGet:
      path: /api/health
      port: 3000
    initialDelaySeconds: 10
    periodSeconds: 30
    timeoutSeconds: 5
    failureThreshold: 3

  readinessProbe:
    enabled: true
    httpGet:
      path: /api/health
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 3
    failureThreshold: 3

  # Horizontal Pod Autoscaler
  autoscaling:
    enabled: false
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80

  # Node selector, tolerations, affinity
  nodeSelector: {}
  tolerations: []
  affinity: {}

  # Pod annotations and labels
  podAnnotations: {}
  podLabels: {}

# -----------------------------------------------------------------------------
# Backend Configuration (FastAPI)
# -----------------------------------------------------------------------------
backend:
  enabled: true
  name: todo-backend

  # Replica count
  replicaCount: 2

  # Container image
  image:
    repository: todo-backend
    tag: "latest"
    pullPolicy: IfNotPresent

  # Container port
  containerPort: 8000

  # Service configuration
  service:
    type: ClusterIP
    port: 8000
    targetPort: 8000
    annotations: {}

  # Resource limits and requests
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"

  # Environment variables (non-sensitive)
  env:
    - name: PYTHONUNBUFFERED
      value: "1"
    - name: LOG_LEVEL
      value: "info"
    - name: WORKERS
      value: "2"

  # ConfigMap data
  configMap:
    enabled: true
    data:
      APP_NAME: "Todo Backend API"
      CORS_ORIGINS: "*"

  # Secrets (sensitive data)
  secrets:
    enabled: true
    # Values should be base64 encoded or use external secrets
    data:
      OPENAI_API_KEY: ""  # Set via --set or values-prod.yaml
      DATABASE_URL: ""    # Set via --set or values-prod.yaml

  # Health checks
  livenessProbe:
    enabled: true
    httpGet:
      path: /health
      port: 8000
    initialDelaySeconds: 15
    periodSeconds: 30
    timeoutSeconds: 5
    failureThreshold: 3

  readinessProbe:
    enabled: true
    httpGet:
      path: /health
      port: 8000
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 3
    failureThreshold: 3

  # Horizontal Pod Autoscaler
  autoscaling:
    enabled: false
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

  # Node selector, tolerations, affinity
  nodeSelector: {}
  tolerations: []
  affinity: {}

  # Pod annotations and labels
  podAnnotations: {}
  podLabels: {}

# -----------------------------------------------------------------------------
# Ingress Configuration
# -----------------------------------------------------------------------------
ingress:
  enabled: false
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
    # nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # cert-manager.io/cluster-issuer: "letsencrypt-prod"

  hosts:
    - host: todo.local
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: backend

  tls: []
  #  - secretName: todo-tls
  #    hosts:
  #      - todo.local

# -----------------------------------------------------------------------------
# Service Account
# -----------------------------------------------------------------------------
serviceAccount:
  create: true
  name: ""
  annotations: {}
```

---

## Step 4: Environment-Specific Values

### values-dev.yaml (Development)

```yaml
# helm/todo-app/values-dev.yaml
# =============================================================================
# DEVELOPMENT ENVIRONMENT VALUES
# =============================================================================

global:
  namespace: todo-dev
  environment: development

frontend:
  replicaCount: 1

  image:
    tag: "dev"
    pullPolicy: Always

  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "128Mi"
      cpu: "100m"

  env:
    - name: NODE_ENV
      value: "development"
    - name: NEXT_PUBLIC_API_URL
      value: "http://todo-backend:8000"

  service:
    type: NodePort
    nodePort: 30080

backend:
  replicaCount: 1

  image:
    tag: "dev"
    pullPolicy: Always

  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

  env:
    - name: LOG_LEVEL
      value: "debug"
    - name: WORKERS
      value: "1"

  service:
    type: NodePort
    nodePort: 30800

ingress:
  enabled: false
```

### values-prod.yaml (Production)

```yaml
# helm/todo-app/values-prod.yaml
# =============================================================================
# PRODUCTION ENVIRONMENT VALUES
# =============================================================================

global:
  namespace: todo-prod
  environment: production
  imagePullPolicy: Always

frontend:
  replicaCount: 3

  image:
    repository: docker.io/yourusername/todo-frontend
    tag: "v1.0.0"

  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"

  env:
    - name: NODE_ENV
      value: "production"
    - name: NEXT_PUBLIC_API_URL
      value: "https://api.todo.example.com"

  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

backend:
  replicaCount: 3

  image:
    repository: docker.io/yourusername/todo-backend
    tag: "v1.0.0"

  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

  env:
    - name: LOG_LEVEL
      value: "warning"
    - name: WORKERS
      value: "4"

  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 15
    targetCPUUtilizationPercentage: 70

ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: todo.example.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api
          pathType: Prefix
          service: backend
  tls:
    - secretName: todo-tls
      hosts:
        - todo.example.com
```

---

## Step 5: Template Files

### _helpers.tpl (Template Helpers)

```yaml
# helm/todo-app/templates/_helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "todo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "todo-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "todo-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "todo-app.labels" -}}
helm.sh/chart: {{ include "todo-app.chart" . }}
{{ include "todo-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.global.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "todo-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "todo-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "todo-app.frontend.labels" -}}
{{ include "todo-app.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "todo-app.frontend.selectorLabels" -}}
{{ include "todo-app.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend labels
*/}}
{{- define "todo-app.backend.labels" -}}
{{ include "todo-app.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "todo-app.backend.selectorLabels" -}}
{{ include "todo-app.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "todo-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "todo-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "todo-app.image" -}}
{{- $registry := .registry | default "" -}}
{{- $repository := .repository -}}
{{- $tag := .tag | default "latest" -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else }}
{{- printf "%s:%s" $repository $tag -}}
{{- end }}
{{- end }}
```

### Frontend Deployment Template

```yaml
# helm/todo-app/templates/frontend/deployment.yaml
{{- if .Values.frontend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.frontend.name }}
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.frontend.labels" . | nindent 4 }}
spec:
  {{- if not .Values.frontend.autoscaling.enabled }}
  replicas: {{ .Values.frontend.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "todo-app.frontend.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/frontend/configmap.yaml") . | sha256sum }}
        {{- with .Values.frontend.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "todo-app.frontend.selectorLabels" . | nindent 8 }}
        {{- with .Values.frontend.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.global.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "todo-app.serviceAccountName" . }}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: {{ .Values.frontend.name }}
          image: {{ include "todo-app.image" .Values.frontend.image }}
          imagePullPolicy: {{ .Values.frontend.image.pullPolicy | default .Values.global.imagePullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.frontend.containerPort }}
              protocol: TCP
          {{- if .Values.frontend.env }}
          env:
            {{- toYaml .Values.frontend.env | nindent 12 }}
          {{- end }}
          {{- if .Values.frontend.configMap.enabled }}
          envFrom:
            - configMapRef:
                name: {{ .Values.frontend.name }}-config
          {{- end }}
          {{- if .Values.frontend.livenessProbe.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.frontend.livenessProbe.httpGet.path }}
              port: {{ .Values.frontend.livenessProbe.httpGet.port }}
            initialDelaySeconds: {{ .Values.frontend.livenessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.frontend.livenessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.frontend.livenessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.frontend.livenessProbe.failureThreshold }}
          {{- end }}
          {{- if .Values.frontend.readinessProbe.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.frontend.readinessProbe.httpGet.path }}
              port: {{ .Values.frontend.readinessProbe.httpGet.port }}
            initialDelaySeconds: {{ .Values.frontend.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.frontend.readinessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.frontend.readinessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.frontend.readinessProbe.failureThreshold }}
          {{- end }}
          resources:
            {{- toYaml .Values.frontend.resources | nindent 12 }}
      {{- with .Values.frontend.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.frontend.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.frontend.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
```

### Frontend Service Template

```yaml
# helm/todo-app/templates/frontend/service.yaml
{{- if .Values.frontend.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.frontend.name }}
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.frontend.labels" . | nindent 4 }}
  {{- with .Values.frontend.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.frontend.service.type }}
  ports:
    - port: {{ .Values.frontend.service.port }}
      targetPort: {{ .Values.frontend.service.targetPort }}
      protocol: TCP
      name: http
      {{- if and (eq .Values.frontend.service.type "NodePort") .Values.frontend.service.nodePort }}
      nodePort: {{ .Values.frontend.service.nodePort }}
      {{- end }}
  selector:
    {{- include "todo-app.frontend.selectorLabels" . | nindent 4 }}
{{- end }}
```

### Frontend ConfigMap Template

```yaml
# helm/todo-app/templates/frontend/configmap.yaml
{{- if and .Values.frontend.enabled .Values.frontend.configMap.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.frontend.name }}-config
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.frontend.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.frontend.configMap.data }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
```

### Backend Deployment Template

```yaml
# helm/todo-app/templates/backend/deployment.yaml
{{- if .Values.backend.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.backend.name }}
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.backend.labels" . | nindent 4 }}
spec:
  {{- if not .Values.backend.autoscaling.enabled }}
  replicas: {{ .Values.backend.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "todo-app.backend.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/backend/configmap.yaml") . | sha256sum }}
        checksum/secret: {{ include (print $.Template.BasePath "/backend/secret.yaml") . | sha256sum }}
        {{- with .Values.backend.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      labels:
        {{- include "todo-app.backend.selectorLabels" . | nindent 8 }}
        {{- with .Values.backend.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.global.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "todo-app.serviceAccountName" . }}
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: {{ .Values.backend.name }}
          image: {{ include "todo-app.image" .Values.backend.image }}
          imagePullPolicy: {{ .Values.backend.image.pullPolicy | default .Values.global.imagePullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.backend.containerPort }}
              protocol: TCP
          {{- if .Values.backend.env }}
          env:
            {{- toYaml .Values.backend.env | nindent 12 }}
          {{- end }}
          envFrom:
            {{- if .Values.backend.configMap.enabled }}
            - configMapRef:
                name: {{ .Values.backend.name }}-config
            {{- end }}
            {{- if .Values.backend.secrets.enabled }}
            - secretRef:
                name: {{ .Values.backend.name }}-secret
            {{- end }}
          {{- if .Values.backend.livenessProbe.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.backend.livenessProbe.httpGet.path }}
              port: {{ .Values.backend.livenessProbe.httpGet.port }}
            initialDelaySeconds: {{ .Values.backend.livenessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.backend.livenessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.backend.livenessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.backend.livenessProbe.failureThreshold }}
          {{- end }}
          {{- if .Values.backend.readinessProbe.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.backend.readinessProbe.httpGet.path }}
              port: {{ .Values.backend.readinessProbe.httpGet.port }}
            initialDelaySeconds: {{ .Values.backend.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ .Values.backend.readinessProbe.periodSeconds }}
            timeoutSeconds: {{ .Values.backend.readinessProbe.timeoutSeconds }}
            failureThreshold: {{ .Values.backend.readinessProbe.failureThreshold }}
          {{- end }}
          resources:
            {{- toYaml .Values.backend.resources | nindent 12 }}
      {{- with .Values.backend.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.backend.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.backend.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
```

### Backend Service Template

```yaml
# helm/todo-app/templates/backend/service.yaml
{{- if .Values.backend.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.backend.name }}
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.backend.labels" . | nindent 4 }}
  {{- with .Values.backend.service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ .Values.backend.service.type }}
  ports:
    - port: {{ .Values.backend.service.port }}
      targetPort: {{ .Values.backend.service.targetPort }}
      protocol: TCP
      name: http
      {{- if and (eq .Values.backend.service.type "NodePort") .Values.backend.service.nodePort }}
      nodePort: {{ .Values.backend.service.nodePort }}
      {{- end }}
  selector:
    {{- include "todo-app.backend.selectorLabels" . | nindent 4 }}
{{- end }}
```

### Backend ConfigMap Template

```yaml
# helm/todo-app/templates/backend/configmap.yaml
{{- if and .Values.backend.enabled .Values.backend.configMap.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.backend.name }}-config
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.backend.labels" . | nindent 4 }}
data:
  {{- range $key, $value := .Values.backend.configMap.data }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
```

### Backend Secret Template

```yaml
# helm/todo-app/templates/backend/secret.yaml
{{- if and .Values.backend.enabled .Values.backend.secrets.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.backend.name }}-secret
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.backend.labels" . | nindent 4 }}
type: Opaque
data:
  {{- range $key, $value := .Values.backend.secrets.data }}
  {{- if $value }}
  {{ $key }}: {{ $value | b64enc | quote }}
  {{- end }}
  {{- end }}
{{- end }}
```

### Ingress Template

```yaml
# helm/todo-app/templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "todo-app.fullname" . }}
  namespace: {{ .Values.global.namespace }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                {{- if eq .service "frontend" }}
                name: {{ $.Values.frontend.name }}
                port:
                  number: {{ $.Values.frontend.service.port }}
                {{- else if eq .service "backend" }}
                name: {{ $.Values.backend.name }}
                port:
                  number: {{ $.Values.backend.service.port }}
                {{- end }}
          {{- end }}
    {{- end }}
{{- end }}
```

### NOTES.txt (Post-Install Instructions)

```yaml
# helm/todo-app/templates/NOTES.txt
=============================================================================
  TODO APP DEPLOYMENT SUCCESSFUL!
=============================================================================

Namespace: {{ .Values.global.namespace }}
Environment: {{ .Values.global.environment }}

-----------------------------------------------------------------------------
FRONTEND ({{ .Values.frontend.name }})
-----------------------------------------------------------------------------
{{- if .Values.frontend.enabled }}
  Replicas: {{ .Values.frontend.replicaCount }}
  Service Type: {{ .Values.frontend.service.type }}

  {{- if eq .Values.frontend.service.type "NodePort" }}
  Access URL: http://<NODE_IP>:{{ .Values.frontend.service.nodePort }}

  For Minikube:
    minikube service {{ .Values.frontend.name }} -n {{ .Values.global.namespace }} --url
  {{- else if eq .Values.frontend.service.type "LoadBalancer" }}
  Access URL: Pending external IP assignment

  Get the external IP:
    kubectl get svc {{ .Values.frontend.name }} -n {{ .Values.global.namespace }} -w
  {{- else }}
  Port Forward:
    kubectl port-forward svc/{{ .Values.frontend.name }} 3000:{{ .Values.frontend.service.port }} -n {{ .Values.global.namespace }}
  {{- end }}
{{- else }}
  Frontend is DISABLED
{{- end }}

-----------------------------------------------------------------------------
BACKEND ({{ .Values.backend.name }})
-----------------------------------------------------------------------------
{{- if .Values.backend.enabled }}
  Replicas: {{ .Values.backend.replicaCount }}
  Service Type: {{ .Values.backend.service.type }}

  {{- if eq .Values.backend.service.type "NodePort" }}
  Access URL: http://<NODE_IP>:{{ .Values.backend.service.nodePort }}

  For Minikube:
    minikube service {{ .Values.backend.name }} -n {{ .Values.global.namespace }} --url
  {{- else if eq .Values.backend.service.type "LoadBalancer" }}
  Access URL: Pending external IP assignment
  {{- else }}
  Port Forward:
    kubectl port-forward svc/{{ .Values.backend.name }} 8000:{{ .Values.backend.service.port }} -n {{ .Values.global.namespace }}
  {{- end }}

  Health Check:
    curl http://localhost:8000/health

  API Docs:
    http://localhost:8000/docs
{{- else }}
  Backend is DISABLED
{{- end }}

{{- if .Values.ingress.enabled }}
-----------------------------------------------------------------------------
INGRESS
-----------------------------------------------------------------------------
  {{- range .Values.ingress.hosts }}
  Host: {{ .host }}
  {{- end }}

  {{- if .Values.ingress.tls }}
  TLS: Enabled
  {{- end }}
{{- end }}

-----------------------------------------------------------------------------
USEFUL COMMANDS
-----------------------------------------------------------------------------
  # Check pod status
  kubectl get pods -n {{ .Values.global.namespace }}

  # View logs
  kubectl logs -f deployment/{{ .Values.frontend.name }} -n {{ .Values.global.namespace }}
  kubectl logs -f deployment/{{ .Values.backend.name }} -n {{ .Values.global.namespace }}

  # Describe deployments
  kubectl describe deployment {{ .Values.frontend.name }} -n {{ .Values.global.namespace }}
  kubectl describe deployment {{ .Values.backend.name }} -n {{ .Values.global.namespace }}

  # Scale deployments
  kubectl scale deployment {{ .Values.frontend.name }} --replicas=3 -n {{ .Values.global.namespace }}

  # Upgrade release
  helm upgrade {{ .Release.Name }} ./helm/todo-app -n {{ .Values.global.namespace }}

=============================================================================
```

### .helmignore

```
# helm/todo-app/.helmignore
# Patterns to ignore when building packages.

# VCS
.git/
.gitignore
.bzr/
.bzrignore
.hg/
.hgignore
.svn/

# IDE
.idea/
.vscode/
*.swp
*.bak
*.tmp
*.orig
*~

# Build/Test artifacts
*.log
.DS_Store

# Documentation
*.md
!README.md

# CI/CD
.github/
.gitlab-ci.yml
.travis.yml
Jenkinsfile

# Testing
tests/
*_test.yaml
```

---

## Step 6: Validate Helm Chart

### Validation Commands

```bash
# =============================================================================
# HELM CHART VALIDATION
# =============================================================================

# Lint the chart for errors
helm lint ./helm/todo-app

# Lint with specific values file
helm lint ./helm/todo-app -f ./helm/todo-app/values-dev.yaml

# Template rendering (dry-run) - see generated manifests
helm template todo-app ./helm/todo-app

# Template with specific values
helm template todo-app ./helm/todo-app -f ./helm/todo-app/values-dev.yaml

# Template single resource
helm template todo-app ./helm/todo-app --show-only templates/frontend/deployment.yaml

# Dry-run install (validates against cluster)
helm install todo-app ./helm/todo-app --dry-run --debug

# Validate YAML syntax
helm template todo-app ./helm/todo-app | kubectl apply --dry-run=client -f -
```

### Validation Script

```bash
#!/bin/bash
# scripts/validate-helm.sh

set -e

CHART_PATH="./helm/todo-app"

echo "=== Helm Chart Validation ==="

echo "1. Linting chart..."
helm lint ${CHART_PATH}

echo "2. Linting with dev values..."
helm lint ${CHART_PATH} -f ${CHART_PATH}/values-dev.yaml

echo "3. Linting with prod values..."
helm lint ${CHART_PATH} -f ${CHART_PATH}/values-prod.yaml

echo "4. Template rendering..."
helm template todo-app ${CHART_PATH} > /dev/null

echo "5. YAML validation..."
helm template todo-app ${CHART_PATH} | kubectl apply --dry-run=client -f - > /dev/null 2>&1

echo "=== All validations passed! ==="
```

---

## Step 7: Install/Upgrade Chart

### Installation Commands

```bash
# =============================================================================
# HELM INSTALL/UPGRADE COMMANDS
# =============================================================================

# -----------------------------------------------------------------------------
# Create Namespace (if not using chart's createNamespace)
# -----------------------------------------------------------------------------
kubectl create namespace todo-dev --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------------------
# Development Installation
# -----------------------------------------------------------------------------
helm install todo-app ./helm/todo-app \
  -f ./helm/todo-app/values-dev.yaml \
  -n todo-dev \
  --create-namespace

# -----------------------------------------------------------------------------
# Production Installation
# -----------------------------------------------------------------------------
helm install todo-app ./helm/todo-app \
  -f ./helm/todo-app/values-prod.yaml \
  -n todo-prod \
  --create-namespace \
  --set backend.secrets.data.OPENAI_API_KEY="${OPENAI_API_KEY}"

# -----------------------------------------------------------------------------
# Upgrade Existing Release
# -----------------------------------------------------------------------------
helm upgrade todo-app ./helm/todo-app \
  -f ./helm/todo-app/values-dev.yaml \
  -n todo-dev

# Upgrade with atomic rollback on failure
helm upgrade todo-app ./helm/todo-app \
  -f ./helm/todo-app/values-prod.yaml \
  -n todo-prod \
  --atomic \
  --timeout 5m

# -----------------------------------------------------------------------------
# Install or Upgrade (idempotent)
# -----------------------------------------------------------------------------
helm upgrade --install todo-app ./helm/todo-app \
  -f ./helm/todo-app/values-dev.yaml \
  -n todo-dev \
  --create-namespace

# -----------------------------------------------------------------------------
# Uninstall Release
# -----------------------------------------------------------------------------
helm uninstall todo-app -n todo-dev

# -----------------------------------------------------------------------------
# Rollback to Previous Version
# -----------------------------------------------------------------------------
helm rollback todo-app 1 -n todo-dev

# -----------------------------------------------------------------------------
# View Release History
# -----------------------------------------------------------------------------
helm history todo-app -n todo-dev
```

### Quick Start Script

```bash
#!/bin/bash
# scripts/deploy-helm.sh

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="todo-${ENVIRONMENT}"
CHART_PATH="./helm/todo-app"
VALUES_FILE="${CHART_PATH}/values-${ENVIRONMENT}.yaml"

echo "=== Deploying Todo App to ${ENVIRONMENT} ==="

# Validate
echo "Validating chart..."
helm lint ${CHART_PATH} -f ${VALUES_FILE}

# Deploy
echo "Installing/upgrading release..."
helm upgrade --install todo-app ${CHART_PATH} \
  -f ${VALUES_FILE} \
  -n ${NAMESPACE} \
  --create-namespace \
  --wait \
  --timeout 5m

# Status
echo "Deployment status:"
helm status todo-app -n ${NAMESPACE}

echo "=== Deployment complete! ==="
kubectl get pods -n ${NAMESPACE}
```

---

## Best Practices Summary

### Security
- Use Kubernetes Secrets for sensitive data
- Set `runAsNonRoot: true` in security context
- Use specific image tags, not `latest` in production
- Enable network policies (not included, add if needed)

### Reliability
- Configure proper health checks (liveness/readiness probes)
- Set resource requests and limits
- Use pod disruption budgets for production
- Enable autoscaling for variable loads

### Maintainability
- Use `_helpers.tpl` for reusable template functions
- Separate environment configs (values-dev.yaml, values-prod.yaml)
- Include NOTES.txt for post-install guidance
- Version your chart (Chart.yaml version)

### Testing
- Always lint before deploying (`helm lint`)
- Use `--dry-run` to preview changes
- Test in dev environment before production

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `namespace not found` | Namespace doesn't exist | Use `--create-namespace` flag |
| `image pull error` | Wrong image name or registry auth | Check image name, add imagePullSecrets |
| `pod crashloopbackoff` | App failing health checks | Check logs, adjust probe timing |
| `template error` | Invalid YAML or missing values | Run `helm template --debug` |
| `upgrade failed` | Breaking changes | Use `--atomic` for automatic rollback |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-28 | Initial release with frontend/backend templates |

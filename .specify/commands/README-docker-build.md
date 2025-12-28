# Docker Build Skill - Quick Start Guide

## Overview
The `/sp.docker-build` skill provides AI-assisted Docker image building for the Todo application with support for:
- ✅ Multi-stage builds for optimized image sizes
- ✅ Frontend (Next.js) and Backend (FastAPI) components
- ✅ Custom tagging strategies
- ✅ AI-first DevOps practices (Docker AI integration)
- ✅ Security scanning and secrets detection
- ✅ Automatic PHR documentation

## Installation

### Prerequisites
1. **Docker Desktop** (required by constitution)
   ```powershell
   # Verify Docker is installed and running
   docker --version
   docker info
   ```

2. **Git** (for commit-based tagging)
   ```powershell
   git --version
   ```

3. **Project Structure**
   ```
   project-root/
   ├── frontend/
   │   ├── Dockerfile          # ✅ Created by this skill
   │   ├── package.json
   │   └── ...
   ├── backend/
   │   ├── Dockerfile          # ✅ Created by this skill
   │   ├── requirements.txt
   │   └── ...
   └── .specify/
       └── commands/
           └── sp.docker-build.md
   ```

## Quick Start

### 1. Basic Build (All Components)
```powershell
# Claude Code CLI
/sp.docker-build
```

This will:
- Build both frontend and backend images
- Tag them as `todo-frontend:latest` and `todo-backend:latest`
- Generate `.dockerignore` if missing
- Check for secrets in build context
- Create a build log and PHR

### 2. Build Specific Component
```powershell
# Frontend only
/sp.docker-build --component frontend

# Backend only
/sp.docker-build --component backend
```

### 3. Custom Tagging
```powershell
# Semantic version
/sp.docker-build --tag v1.0.0

# Git commit SHA (automatic)
/sp.docker-build --tag $(git rev-parse --short HEAD)

# Development tag
/sp.docker-build --tag dev --component frontend
```

### 4. Build and Push to Registry
```powershell
# Push to Docker Hub
/sp.docker-build --tag v1.0.0 --registry docker.io/myusername --push

# Push to private registry
/sp.docker-build --tag v1.0.0 --registry registry.example.com/myproject --push
```

## Usage Examples

### Example 1: Development Workflow
```powershell
# 1. Build development images
/sp.docker-build --tag dev

# 2. Verify images
docker images | grep todo

# 3. Test frontend locally
docker run -p 3000:3000 todo-frontend:dev

# 4. Test backend locally
docker run -p 8000:8000 -e DATABASE_URL=$env:DATABASE_URL todo-backend:dev
```

### Example 2: Production Build
```powershell
# 1. Build with version tag
/sp.docker-build --tag v1.0.0 --no-cache

# 2. Inspect image
docker inspect todo-frontend:v1.0.0

# 3. Push to registry
/sp.docker-build --tag v1.0.0 --registry docker.io/myuser --push
```

### Example 3: Multi-Platform Build
```powershell
# Build for ARM64 (e.g., Apple Silicon)
/sp.docker-build --platform linux/arm64 --tag arm64

# Build for AMD64 (standard)
/sp.docker-build --platform linux/amd64 --tag amd64
```

## Configuration

### Optional: Custom Build Configuration
Create `docker-build-config.json` in project root:

```json
{
  "frontend": {
    "context": "./frontend",
    "dockerfile": "./frontend/Dockerfile",
    "defaultTag": "latest",
    "buildArgs": {
      "NODE_ENV": "production"
    }
  },
  "backend": {
    "context": "./backend",
    "dockerfile": "./backend/Dockerfile",
    "defaultTag": "latest",
    "buildArgs": {
      "PYTHON_VERSION": "3.11"
    }
  }
}
```

### Customizing .dockerignore
The skill auto-generates `.dockerignore`, but you can customize it:

```
# Add project-specific exclusions
*.local
.vscode/
.idea/

# Keep specific files
!.env.example
```

## Command Reference

### Arguments
| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `--component` | string | No | `all` | `frontend`, `backend`, or `all` |
| `--tag` | string | No | `latest` | Image tag (version, SHA, etc.) |
| `--registry` | string | No | `local` | Target registry URL |
| `--push` | flag | No | `false` | Push to registry after build |
| `--no-cache` | flag | No | `false` | Build without cache |
| `--platform` | string | No | `linux/amd64` | Target platform |

### Exit Codes
- `0`: Success - all builds completed
- `1`: Failure - Docker not running or build failed

## Troubleshooting

### Error: Docker Desktop Not Running
```
❌ Error: Docker Desktop is not running
💡 Solution: Start Docker Desktop and wait for it to be ready
```

**Fix**: Open Docker Desktop and wait for the whale icon to be active.

### Error: Dockerfile Not Found
```
❌ Error: Dockerfile not found at ./frontend/Dockerfile
💡 Solution: Create Dockerfile or check component path
```

**Fix**: The skill created template Dockerfiles in `frontend/` and `backend/` directories. Verify they exist.

### Error: Secrets Detected
```
❌ Error: Potential secrets detected in build context
   - .env file detected
💡 Add sensitive files to .dockerignore
```

**Fix**: Add `.env` and other sensitive files to `.dockerignore`:
```
.env
.env.local
credentials.json
```

### Error: Build Failed
```
❌ Error: Docker build failed at step 5/12
💡 Check build logs: docker-build.log
```

**Fix**:
1. Check `docker-build.log` for detailed error
2. Common causes:
   - Missing dependencies in `package.json` or `requirements.txt`
   - Network issues downloading packages
   - Syntax errors in Dockerfile

### Performance Issues

#### Slow Build Times
```powershell
# Use cache for faster rebuilds
/sp.docker-build --component frontend

# Clear cache for clean build
/sp.docker-build --no-cache
```

#### Large Image Sizes
The Dockerfiles use multi-stage builds to minimize size:
- **Frontend**: ~245 MB (Node builder → Nginx serve)
- **Backend**: ~389 MB (Python builder → slim runtime)

## Integration with AI DevOps

### Docker AI (Gordon) Integration
If you have Docker AI available:

```powershell
# Ask Gordon to analyze Dockerfile
gordon analyze-dockerfile ./frontend/Dockerfile

# Ask Gordon for optimization suggestions
gordon optimize ./frontend/Dockerfile
```

The skill will automatically incorporate Gordon's suggestions if available.

### Manual Optimization with Claude Code
```
# In Claude Code CLI
Analyze the frontend Dockerfile and suggest optimizations for:
- Smaller image size
- Faster build times
- Better security
```

## Best Practices

### 1. Security
✅ **Use non-root users** (enforced in generated Dockerfiles)
✅ **No secrets in images** (validated by skill)
✅ **Minimal base images** (alpine/slim variants)
✅ **Regular updates** (rebuild periodically)

### 2. Performance
✅ **Multi-stage builds** (reduces final image size)
✅ **Layer caching** (order commands from least to most frequently changed)
✅ **Minimize context** (use `.dockerignore`)

### 3. Tagging Strategy
```powershell
# Development
/sp.docker-build --tag dev

# Staging
/sp.docker-build --tag staging-$(git rev-parse --short HEAD)

# Production
/sp.docker-build --tag v1.0.0 --push
```

### 4. Health Checks
Both Dockerfiles include health checks:

**Frontend**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
    CMD node -e "require('http').get('http://localhost:3000/api/health', ...)"
```

**Backend**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8000/health || exit 1
```

## Next Steps

After building images:

### 1. Test Locally
```powershell
# Run frontend
docker run -d -p 3000:3000 --name todo-frontend todo-frontend:latest

# Run backend with env vars
docker run -d -p 8000:8000 \
    -e DATABASE_URL="postgresql://..." \
    -e OPENAI_API_KEY="sk-..." \
    --name todo-backend \
    todo-backend:latest

# Check logs
docker logs todo-frontend
docker logs todo-backend
```

### 2. Deploy to Minikube
```powershell
# Load images into Minikube
minikube image load todo-frontend:latest
minikube image load todo-backend:latest

# Deploy with Helm (if skill exists)
/sp.helm-deploy
```

### 3. Verify Phase III Compatibility
```powershell
# Test chatbot functionality
curl http://localhost:8000/api/chat -X POST -d '{"message":"show my tasks"}'

# Verify database connection
curl http://localhost:8000/health
```

## Constitutional Compliance

This skill enforces the following constitutional principles:

### ✅ Principle VI: Container Runtime Mandate
Uses Docker Desktop exclusively (no podman, containerd, etc.)

### ✅ Principle IX: AI-Assisted DevOps Priority
- Integrates with Docker AI (Gordon) when available
- Falls back to Claude Code optimizations
- Documents AI usage in PHR

### ✅ Principle XI: Secrets Management
- Validates no secrets in build context
- Auto-generates `.dockerignore` for sensitive files
- Enforces environment variable injection

### ✅ Principle II: No Manual Coding
- AI-generated Dockerfiles follow best practices
- Multi-stage builds configured automatically
- Security hardening applied

## Maintenance

### Updating Dockerfiles
If you need to modify the Dockerfiles:

1. Edit specification: `/sp.specify` (describe needed changes)
2. Update Dockerfiles with Claude Code
3. Rebuild: `/sp.docker-build`
4. Document changes in PHR

### Monitoring Build Performance
```powershell
# Check build logs
Get-Content docker-build.log -Tail 50

# Analyze image layers
docker history todo-frontend:latest

# Compare image sizes
docker images | grep todo
```

## Support

### Documentation
- **Skill Command**: `.specify/commands/sp.docker-build.md`
- **Constitution**: `.specify/memory/constitution.md`
- **Docker Best Practices**: https://docs.docker.com/develop/dev-best-practices/

### Common Questions

**Q: Can I use this with kind or k3s?**
A: No, Phase IV constitution mandates Minikube only (Principle VII).

**Q: Can I manually edit Dockerfiles?**
A: Only through specification → Claude Code generation (Principle II).

**Q: How do I handle database credentials?**
A: Use Kubernetes Secrets or environment variables (Principle XI).

**Q: What if Docker AI (Gordon) is unavailable?**
A: Skill automatically falls back to Claude Code optimizations.

## Version History

- **v1.0.0** (2025-12-24): Initial release
  - Multi-stage build support
  - Frontend + Backend components
  - Custom tagging strategies
  - AI DevOps integration
  - Security validation
  - Automatic PHR documentation

---

**Created**: 2025-12-24
**Skill Type**: Infrastructure/DevOps
**Constitutional Alignment**: ✅ Principles II, VI, IX, XI

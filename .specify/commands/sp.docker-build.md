# Docker Build Skill

**Command**: `/sp.docker-build`

## Purpose
AI-assisted Docker image building for the Todo application components with support for multi-stage builds, custom tagging, and AI-first DevOps practices.

## Surface
Project-level command that builds Docker images for frontend and backend services.

## Success Criteria
- Docker images are built successfully using Docker Desktop
- Images follow multi-stage build patterns for optimization
- Custom tagging strategies are applied correctly
- Build process is documented in PHR
- No secrets are embedded in images

## Usage

### Basic Usage
```
/sp.docker-build
```
Builds all components (frontend + backend) with default tags.

### Component-Specific Builds
```
/sp.docker-build --component frontend
/sp.docker-build --component backend
```

### Custom Tagging
```
/sp.docker-build --tag latest
/sp.docker-build --tag v1.0.0
/sp.docker-build --tag $(git rev-parse --short HEAD)
```

### Combined Options
```
/sp.docker-build --component frontend --tag v1.0.0 --push
```

## Arguments

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `--component` | string | No | `all` | Component to build: `frontend`, `backend`, or `all` |
| `--tag` | string | No | `latest` | Docker image tag (supports: `latest`, semantic versions, git SHA) |
| `--registry` | string | No | `local` | Target registry: `local`, `docker.io/username`, or custom registry |
| `--push` | flag | No | `false` | Push image to registry after build |
| `--no-cache` | flag | No | `false` | Build without using cache |
| `--platform` | string | No | `linux/amd64` | Target platform for multi-arch builds |

## Pre-requisites

### System Requirements
1. Docker Desktop installed and running
2. Git installed (for commit-based tagging)
3. Project structure:
   ```
   /frontend/Dockerfile
   /backend/Dockerfile
   ```

### Configuration Files
- `docker-build-config.json` (optional): Custom build configurations
- `.dockerignore`: Files to exclude from build context

## Workflow

### Phase 1: Validation
1. Verify Docker Desktop is running
2. Check if Dockerfiles exist for target components
3. Validate tag format
4. Ensure no secrets in build context

### Phase 2: Build Preparation
1. Read component-specific Dockerfile
2. Prepare build arguments:
   - `NODE_ENV` for frontend
   - `PYTHON_VERSION` for backend
   - Build timestamp
3. Generate `.dockerignore` if missing

### Phase 3: Build Execution
1. Run `docker build` with optimized flags:
   ```bash
   docker build \
     --tag <image-name>:<tag> \
     --file <Dockerfile-path> \
     --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
     --label org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
     --label org.opencontainers.image.revision=$(git rev-parse HEAD) \
     --platform <platform> \
     <context-directory>
   ```
2. Capture build logs
3. Verify image creation: `docker images | grep <image-name>`

### Phase 4: Post-Build Actions
1. Display image size and layers
2. Optionally push to registry
3. Generate build summary
4. Create PHR documenting build

## Examples

### Example 1: Build Frontend for Development
```bash
/sp.docker-build --component frontend --tag dev
```

**Expected Output**:
```
✅ Docker Desktop: Running
✅ Building frontend image: todo-frontend:dev
✅ Build completed successfully
📦 Image size: 245 MB
🏷️  Tags: todo-frontend:dev
📝 PHR created: history/prompts/k8s-deployment/012-docker-build-frontend.misc.prompt.md
```

### Example 2: Build All Components with Git SHA Tag
```bash
/sp.docker-build --tag $(git rev-parse --short HEAD)
```

**Expected Output**:
```
✅ Building frontend: todo-frontend:a1b2c3d
✅ Building backend: todo-backend:a1b2c3d
📊 Build Summary:
   - Frontend: 245 MB (12 layers)
   - Backend: 389 MB (15 layers)
```

### Example 3: Production Build and Push
```bash
/sp.docker-build --tag v1.0.0 --registry docker.io/myuser --push
```

## Error Handling

### Common Errors

#### Docker Desktop Not Running
```
❌ Error: Docker Desktop is not running
💡 Solution: Start Docker Desktop and wait for it to be ready
```

#### Dockerfile Not Found
```
❌ Error: Dockerfile not found at ./frontend/Dockerfile
💡 Solution: Create Dockerfile or check component path
```

#### Build Failed
```
❌ Error: Docker build failed at step 5/12
💡 Check build logs above for specific error
💡 Common causes: missing dependencies, network issues, syntax errors
```

#### Secrets Detected in Build Context
```
❌ Error: Potential secrets detected in build context
   - .env file detected
   - credentials.json found
💡 Add sensitive files to .dockerignore
```

## AI-Assisted DevOps Integration

### Docker AI (Gordon) Integration
If Docker AI is available, the skill will:
1. Ask Gordon to analyze Dockerfile for optimization opportunities
2. Generate improved multi-stage build configurations
3. Suggest security best practices

**Example Gordon Prompt**:
```
Analyze this Dockerfile and suggest optimizations for:
- Smaller image size
- Faster build times
- Better layer caching
- Security improvements
```

### Fallback to Claude Code
If Gordon is unavailable:
1. Claude Code will analyze Dockerfile structure
2. Apply best practices automatically
3. Generate optimized build commands

## Best Practices Enforced

### Multi-Stage Builds
- **Frontend**: Node build stage → Nginx serve stage
- **Backend**: Python dependencies stage → Runtime stage

### Layer Optimization
- Group related commands
- Copy package files before source code
- Use `.dockerignore` to reduce context size

### Security
- Use non-root users
- Scan for vulnerabilities (if tools available)
- No secrets in layers
- Minimal base images (alpine where possible)

### Labeling
All images include OCI-compliant labels:
- `org.opencontainers.image.created`
- `org.opencontainers.image.revision`
- `org.opencontainers.image.source`

## Output Files

### Generated/Modified Files
- Docker images in local registry
- `docker-build.log`: Detailed build logs
- `.dockerignore`: Generated if missing
- PHR documenting the build process

### PHR Location
- **Stage**: `misc` (infrastructure/tooling)
- **Feature**: Current feature context or `k8s-deployment`
- **Path**: `history/prompts/<feature>/###-docker-build-<component>.misc.prompt.md`

## Constitutional Compliance

### Principle VI: Container Runtime Mandate
✅ Uses Docker Desktop exclusively

### Principle IX: AI-Assisted DevOps Priority
✅ Integrates with Docker AI (Gordon) when available
✅ Falls back to Claude Code-generated optimizations

### Principle XI: Secrets Management
✅ Validates no secrets in build context
✅ Enforces .dockerignore for sensitive files

### Principle II: No Manual Coding
✅ Generated Dockerfiles follow best practices
✅ AI-assisted optimization and refinement

## Integration with Other Skills

### Complementary Skills
- `/sp.specify`: Define container requirements before building
- `/sp.plan`: Architecture decisions for containerization
- `/sp.tasks`: Break down multi-component builds

### Follow-up Actions
After building images:
1. Test containers locally: `docker run`
2. Deploy to Minikube: `/sp.helm-deploy` (if skill exists)
3. Validate behavior matches Phase III

## Maintenance

### Updating the Skill
1. Modify this command file
2. Document changes in constitution or ADR if significant
3. Update related templates if needed

### Version History
- **v1.0.0** (2025-12-24): Initial implementation with multi-stage build support

---

**Skill Type**: Infrastructure/DevOps
**AI Integration**: Docker AI (Gordon) + Claude Code
**Constitutional Alignment**: ✅ Principles II, VI, IX, XI

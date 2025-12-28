# Docker Build Script for Todo Application
# AI-Assisted Docker image building with multi-stage support

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("frontend", "backend", "all")]
    [string]$Component = "all",

    [Parameter(Mandatory=$false)]
    [string]$Tag = "latest",

    [Parameter(Mandatory=$false)]
    [string]$Registry = "local",

    [Parameter(Mandatory=$false)]
    [switch]$Push,

    [Parameter(Mandatory=$false)]
    [switch]$NoCache,

    [Parameter(Mandatory=$false)]
    [string]$Platform = "linux/amd64"
)

# Import common functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\common.ps1"

# Configuration
$projectRoot = Get-ProjectRoot
$buildLog = Join-Path $projectRoot "docker-build.log"
$buildTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" -AsUTC

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "📦 $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Initialize build log
function Initialize-BuildLog {
    @"
Docker Build Log
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Component: $Component
Tag: $Tag
Platform: $Platform
Registry: $Registry
Push: $Push
NoCache: $NoCache
================================================================================

"@ | Out-File -FilePath $buildLog -Encoding UTF8
}

# Check Docker Desktop status
function Test-DockerDesktop {
    Write-Info "Checking Docker Desktop status..."
    try {
        $dockerInfo = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Docker Desktop is not running"
            Write-Host "💡 Solution: Start Docker Desktop and wait for it to be ready" -ForegroundColor Yellow
            return $false
        }
        Write-Success "Docker Desktop: Running"
        return $true
    } catch {
        Write-Error "Docker command not found"
        Write-Host "💡 Solution: Install Docker Desktop" -ForegroundColor Yellow
        return $false
    }
}

# Get git commit SHA for labeling
function Get-GitCommitSha {
    try {
        $sha = git rev-parse HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $sha.Trim()
        }
    } catch {}
    return "unknown"
}

# Get git short SHA
function Get-GitShortSha {
    try {
        $sha = git rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $sha.Trim()
        }
    } catch {}
    return "unknown"
}

# Validate and get Dockerfile path
function Get-DockerfilePath {
    param([string]$ComponentName)

    $possiblePaths = @(
        (Join-Path $projectRoot "$ComponentName\Dockerfile"),
        (Join-Path $projectRoot "docker\$ComponentName.Dockerfile"),
        (Join-Path $projectRoot "Dockerfile.$ComponentName")
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

# Check for secrets in build context
function Test-SecretsInContext {
    param([string]$ContextPath)

    $sensitiveFiles = @(
        ".env",
        ".env.local",
        ".env.production",
        "credentials.json",
        "secrets.json",
        "*.key",
        "*.pem"
    )

    $foundSecrets = @()
    foreach ($pattern in $sensitiveFiles) {
        $files = Get-ChildItem -Path $ContextPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            $foundSecrets += $files.Name
        }
    }

    if ($foundSecrets.Count -gt 0) {
        Write-Error "Potential secrets detected in build context:"
        $foundSecrets | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
        Write-Warning "Add sensitive files to .dockerignore"
        return $false
    }

    return $true
}

# Generate .dockerignore if missing
function Initialize-DockerIgnore {
    param([string]$ContextPath)

    $dockerignorePath = Join-Path $ContextPath ".dockerignore"

    if (-not (Test-Path $dockerignorePath)) {
        Write-Info "Generating .dockerignore..."

        $dockerignoreContent = @"
# Dependencies
node_modules/
__pycache__/
*.pyc
.pytest_cache/
.venv/
venv/

# Environment files
.env
.env.local
.env.production
.env.*.local

# Secrets and credentials
*.key
*.pem
credentials.json
secrets.json

# Development files
.git/
.gitignore
.claude/
.specify/
history/
specs/

# Build artifacts
.next/
dist/
build/
*.log

# IDE
.vscode/
.idea/
*.swp

# OS files
.DS_Store
Thumbs.db

# Documentation (not needed in image)
README.md
*.md
docs/

# Test files
**/*.test.ts
**/*.test.js
**/*.spec.ts
**/*.spec.js
tests/
"@

        $dockerignoreContent | Out-File -FilePath $dockerignorePath -Encoding UTF8
        Write-Success "Generated .dockerignore at $dockerignorePath"
    }
}

# Build Docker image
function Build-DockerImage {
    param(
        [string]$ComponentName,
        [string]$DockerfilePath,
        [string]$ContextPath,
        [string]$ImageTag
    )

    Write-Info "Building $ComponentName image: $ImageTag"

    # Prepare build arguments
    $gitSha = Get-GitCommitSha
    $buildArgs = @(
        "build",
        "--tag", $ImageTag,
        "--file", $DockerfilePath,
        "--build-arg", "BUILD_DATE=$buildTimestamp",
        "--label", "org.opencontainers.image.created=$buildTimestamp",
        "--label", "org.opencontainers.image.revision=$gitSha",
        "--label", "org.opencontainers.image.source=https://github.com/yourorg/todo-app",
        "--platform", $Platform
    )

    if ($NoCache) {
        $buildArgs += "--no-cache"
    }

    $buildArgs += $ContextPath

    # Log the build command
    $buildCommand = "docker " + ($buildArgs -join " ")
    "Executing: $buildCommand" | Out-File -FilePath $buildLog -Append -Encoding UTF8
    Write-Host "🔨 $buildCommand" -ForegroundColor DarkGray

    # Execute build
    try {
        & docker @buildArgs 2>&1 | Tee-Object -FilePath $buildLog -Append

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Docker build failed for $ComponentName"
            Write-Host "💡 Check build logs: $buildLog" -ForegroundColor Yellow
            return $false
        }

        Write-Success "Build completed successfully: $ComponentName"
        return $true
    } catch {
        Write-Error "Exception during build: $_"
        return $false
    }
}

# Get image size and info
function Get-ImageInfo {
    param([string]$ImageTag)

    try {
        $imageInfo = docker images $ImageTag --format "{{.Size}}" 2>$null
        if ($imageInfo) {
            Write-Info "Image size: $imageInfo"
        }

        # Count layers
        $history = docker history $ImageTag --format "{{.ID}}" 2>$null
        if ($history) {
            $layerCount = ($history | Measure-Object).Count
            Write-Info "Layers: $layerCount"
        }
    } catch {
        Write-Warning "Could not retrieve image info"
    }
}

# Push image to registry
function Push-DockerImage {
    param([string]$ImageTag)

    if (-not $Push) {
        return $true
    }

    Write-Info "Pushing image to registry: $ImageTag"

    try {
        docker push $ImageTag 2>&1 | Tee-Object -FilePath $buildLog -Append

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to push image"
            return $false
        }

        Write-Success "Image pushed successfully"
        return $true
    } catch {
        Write-Error "Exception during push: $_"
        return $false
    }
}

# Build component helper
function Build-Component {
    param([string]$ComponentName)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Building: $ComponentName" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Find Dockerfile
    $dockerfilePath = Get-DockerfilePath -ComponentName $ComponentName
    if (-not $dockerfilePath) {
        Write-Error "Dockerfile not found for $ComponentName"
        Write-Host "💡 Create Dockerfile at .\$ComponentName\Dockerfile" -ForegroundColor Yellow
        return $false
    }

    Write-Success "Found Dockerfile: $dockerfilePath"

    # Determine context path
    $contextPath = Split-Path -Parent $dockerfilePath
    if (-not (Test-Path $contextPath)) {
        $contextPath = $projectRoot
    }

    # Security check
    if (-not (Test-SecretsInContext -ContextPath $contextPath)) {
        return $false
    }

    # Generate .dockerignore if needed
    Initialize-DockerIgnore -ContextPath $contextPath

    # Construct image tag
    $imageName = "todo-$ComponentName"
    if ($Registry -ne "local") {
        $imageName = "$Registry/$imageName"
    }
    $imageTag = "${imageName}:${Tag}"

    # Build image
    $buildSuccess = Build-DockerImage `
        -ComponentName $ComponentName `
        -DockerfilePath $dockerfilePath `
        -ContextPath $contextPath `
        -ImageTag $imageTag

    if (-not $buildSuccess) {
        return $false
    }

    # Get image info
    Get-ImageInfo -ImageTag $imageTag

    # Push if requested
    if ($Push) {
        $pushSuccess = Push-DockerImage -ImageTag $imageTag
        if (-not $pushSuccess) {
            return $false
        }
    }

    return $true
}

# Main execution
function Main {
    Write-Host "`n🐳 Docker Build for Todo Application`n" -ForegroundColor Magenta

    # Initialize log
    Initialize-BuildLog

    # Check Docker Desktop
    if (-not (Test-DockerDesktop)) {
        exit 1
    }

    # Build components
    $componentsTouild = @()
    if ($Component -eq "all") {
        $componentsTouild = @("frontend", "backend")
    } else {
        $componentsTouild = @($Component)
    }

    $allSuccess = $true
    $buildSummary = @()

    foreach ($comp in $componentsTouild) {
        $success = Build-Component -ComponentName $comp
        if ($success) {
            $buildSummary += "✅ $comp"
        } else {
            $buildSummary += "❌ $comp"
            $allSuccess = $false
        }
    }

    # Display summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Build Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $buildSummary | ForEach-Object { Write-Host $_ }
    Write-Host "`n📝 Build log: $buildLog" -ForegroundColor Cyan

    if ($allSuccess) {
        Write-Host "`n✅ All builds completed successfully!`n" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n❌ Some builds failed. Check logs above.`n" -ForegroundColor Red
        exit 1
    }
}

# Run main
Main

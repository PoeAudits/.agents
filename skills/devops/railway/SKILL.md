---
name: railway
description: Use when deploying applications to Railway, configuring Railway services, setting up databases on Railway, or troubleshooting Railway deployments. Triggers on railway CLI commands, railway.json/toml configuration, Railway networking, or Railway environment variables.
---

# Railway Deployment

## Overview

Railway is a cloud deployment platform with zero-config builds, automatic scaling, and built-in databases. Deploy via GitHub, CLI, or Docker images. Services within a project are automatically joined to a private network.

**Key concepts:**
- **Project**: Container for services, joined by private network
- **Service**: Deployment target (code repo, Docker image, or database)
- **Environment**: Isolated configuration (production, staging, PR environments)
- **Volume**: Persistent storage that survives deployments

## CLI Installation

```bash
# macOS
brew install railway

# npm (requires Node.js >=16)
npm i -g @railway/cli

# Shell script (macOS, Linux, Windows WSL)
bash <(curl -fsSL cli.new)

# Windows (Scoop)
scoop install railway
```

Verify installation: `railway --version`

## Authentication

```bash
# Browser-based login (default)
railway login

# Browserless login (for SSH sessions, CI/CD, headless environments)
railway login --browserless

# Logout
railway logout

# Check current user
railway whoami
railway whoami --json
```

### Token-Based Authentication (CI/CD)

| Token Type | Environment Variable | Scope |
|------------|---------------------|-------|
| Project Token | `RAILWAY_TOKEN` | Single project, limited actions (deploy, logs, redeploy) |
| Account Token | `RAILWAY_API_TOKEN` | All user workspaces, full CLI access |
| Team Token | `RAILWAY_API_TOKEN` | Single team workspace |

```bash
# Project-scoped deployment (CI/CD pipelines)
RAILWAY_TOKEN=xxx railway up --ci

# Account-scoped operations
RAILWAY_API_TOKEN=xxx railway init
```

Generate tokens in Railway dashboard under Project Settings or Account Settings.

## CLI Command Reference

### Project Management

```bash
# Create new project
railway init
railway init -n "project-name"
railway init -n "project-name" -w "workspace-name"

# Link directory to existing project
railway link
railway link -p "project-id-or-name"
railway link -p "project" -e "environment" -s "service"

# Unlink project
railway unlink
railway unlink -s  # Unlink service only

# List all projects
railway list
railway list --json

# View project status
railway status
railway status --json

# Open project in browser
railway open
```

### Deployment

```bash
# Deploy current directory
railway up                    # Deploy and stream logs
railway up --detach           # Deploy without log stream
railway up -d                 # Short form
railway up --ci               # Stream build logs only, exit when done
railway up -s "service-name"  # Deploy to specific service
railway up -e "environment"   # Deploy to specific environment
railway up /path/to/dir       # Deploy specific directory
railway up --no-gitignore     # Include gitignored files
railway up --verbose          # Verbose output

# Remove most recent deployment
railway down
railway down -y  # Skip confirmation

# Redeploy latest deployment
railway redeploy
railway redeploy -s "service-name"
railway redeploy -y  # Skip confirmation
```

### Service Management

```bash
# Link to a service (interactive)
railway service
railway service "service-name"

# Add service/database to project
railway add                              # Interactive
railway add -d postgres                  # Add database (postgres, mysql, redis, mongo)
railway add -s "my-service"              # Add named service
railway add -s "my-service" -r "owner/repo"  # Link to GitHub repo
railway add -s "my-service" -i "docker/image"  # Link to Docker image
railway add --variables "KEY=value"      # Set environment variables
```

### Environment Management

```bash
# Switch/link environment (interactive)
railway environment
railway environment "env-name"

# Create new environment
railway environment new "env-name"
railway environment new "env-name" -d "source-env"  # Duplicate from existing

# Delete environment
railway environment delete "env-name"
railway environment delete "env-name" -y  # Skip confirmation
```

### Variables

```bash
# View variables
railway variables
railway variables -s "service"
railway variables -e "environment"
railway variables -k  # KV format output
railway variables --json

# Set variables
railway variables --set "KEY=value"
railway variables --set "KEY1=val1" --set "KEY2=val2"
```

### Local Development

```bash
# Run command with Railway environment variables
railway run <command>
railway run npm start
railway run python main.py
railway run -s "service-name" <command>

# Open shell with Railway environment variables
railway shell
railway shell -s "service-name"
```

### Logs & Debugging

```bash
# View logs
railway logs              # Deployment logs (default)
railway logs -d           # Deployment logs (explicit)
railway logs -b           # Build logs
railway logs --json

# SSH into running service
railway ssh
railway ssh -p "project" -s "service" -e "environment"
railway ssh -- ls  # Run single command
```

### Database Connection

```bash
# Connect to database shell (interactive)
railway connect
railway connect "database-name"
railway connect -e "environment"
```

Supported: PostgreSQL (psql), MySQL (mysql), Redis (redis-cli), MongoDB (mongosh)

### Domain Management

```bash
# Generate Railway domain
railway domain

# Add custom domain
railway domain "custom.domain.com"

# Specify port
railway domain -p 3000

# For specific service
railway domain -s "service-name"
```

### Volume Management

```bash
railway volume list
railway volume add
railway volume delete
railway volume update
railway volume attach
railway volume detach
```

---

## Config as Code

Railway supports `railway.json` or `railway.toml` in project root. Config in code **always overrides** dashboard settings.

### Basic Example (railway.json)

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "RAILPACK",
    "buildCommand": "npm run build",
    "watchPatterns": ["src/**"]
  },
  "deploy": {
    "startCommand": "node dist/index.js",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300
  }
}
```

### Complete Configuration Reference

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "RAILPACK",
    "buildCommand": "npm run build",
    "watchPatterns": ["src/**", "package.json"],
    "dockerfilePath": "Dockerfile.backend",
    "railpackVersion": "0.7.0",
    "nixpacksVersion": "1.29.1",
    "nixpacksConfigPath": "nixpacks.toml",
    "nixpacksPlan": {
      "providers": ["python", "node"],
      "phases": {
        "setup": {
          "nixPkgs": ["ffmpeg", "imagemagick"],
          "aptPkgs": ["libpq-dev"]
        },
        "install": {
          "dependsOn": ["setup"],
          "cmds": ["pip install -r requirements.txt"]
        }
      }
    }
  },
  "deploy": {
    "startCommand": "node dist/index.js",
    "preDeployCommand": ["npm run db:migrate"],
    "numReplicas": 2,
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 5,
    "cronSchedule": "*/15 * * * *",
    "region": "us-west1",
    "sleepApplication": false,
    "runtime": "V2",
    "overlapSeconds": 60,
    "drainingSeconds": 10
  },
  "environments": {
    "production": {
      "build": {
        "buildCommand": "npm run build:prod"
      },
      "deploy": {
        "startCommand": "npm start",
        "numReplicas": 3
      }
    },
    "staging": {
      "deploy": {
        "startCommand": "npm run staging",
        "numReplicas": 1
      }
    },
    "pr": {
      "deploy": {
        "startCommand": "npm run pr",
        "numReplicas": 1
      }
    }
  }
}
```

### TOML Equivalent

```toml
[build]
builder = "RAILPACK"
buildCommand = "npm run build"
watchPatterns = ["src/**", "package.json"]

[deploy]
startCommand = "node dist/index.js"
preDeployCommand = ["npm run db:migrate"]
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 5
numReplicas = 2

[environments.production.deploy]
numReplicas = 3

[environments.staging.deploy]
numReplicas = 1
```

### Build Options

| Option | Type | Description |
|--------|------|-------------|
| `builder` | string | `RAILPACK` (default), `DOCKERFILE`, `NIXPACKS` (deprecated) |
| `buildCommand` | string | Build command (e.g., `npm run build`) |
| `watchPatterns` | string[] | Patterns to trigger deploys (e.g., `["src/**"]`) |
| `dockerfilePath` | string | Path to non-standard Dockerfile |
| `railpackVersion` | string | Specific Railpack version |

### Deploy Options

| Option | Type | Description |
|--------|------|-------------|
| `startCommand` | string | Command to start container |
| `preDeployCommand` | string/string[] | Run before start (e.g., migrations) |
| `numReplicas` | integer | Number of instances (1-200) |
| `healthcheckPath` | string | HTTP path for health check |
| `healthcheckTimeout` | number | Seconds to wait for healthy (default: 300) |
| `restartPolicyType` | string | `ON_FAILURE`, `ALWAYS`, `NEVER` |
| `restartPolicyMaxRetries` | number | Max restart attempts |
| `cronSchedule` | string | Cron expression (e.g., `*/15 * * * *`) |
| `region` | string | Deployment region |
| `sleepApplication` | boolean | Enable app sleeping |
| `overlapSeconds` | number | Zero-downtime overlap time |
| `drainingSeconds` | number | SIGTERM to SIGKILL buffer |

### Multi-Region Configuration

```json
{
  "deploy": {
    "multiRegionConfig": {
      "us-west2": { "numReplicas": 2 },
      "us-east4-eqdc4a": { "numReplicas": 2 },
      "europe-west4-drams3a": { "numReplicas": 2 },
      "asia-southeast1-eqsg3a": { "numReplicas": 2 }
    }
  }
}
```

---

## Environment Variables

### Variable Types

| Type | Scope | Usage |
|------|-------|-------|
| Service Variables | Single service | Define in service Variables tab |
| Shared Variables | Project-wide | Define in Project Settings |
| Reference Variables | Cross-service | Use `${{...}}` syntax |
| Sealed Variables | Extra security | Value never visible in UI/API |

### Reference Variable Syntax

```bash
# Reference shared variable
DATABASE_NAME=${{shared.DATABASE_NAME}}

# Reference another service's variable
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Reference variable in same service
FULL_URL=https://${{DOMAIN}}/${{API_PATH}}

# Reference Railway-provided variables from another service
BACKEND_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:${{api.PORT}}
```

### Railway-Provided Variables

| Variable | Description |
|----------|-------------|
| `PORT` | Port your app should listen on |
| `RAILWAY_PUBLIC_DOMAIN` | Public domain (e.g., `example.up.railway.app`) |
| `RAILWAY_PRIVATE_DOMAIN` | Private DNS (e.g., `service.railway.internal`) |
| `RAILWAY_TCP_PROXY_DOMAIN` | TCP proxy domain (if enabled) |
| `RAILWAY_TCP_PROXY_PORT` | External TCP proxy port |
| `RAILWAY_PROJECT_NAME` | Project name |
| `RAILWAY_PROJECT_ID` | Project ID |
| `RAILWAY_ENVIRONMENT_NAME` | Environment name |
| `RAILWAY_ENVIRONMENT_ID` | Environment ID |
| `RAILWAY_SERVICE_NAME` | Service name |
| `RAILWAY_SERVICE_ID` | Service ID |
| `RAILWAY_DEPLOYMENT_ID` | Deployment ID |
| `RAILWAY_REPLICA_ID` | Replica ID |
| `RAILWAY_REPLICA_REGION` | Region (e.g., `us-west2`) |
| `RAILWAY_VOLUME_NAME` | Attached volume name |
| `RAILWAY_VOLUME_MOUNT_PATH` | Volume mount path |

### Git Variables (GitHub deployments)

| Variable | Description |
|----------|-------------|
| `RAILWAY_GIT_COMMIT_SHA` | Commit SHA |
| `RAILWAY_GIT_AUTHOR` | Commit author |
| `RAILWAY_GIT_BRANCH` | Branch name |
| `RAILWAY_GIT_REPO_NAME` | Repository name |
| `RAILWAY_GIT_REPO_OWNER` | Repository owner |
| `RAILWAY_GIT_COMMIT_MESSAGE` | Commit message |

### Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RAILWAY_DOCKERFILE_PATH` | Custom Dockerfile path | `Dockerfile` |
| `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` | Healthcheck timeout | 300 |
| `RAILWAY_DEPLOYMENT_OVERLAP_SECONDS` | Overlap time | 0 |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | Drain time | 0 |
| `RAILWAY_RUN_UID` | UID for main process (0 = root) | - |
| `RAILWAY_SHM_SIZE_BYTES` | Shared memory size | 67108864 |

---

## Networking

### Port Configuration

Your app **MUST** listen on `0.0.0.0:$PORT` or `[::]:$PORT`. Railway auto-provides `PORT` if not defined.

**Node.js/Express:**
```javascript
const port = process.env.PORT || 3000;
app.listen(port, "::", () => console.log(`Listening on ${port}`));
```

**Python/Flask:**
```python
app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)))
```

**Python/Gunicorn:**
```bash
gunicorn app:app --bind [::]:${PORT:-3000}
```

**Python/Uvicorn:**
```bash
uvicorn app:app --host :: --port ${PORT:-3000}
```

**Next.js:**
```bash
next start --hostname :: --port ${PORT:-3000}
```

**Go/Fiber:**
```go
app.Listen(":" + os.Getenv("PORT"))
// With config: Network: "tcp"
```

### Public Networking

Generate a Railway domain in dashboard or CLI:
```bash
railway domain
```

- Domain format: `*.up.railway.app`
- Automatic HTTPS via Let's Encrypt
- TLS 1.2 and 1.3 supported
- All inbound traffic must be TLS-encrypted

**Limits:**
- Max concurrent connections: 10,000
- HTTP requests/sec: ~11,000 RPS
- Max header size: 32 KB
- Max request duration: 15 minutes
- Keep-alive timeout: 60 seconds

### Custom Domains

1. Go to Service Settings > + Custom Domain
2. Enter domain (wildcards supported: `*.example.com`)
3. Create CNAME record pointing to Railway's provided value
4. Wait for DNS propagation (up to 72 hours)

**Cloudflare users:** Set SSL/TLS to "Full" (NOT "Full Strict")

### Private Networking

Services in the same project communicate via internal DNS:
```
http://<service-name>.railway.internal:<port>
```

```javascript
// Example: Frontend calling backend API
axios.get("http://api.railway.internal:3000/users")
```

Using reference variables:
```bash
BACKEND_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:${{api.PORT}}
```

**Important caveats:**
- NOT available during build phase
- Cannot communicate between different projects/environments
- Client-side (browser) requests cannot use private network
- External services cannot access private network

### TCP Proxy (Non-HTTP Services)

For databases and non-HTTP services:

1. Go to Service Settings > TCP Proxy
2. Specify the port your service listens on
3. Railway generates `domain:port` for external access

---

## Databases

### Adding Databases

```bash
# CLI
railway add -d postgres   # PostgreSQL
railway add -d mysql      # MySQL
railway add -d redis      # Redis
railway add -d mongo      # MongoDB
```

Or use templates:
- PostgreSQL: `railway.com/template/postgres`
- MySQL: `railway.com/template/mysql`
- Redis: `railway.com/template/redis`
- MongoDB: `railway.com/template/mongodb`

### PostgreSQL Extensions

- TimescaleDB: `railway.com/template/VSbF5V`
- PostGIS: `railway.com/template/postgis`
- pgvector: `railway.com/template/3jJFCA`

### Connection Variables

Each database automatically creates environment variables:

**PostgreSQL:**
```
PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, DATABASE_URL
```

**MySQL:**
```
MYSQLHOST, MYSQLPORT, MYSQLUSER, MYSQLPASSWORD, MYSQLDATABASE, MYSQL_URL
```

**Redis:**
```
REDISHOST, REDISPORT, REDISUSER, REDISPASSWORD, REDIS_URL
```

**MongoDB:**
```
MONGOHOST, MONGOPORT, MONGOUSER, MONGOPASSWORD, MONGO_URL
```

### Referencing in Other Services

```bash
# In your app service's variables
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
```

### Library-Specific Configuration

**ioredis/bullmq (IPv6 support):**
```javascript
// Add family=0 for IPv4/IPv6 auto-detection
const redis = new Redis(process.env.REDIS_URL + "?family=0");
// Or in config: { family: 0 }
```

**MongoDB Docker (IPv6):**
```bash
mongod --ipv6 --bind_ip ::,0.0.0.0
```

---

## Build Configuration

### Builders

| Builder | Description |
|---------|-------------|
| `RAILPACK` | Default, modern optimized builder |
| `DOCKERFILE` | Use when Dockerfile present |
| `NIXPACKS` | Legacy, in maintenance mode |

### Railpack Environment Variables

| Variable | Description |
|----------|-------------|
| `RAILPACK_BUILD_CMD` | Override build command |
| `RAILPACK_INSTALL_CMD` | Override install command |
| `RAILPACK_START_CMD` | Override start command |
| `RAILPACK_PACKAGES` | Mise packages (e.g., `node@22 python@3.13`) |
| `RAILPACK_BUILD_APT_PACKAGES` | Apt packages for build phase |
| `RAILPACK_DEPLOY_APT_PACKAGES` | Apt packages in final image |
| `RAILPACK_DISABLE_CACHES` | Disable caches (`*` for all) |

### Railpack Config File (railpack.json)

```json
{
  "$schema": "https://schema.railpack.com",
  "provider": "node",
  "packages": {
    "node": "22",
    "python": "3.13"
  },
  "buildAptPackages": ["git", "curl"],
  "caches": {
    "npm-cache": {
      "directory": "/root/.npm",
      "type": "shared"
    }
  },
  "steps": {
    "install": {
      "commands": ["npm ci"]
    },
    "build": {
      "inputs": [{ "step": "install" }],
      "commands": ["...", "./custom-build.sh"]
    }
  },
  "deploy": {
    "startCommand": "node dist/index.js",
    "aptPackages": ["ffmpeg"],
    "variables": { "NODE_ENV": "production" }
  }
}
```

### Dockerfile Usage

Railway auto-detects `Dockerfile` at service root. Custom path:
```bash
RAILWAY_DOCKERFILE_PATH=/build/Dockerfile
```

Build-time variables require `ARG`:
```dockerfile
ARG RAILWAY_SERVICE_NAME
ARG MY_CUSTOM_VAR
RUN echo $RAILWAY_SERVICE_NAME
ENV APP_NAME=$MY_CUSTOM_VAR
```

### Disable Caching

```bash
NO_CACHE=1
# or
RAILPACK_DISABLE_CACHES=*
```

---

## Healthchecks

Required for zero-downtime deployments:

```json
{
  "deploy": {
    "healthcheckPath": "/health",
    "healthcheckTimeout": 300
  }
}
```

**Requirements:**
- Endpoint must return HTTP 200 when ready
- Default timeout: 300 seconds (5 minutes)
- Healthcheck requests come from hostname `healthcheck.railway.app`
- Only checked at deployment start, NOT continuous monitoring

**Example health endpoint (Express):**
```javascript
app.get('/health', (req, res) => {
  // Check database connection, etc.
  res.status(200).json({ status: 'healthy' });
});
```

---

## Deployment Lifecycle

### States

1. **Initializing**: Accepted into build queue
2. **Building**: Creating Docker image
3. **Deploying**: Starting container, running healthcheck
4. **Active**: Running and serving traffic
5. **Completed**: Process exited with code 0
6. **Crashed**: Process exited with non-zero code
7. **Failed**: Error during build or deploy

### Zero-Downtime Deployment

Configure overlap between old and new deployments:

```json
{
  "deploy": {
    "overlapSeconds": 60,
    "drainingSeconds": 10
  }
}
```

- `overlapSeconds`: Time old deployment stays active after new one is ready
- `drainingSeconds`: Time between SIGTERM and SIGKILL (default: 3 seconds)

### Rollbacks

Available via 3-dot menu on deployment in dashboard. Restores both Docker image AND custom variables.

---

## Scaling

### Vertical Autoscaling

Automatic, scales up to plan limits:
- Pro: 32 vCPU, 32GB RAM

### Horizontal Scaling (Replicas)

```json
{
  "deploy": {
    "numReplicas": 3
  }
}
```

**Note:** Replicas CANNOT be used with volumes.

### Multi-Region

```json
{
  "deploy": {
    "multiRegionConfig": {
      "us-west2": { "numReplicas": 2 },
      "europe-west4-drams3a": { "numReplicas": 1 }
    }
  }
}
```

Traffic automatically routes to nearest region.

---

## Volumes (Persistent Storage)

Create via Command Palette or right-click menu. Required for databases.

**Limits by plan:**
- Free/Trial: 0.5GB
- Hobby: 5GB
- Pro: 50GB (expandable)

**Important:**
- Only ONE volume per service
- Replicas CANNOT use volumes
- Brief downtime during redeploy (even with healthchecks)
- Volumes are mounted at runtime, NOT during build

---

## Common Workflows

### New Project Deployment

```bash
railway login
railway init -n "my-project"
railway add -d postgres
railway up
railway domain
railway open
```

### Deploy Existing Project

```bash
railway login
railway link
railway service  # Select service
railway up
```

### Local Development with Remote Services

```bash
railway link
railway run npm run dev
# or
railway shell
npm run dev
```

### CI/CD Pipeline

```bash
export RAILWAY_TOKEN=<project-token>
railway up --ci
```

### Database Migration

```json
{
  "deploy": {
    "preDeployCommand": ["npm run db:migrate"]
  }
}
```

### Cron Job

```json
{
  "deploy": {
    "startCommand": "python job.py",
    "cronSchedule": "0 */6 * * *",
    "restartPolicyType": "NEVER"
  }
}
```

---

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| 502 Bad Gateway | Not listening on correct port | Listen on `0.0.0.0:$PORT` |
| 502 Bad Gateway | Target port mismatch | Check port configuration matches app |
| Application failed to respond | App under heavy load | Scale replicas or resources |
| Private network not working | Used during build | Private network only available at runtime |
| Private network not working | Using IPv4 only | Bind to `::` for dual-stack |
| Service won't sleep | Active DB connections | Close idle connections |
| Service won't sleep | Framework telemetry | Disable telemetry (e.g., Next.js) |
| Volume issues | Using replicas | Volumes don't support replicas |
| Build fails | Missing system deps | Add via `RAILPACK_BUILD_APT_PACKAGES` |

### Debugging Commands

```bash
# View deployment logs
railway logs

# View build logs
railway logs -b

# SSH into running container
railway ssh

# Run command in container
railway ssh -- ls -la

# Check environment variables
railway variables
```

---

## Framework Examples

### Node.js/Express

```javascript
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.listen(port, '::', () => console.log(`Server on port ${port}`));
```

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "deploy": {
    "startCommand": "node index.js",
    "healthcheckPath": "/health"
  }
}
```

### Python/Django

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "buildCommand": "pip install -r requirements.txt && python manage.py collectstatic --noinput"
  },
  "deploy": {
    "preDeployCommand": ["python manage.py migrate"],
    "startCommand": "gunicorn myproject.wsgi --bind [::]:$PORT",
    "healthcheckPath": "/health/"
  }
}
```

### Next.js

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "buildCommand": "npm run build"
  },
  "deploy": {
    "startCommand": "npm start",
    "healthcheckPath": "/api/health"
  }
}
```

### Docker-based

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "healthcheckPath": "/",
    "restartPolicyType": "ALWAYS"
  }
}
```

---

## Best Practices

### Production Checklist

1. **Configure healthchecks** for zero-downtime deploys
2. **Use private networking** for service-to-service communication
3. **Set restart policy** to `ON_FAILURE` with reasonable retries
4. **Use reference variables** instead of hardcoding values
5. **Seal sensitive variables** that shouldn't be exposed
6. **Configure overlap/draining** for graceful shutdowns
7. **Use separate environments** for staging/production

### Security

- Use sealed variables for secrets
- Keep internal services off public internet (no domain)
- Use private networking for database connections
- Never commit secrets to repositories

### Performance

- Use watch patterns to avoid unnecessary deploys
- Enable app sleeping for non-critical services
- Use private networking to avoid egress costs
- Configure libraries for IPv6 when using private networking

---

## Documentation Links

- **Quick Start**: https://docs.railway.com/quick-start
- **CLI Reference**: https://docs.railway.com/reference/cli-api
- **Config as Code**: https://docs.railway.com/guides/config-as-code
- **Variables**: https://docs.railway.com/guides/variables
- **Networking**: https://docs.railway.com/guides/networking
- **Deployments**: https://docs.railway.com/guides/deployments
- **Databases**: https://docs.railway.com/guides/databases
- **Builds**: https://docs.railway.com/guides/builds
- **Best Practices**: https://docs.railway.com/overview/best-practices
- **Templates**: https://railway.com/templates
- **Error Reference**: https://docs.railway.com/reference/errors

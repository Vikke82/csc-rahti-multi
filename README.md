# Task Manager - Multi-Container Demo Application

A demonstrative web application showcasing multi-container deployment with React frontend and Python Flask backend, specifically designed for deployment on **CSC Rahti OpenShift platform**.

## 🏗️ Architecture

```
┌─────────────────┐    HTTP    ┌─────────────────┐
│   React SPA     │ ---------> │  Flask Backend  │
│  (Frontend)     │    API     │     (API)       │
│   Port: 8080    │            │   Port: 5000    │
└─────────────────┘            └─────────────────┘
```

## 🚀 Features

- **Frontend**: Modern React SPA with responsive design
- **Backend**: RESTful API built with Flask
- **Task Management**: Create, read, update, delete tasks
- **Health Checks**: Built-in health monitoring endpoints
- **Container Ready**: Dockerized with multi-stage builds
- **OpenShift Optimized**: Configured for CSC Rahti deployment
- **Security**: Non-root containers, security contexts
- **Monitoring**: Liveness and readiness probes

## 📁 Project Structure

```
.
├── backend/                 # Python Flask API
│   ├── app.py              # Main application
│   ├── requirements.txt    # Python dependencies
│   └── Dockerfile          # Backend container
├── frontend/               # React SPA
│   ├── src/                # React source code
│   ├── public/             # Static assets
│   ├── package.json        # Node dependencies
│   ├── Dockerfile          # Frontend container
│   └── nginx.conf          # Nginx configuration
├── openshift/              # CSC Rahti deployment configs
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── routes.yaml
│   ├── buildconfig.yaml
# Task Manager - Multi-Container Demo (CSC Rahti / OpenShift)

A small demo app showing a multi-container setup on OpenShift (CSC Rahti):
- Frontend: React SPA served by Nginx (port 8080)
- Backend: Flask API served by Gunicorn (port 5000)

The frontend proxies API requests under /api to the backend Service inside the cluster.

## Architecture

```
┌────────────────────────────┐    HTTP (Route)    ┌──────────────────────────┐
│   Nginx (+React build)     │  ────────────────▶ │   Flask API (Gunicorn)   │
│   Deploy: frontend         │   /api/* proxied   │   Deploy: backend        │
│   Container port: 8080     │   to Service       │   Container port: 5000   │
└────────────────────────────┘                    └──────────────────────────┘
```

Key detail: Nginx proxies /api/* to the backend Service name "backend" on port 5000 (same namespace). No CORS needed by default.

## Repository layout

```
.
├── backend/                 # Python Flask API
│   ├── app.py               # Endpoints: /health, /api/*
│   ├── requirements.txt
│   └── Dockerfile           # OpenShift-friendly (arbitrary UID)
├── frontend/                # React SPA
│   ├── src/                 # React source
│   ├── public/
│   ├── package.json
│   ├── Dockerfile           # Multi-stage: Node build → Nginx
│   └── nginx.conf           # Proxies /api to Service backend:5000
├── openshift/
│   ├── backend-deployment.yaml     # Deployment+Service (backend)
│   ├── frontend-deployment.yaml    # Deployment+Service (frontend)
│   └── routes.yaml                 # Routes for frontend and backend
├── docker-compose.yml
└── README.md
```

## Local development

Prerequisites: Docker Desktop, Node.js 18+, Python 3.11+ (optional for local-only dev).

Using Docker Compose
```bash
docker-compose up --build
# Frontend: http://localhost:3000 (serves Nginx:8080)
# Backend:  http://localhost:5000
# Health:   http://localhost:5000/health
```

Dev mode (optional)
```bash
# Backend (Windows)
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py

# Frontend
cd frontend
npm install
npm start
```

## Deploy to CSC Rahti (OpenShift)

You can deploy via Git-based Docker builds. This guide uses two BuildConfigs: backend and frontend.

Prerequisites
- CSC Rahti account and a project/namespace (e.g., task-manager-demo)
- oc CLI logged in: `oc login https://api.2.rahti.csc.fi:6443`
- This repo pushed to your own GitHub fork (see Students section)

Create BuildConfigs from your Git repo

PowerShell (Windows)
```powershell
# Replace with your fork URL
$REPO = "https://github.com/<YOUR_GH_USER>/csc-rahti-multi.git"

# Create (or recreate) BuildConfigs from Git (Docker strategy)
oc delete bc backend frontend 2>$null
oc new-build --strategy=docker --name=backend  $REPO --context-dir=backend
oc new-build --strategy=docker --name=frontend $REPO --context-dir=frontend

# Start builds and follow logs
oc start-build backend  --follow
oc start-build frontend --follow
```

Bash (Linux/macOS/WSL)
```bash
# Replace with your fork URL
REPO=https://github.com/<YOUR_GH_USER>/csc-rahti-multi.git

# Create (or recreate) BuildConfigs from Git (Docker strategy)
oc delete bc backend frontend >/dev/null 2>&1 || true
oc new-build --strategy=docker --name=backend  "$REPO" --context-dir=backend
oc new-build --strategy=docker --name=frontend "$REPO" --context-dir=frontend

# Start builds and follow logs
oc start-build backend  --follow
oc start-build frontend --follow
```

Apply Deployments/Services/Routes
```bash
oc apply -f openshift/backend-deployment.yaml
oc apply -f openshift/frontend-deployment.yaml
oc apply -f openshift/routes.yaml

# Optional: set Deployments to use ImageStream tags (simpler than registry URLs)
oc set image deploy/backend  backend=backend:latest
oc set image deploy/frontend frontend=frontend:latest

# Roll out and verify
oc rollout restart deploy/backend
oc rollout restart deploy/frontend
oc rollout status deploy/backend
oc rollout status deploy/frontend

# Test Routes
echo "Backend:  https://$(oc get route backend  -o jsonpath='{.spec.host}')/health"
echo "Frontend: https://$(oc get route frontend -o jsonpath='{.spec.host}')/"
```

Notes
- Images are stored in the project’s internal registry via ImageStreams (backend:latest, frontend:latest).
- Deployments reference those images (either by full registry URL or simply image: <name>:latest). Using ImageStream tags makes rollouts easier.

## How the Nginx proxy works (and common pitfalls)

- The frontend Nginx serves the compiled React app and proxies /api/* to backend:5000.
- Avoid trailing slash in proxy_pass when you want to preserve the prefix:
   - Good: `proxy_pass http://backend_svc;` (with upstream) or `proxy_pass http://backend:5000;`
   - Avoid: `proxy_pass http://backend:5000/;` (this strips the /api prefix)
- This repo uses a named upstream:
   ```nginx
   upstream backend_svc { server backend:5000; keepalive 32; }
   location /api/ { proxy_pass http://backend_svc; }
   ```

## API endpoints

Health & Info
- GET /health
- GET /api/info

Tasks
- GET /api/tasks
- POST /api/tasks
- PUT /api/tasks/{id}
- DELETE /api/tasks/{id}

Examples
```bash
# Replace with your backend route
BE=https://$(oc get route backend -o jsonpath='{.spec.host}')
curl -k $BE/health
curl -k $BE/api/tasks
curl -k -X POST $BE/api/tasks \
   -H "Content-Type: application/json" \
   -d '{"title":"Deploy to Rahti","completed":false}'
```

## Students: fork and onboard

Goal: each student forks the repo and deploys it to their own Rahti project.

1) Fork the repository
- Click "Fork" in GitHub → choose your account.
- Clone your fork locally and push any changes you need.

2) Create/select a Rahti project
```bash
oc login https://api.2.rahti.csc.fi:6443
oc new-project <your-unique-project-name>
```

3) Create builds from your fork

PowerShell (Windows)
```powershell
$REPO = "https://github.com/<YOUR_GH_USER>/csc-rahti-multi.git"
oc new-build --strategy=docker --name=backend  $REPO --context-dir=backend
oc new-build --strategy=docker --name=frontend $REPO --context-dir=frontend
oc start-build backend  --follow
oc start-build frontend --follow
```

Bash (Linux/macOS/WSL)
```bash
REPO=https://github.com/<YOUR_GH_USER>/csc-rahti-multi.git
oc new-build --strategy=docker --name=backend  "$REPO" --context-dir=backend
oc new-build --strategy=docker --name=frontend "$REPO" --context-dir=frontend
oc start-build backend  --follow
oc start-build frontend --follow
```

4) Deploy and wire
```bash
oc apply -f openshift/backend-deployment.yaml
oc apply -f openshift/frontend-deployment.yaml
oc apply -f openshift/routes.yaml

# Point Deployments at ImageStreams for simpler rollouts
oc set image deploy/backend  backend=backend:latest
oc set image deploy/frontend frontend=frontend:latest

oc rollout restart deploy/backend
oc rollout restart deploy/frontend
oc rollout status deploy/backend
oc rollout status deploy/frontend
```

5) Test

PowerShell (Windows)
```powershell
$BE = oc get route backend  -o jsonpath='{.spec.host}'
$FE = oc get route frontend -o jsonpath='{.spec.host}'
curl.exe -k https://$BE/health
curl.exe -k https://$FE/api/info
```

Bash (Linux/macOS/WSL)
```bash
BE=https://$(oc get route backend  -o jsonpath='{.spec.host}')
FE=https://$(oc get route frontend -o jsonpath='{.spec.host}')
curl -k $BE/health
curl -k $FE/api/info
```

## Shell differences: PowerShell vs Bash

- Variables
   - PowerShell: `$REPO = "https://..."` and reference as `$REPO`
   - Bash: `REPO=https://...` and reference as `$REPO`
- Redirecting output
   - PowerShell: `2>$null`
   - Bash: `>/dev/null 2>&1`
- curl
   - PowerShell: prefer `curl.exe` to avoid the `Invoke-WebRequest` alias
   - Bash: `curl` is fine
- Env vars inside commands
   - PowerShell: `$env:REPO`
   - Bash: `$REPO`
- Line continuation
   - PowerShell: backtick ` (or separate lines)
   - Bash: `\` at end of line

If your fork is private
```bash
oc create secret generic github-cred --type=kubernetes.io/basic-auth \
   --from-literal=username=<USER> \
   --from-literal=password=<GH_TOKEN>
oc set build-secret bc/backend  --source github-cred
oc set build-secret bc/frontend --source github-cred
```

## Troubleshooting

Nginx 404 on /api/*
- Likely `proxy_pass http://backend:5000/;` is stripping the /api prefix.
- Fix to `proxy_pass http://backend:5000;` or use the provided upstream config.

502 Bad Gateway on /api/*
- Check Nginx error log inside frontend pod:
   ```bash
   FPOD=$(oc get pods -l app=frontend -o name | head -n1)
   oc exec $FPOD -- tail -n 200 /var/log/nginx/error.log
   ```
- Ensure backend Service name is `backend` and port is 5000:
   `oc get svc backend -o yaml`

`npm ci` fails (lockfile out of sync)
- The Dockerfile falls back to `npm install` if `npm ci` fails.
- To restore reproducible builds, run `npm install` locally to regenerate `package-lock.json`, commit, rebuild in Rahti.

Uploads are slow with binary builds
- Prefer Git builds (`oc new-build … --context-dir=…`).
- If you must use binary builds, upload a tar without `node_modules`:
   `tar -czf frontend.tgz -C frontend --exclude node_modules --exclude build .`
   `oc start-build frontend --from-archive=frontend.tgz --follow`

Session expired / not logged in
- Re-login: `oc login https://api.2.rahti.csc.fi:6443 --token=<TOKEN>`

## Security & resources

- Containers are compatible with OpenShift’s arbitrary UID model (no fixed USER; group-writable paths).
- Probes, CPU/memory requests/limits are defined in the Deployments.
- Routes use TLS edge termination by default.

## License

Educational/demo use for CSC Rahti OpenShift.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Develop and test locally
4. Open a pull request

— Built for CSC Rahti OpenShift Platform —

CSC Rahti docs: https://rahti.csc.fi/
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
│   ├── deploy-to-rahti.sh  # Bash deployment script
│   └── deploy-to-rahti.ps1 # PowerShell deployment script
├── docker-compose.yml      # Local development
└── README.md
```

## 🛠️ Local Development

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for frontend development)
- Python 3.11+ (for backend development)

### Quick Start with Docker Compose

1. **Clone and navigate to the project:**
   ```bash
   git clone <your-repo-url>
   cd "Cloud Services kontti"
   ```

2. **Start the application:**
   ```bash
   docker-compose up --build
   ```

3. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000
   - Health checks: http://localhost:5000/health

### Development Mode

#### Backend Development
```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
python app.py
```

#### Frontend Development
```bash
cd frontend
npm install
npm start
```

## ☁️ CSC Rahti Deployment

### Prerequisites

1. **CSC Account**: Active CSC account with Rahti access
2. **OpenShift CLI**: Download from [OpenShift releases](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/)
3. **Git Repository**: Push your code to a Git repository (GitHub, GitLab, etc.)

### Step-by-Step Deployment

#### 1. Login to CSC Rahti
```bash
oc login --server=https://api.2.rahti.csc.fi:6443
```

#### 2. Update Build Configuration
Edit `openshift/buildconfig.yaml` and replace the Git repository URL:
```yaml
git:
  uri: https://github.com/your-username/your-repo.git  # Your actual repo
  ref: main
```

#### 3. Deploy Using Script

**Option A: Bash (Linux/Mac/WSL)**
```bash
chmod +x openshift/deploy-to-rahti.sh
./openshift/deploy-to-rahti.sh
```

**Option B: PowerShell (Windows)**
```powershell
.\openshift\deploy-to-rahti.ps1
```

#### 4. Manual Deployment Steps

If you prefer manual deployment:

```bash
# Create project
oc new-project task-manager-demo

# Create build configurations
oc apply -f openshift/buildconfig.yaml

# Start builds
oc start-build task-manager-backend-build
oc start-build task-manager-frontend-build

# Wait for builds to complete
oc logs -f bc/task-manager-backend-build
oc logs -f bc/task-manager-frontend-build

# Deploy applications
oc apply -f openshift/backend-deployment.yaml
oc apply -f openshift/frontend-deployment.yaml

# Create routes
oc apply -f openshift/routes.yaml

# Check deployment status
oc get pods
oc get routes
```

## 🔍 API Endpoints

### Health & Info
- `GET /health` - Health check endpoint
- `GET /api/info` - Application information

### Tasks API
- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task

### Example API Usage

```bash
# Health check
curl https://your-backend-route-url/health

# Get all tasks
curl https://your-backend-route-url/api/tasks

# Create a task
curl -X POST https://your-backend-route-url/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Deploy to Rahti", "completed": false}'
```

## 🛡️ Security Features

- **Non-root containers**: All containers run as non-root users
- **Security contexts**: Proper security contexts defined
- **HTTPS only**: Routes configured with TLS termination
- **Resource limits**: Memory and CPU limits configured
- **Health checks**: Liveness and readiness probes

## 📊 Monitoring & Logging

### Health Checks
- **Liveness Probe**: Ensures container is running
- **Readiness Probe**: Ensures container is ready to serve traffic
- **Health Endpoints**: `/health` for both frontend and backend

### Viewing Logs
```bash
# Backend logs
oc logs -f deployment/task-manager-backend

# Frontend logs
oc logs -f deployment/task-manager-frontend

# Build logs
oc logs -f bc/task-manager-backend-build
```

## 🔧 Configuration

### Environment Variables

#### Backend
- `FLASK_ENV`: Environment mode (development/production)
- `ENVIRONMENT`: Deployment environment identifier
- `PORT`: Server port (default: 5000)

#### Frontend
- `REACT_APP_API_URL`: Backend API URL

### Resource Limits

Current configuration:
- **Backend**: 128Mi-256Mi RAM, 100m-200m CPU
- **Frontend**: 64Mi-128Mi RAM, 50m-100m CPU

## 🚀 Scaling

Scale your application:
```bash
# Scale backend
oc scale deployment task-manager-backend --replicas=3

# Scale frontend
oc scale deployment task-manager-frontend --replicas=2
```

## 🔄 Updates

The application supports automatic updates through Git webhooks:

1. Push changes to your Git repository
2. OpenShift automatically triggers new builds
3. New images are deployed automatically

Manual update:
```bash
oc start-build task-manager-backend-build
oc start-build task-manager-frontend-build
```

## 🐛 Troubleshooting

### Common Issues

1. **Build Failures**: Check build logs with `oc logs bc/<build-config>`
2. **Pod Not Starting**: Check pod logs with `oc logs <pod-name>`
3. **Route Not Accessible**: Verify route with `oc get routes`
4. **API Connection Issues**: Check service endpoints with `oc get svc`

### Debug Commands

```bash
# Check all resources
oc get all -l app=task-manager

# Describe problematic pod
oc describe pod <pod-name>

# Check events
oc get events --sort-by=.metadata.creationTimestamp

# Port forward for debugging
oc port-forward svc/task-manager-backend-service 5000:5000
```

## 📝 License

This project is created for educational purposes and demonstration of multi-container applications on CSC Rahti platform.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with Docker Compose
5. Submit a pull request

---

**Built for CSC Rahti OpenShift Platform** 🚀

For more information about CSC Rahti, visit: https://rahti.csc.fi/
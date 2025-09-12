# CSC Rahti Deployment Script (PowerShell)
# This script deploys the Task Manager application to CSC Rahti OpenShift platform

Write-Host "🚀 Deploying Task Manager to CSC Rahti..." -ForegroundColor Green

# Check if oc CLI is installed
if (-not (Get-Command "oc" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ OpenShift CLI (oc) is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/" -ForegroundColor Yellow
    exit 1
}

# Check if logged in to OpenShift
try {
    $currentUser = oc whoami 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Not logged in"
    }
} catch {
    Write-Host "❌ You are not logged in to OpenShift." -ForegroundColor Red
    Write-Host "Please login first using: oc login --server=https://api.2.rahti.csc.fi:6443" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Logged in as: $currentUser" -ForegroundColor Green
$currentProject = oc project -q
Write-Host "✅ Current project: $currentProject" -ForegroundColor Green

# Create or switch to project
$PROJECT_NAME = "task-manager-demo"
try {
    oc get project $PROJECT_NAME 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "📁 Creating new project: $PROJECT_NAME" -ForegroundColor Cyan
        oc new-project $PROJECT_NAME --display-name="Task Manager Demo" --description="Multi-container demo application"
    } else {
        Write-Host "📁 Switching to project: $PROJECT_NAME" -ForegroundColor Cyan
        oc project $PROJECT_NAME
    }
} catch {
    Write-Host "❌ Error managing project: $_" -ForegroundColor Red
    exit 1
}

# Apply BuildConfigs and ImageStreams first
Write-Host "🔨 Creating BuildConfigs and ImageStreams..." -ForegroundColor Cyan
oc apply -f openshift/buildconfig.yaml

# Wait a moment for resources to be created
Start-Sleep -Seconds 5

# Start builds (you need to update the git repository URL in buildconfig.yaml)
Write-Host "🏗️  Starting builds..." -ForegroundColor Cyan
Write-Host "⚠️  Note: Update the Git repository URL in openshift/buildconfig.yaml before running builds" -ForegroundColor Yellow
# oc start-build task-manager-backend-build
# oc start-build task-manager-frontend-build

# Deploy applications
Write-Host "🚀 Deploying backend..." -ForegroundColor Cyan
oc apply -f openshift/backend-deployment.yaml

Write-Host "🚀 Deploying frontend..." -ForegroundColor Cyan
oc apply -f openshift/frontend-deployment.yaml

# Create routes
Write-Host "🌐 Creating routes..." -ForegroundColor Cyan
oc apply -f openshift/routes.yaml

# Wait for deployments
Write-Host "⏳ Waiting for deployments to be ready..." -ForegroundColor Cyan
oc rollout status deployment/task-manager-backend --timeout=300s
oc rollout status deployment/task-manager-frontend --timeout=300s

# Get route URLs
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Application URLs:" -ForegroundColor Yellow

try {
    $FRONTEND_URL = oc get route task-manager-frontend-route -o jsonpath='{.spec.host}' 2>$null
    $BACKEND_URL = oc get route task-manager-backend-route -o jsonpath='{.spec.host}' 2>$null
    
    if ($FRONTEND_URL) {
        Write-Host "🌐 Frontend: https://$FRONTEND_URL" -ForegroundColor Cyan
    }
    
    if ($BACKEND_URL) {
        Write-Host "🔧 Backend API: https://$BACKEND_URL" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️  Routes not yet available" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📊 Resource status:" -ForegroundColor Yellow
oc get pods -l app=task-manager
Write-Host ""
oc get services -l app=task-manager
Write-Host ""
oc get routes -l app=task-manager

Write-Host ""
Write-Host "🎉 Deployment to CSC Rahti completed!" -ForegroundColor Green
Write-Host "💡 To update the application, push changes to your Git repository and the builds will trigger automatically." -ForegroundColor Cyan

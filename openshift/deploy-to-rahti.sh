#!/bin/bash

# CSC Rahti Deployment Script
# This script deploys the Task Manager application to CSC Rahti OpenShift platform

echo "🚀 Deploying Task Manager to CSC Rahti..."

# Check if oc CLI is installed
if ! command -v oc &> /dev/null; then
    echo "❌ OpenShift CLI (oc) is not installed. Please install it first."
    echo "Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/"
    exit 1
fi

# Check if logged in to OpenShift
if ! oc whoami &> /dev/null; then
    echo "❌ You are not logged in to OpenShift."
    echo "Please login first using: oc login --server=https://api.2.rahti.csc.fi:6443"
    exit 1
fi

echo "✅ Logged in as: $(oc whoami)"
echo "✅ Current project: $(oc project -q)"

# Create or switch to project
PROJECT_NAME="task-manager-demo"
if ! oc get project $PROJECT_NAME &> /dev/null; then
    echo "📁 Creating new project: $PROJECT_NAME"
    oc new-project $PROJECT_NAME --display-name="Task Manager Demo" --description="Multi-container demo application"
else
    echo "📁 Switching to project: $PROJECT_NAME"
    oc project $PROJECT_NAME
fi

# Apply BuildConfigs and ImageStreams first
echo "🔨 Creating BuildConfigs and ImageStreams..."
oc apply -f openshift/buildconfig.yaml

# Wait a moment for resources to be created
sleep 5

# Start builds (you need to update the git repository URL in buildconfig.yaml)
echo "🏗️  Starting builds..."
echo "⚠️  Note: Update the Git repository URL in openshift/buildconfig.yaml before running builds"
# oc start-build task-manager-backend-build
# oc start-build task-manager-frontend-build

# Deploy applications
echo "🚀 Deploying backend..."
oc apply -f openshift/backend-deployment.yaml

echo "🚀 Deploying frontend..."
oc apply -f openshift/frontend-deployment.yaml

# Create routes
echo "🌐 Creating routes..."
oc apply -f openshift/routes.yaml

# Wait for deployments
echo "⏳ Waiting for deployments to be ready..."
oc rollout status deployment/task-manager-backend --timeout=300s
oc rollout status deployment/task-manager-frontend --timeout=300s

# Get route URLs
echo "✅ Deployment complete!"
echo ""
echo "📱 Application URLs:"
FRONTEND_URL=$(oc get route task-manager-frontend-route -o jsonpath='{.spec.host}')
BACKEND_URL=$(oc get route task-manager-backend-route -o jsonpath='{.spec.host}')

if [ ! -z "$FRONTEND_URL" ]; then
    echo "🌐 Frontend: https://$FRONTEND_URL"
fi

if [ ! -z "$BACKEND_URL" ]; then
    echo "🔧 Backend API: https://$BACKEND_URL"
fi

echo ""
echo "📊 Resource status:"
oc get pods -l app=task-manager
echo ""
oc get services -l app=task-manager
echo ""
oc get routes -l app=task-manager

echo ""
echo "🎉 Deployment to CSC Rahti completed!"
echo "💡 To update the application, push changes to your Git repository and the builds will trigger automatically."

from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# In-memory storage for demo purposes
tasks = [
    {"id": 1, "title": "Learn Docker", "completed": False, "created_at": "2025-01-01T10:00:00Z"},
    {"id": 2, "title": "Deploy to OpenShift", "completed": False, "created_at": "2025-01-01T11:00:00Z"},
    {"id": 3, "title": "Build React Frontend", "completed": True, "created_at": "2025-01-01T09:00:00Z"}
]

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for OpenShift"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    """Get all tasks"""
    return jsonify({
        "tasks": tasks,
        "total": len(tasks)
    })

@app.route('/api/tasks', methods=['POST'])
def create_task():
    """Create a new task"""
    data = request.get_json()
    
    if not data or 'title' not in data:
        return jsonify({"error": "Title is required"}), 400
    
    new_task = {
        "id": max([t["id"] for t in tasks], default=0) + 1,
        "title": data['title'],
        "completed": data.get('completed', False),
        "created_at": datetime.now().isoformat()
    }
    
    tasks.append(new_task)
    return jsonify(new_task), 201

@app.route('/api/tasks/<int:task_id>', methods=['PUT'])
def update_task(task_id):
    """Update a task"""
    data = request.get_json()
    task = next((t for t in tasks if t["id"] == task_id), None)
    
    if not task:
        return jsonify({"error": "Task not found"}), 404
    
    if 'title' in data:
        task['title'] = data['title']
    if 'completed' in data:
        task['completed'] = data['completed']
    
    return jsonify(task)

@app.route('/api/tasks/<int:task_id>', methods=['DELETE'])
def delete_task(task_id):
    """Delete a task"""
    global tasks
    tasks = [t for t in tasks if t["id"] != task_id]
    return jsonify({"message": "Task deleted successfully"})

@app.route('/api/info', methods=['GET'])
def get_info():
    """Get application information"""
    return jsonify({
        "app": "Task Manager Backend",
        "version": "1.0.0",
        "environment": os.environ.get('ENVIRONMENT', 'development'),
        "container_id": os.environ.get('HOSTNAME', 'unknown'),
        "tasks_count": len(tasks)
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)

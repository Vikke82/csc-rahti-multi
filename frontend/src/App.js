import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Prefer relative API path so Nginx can proxy to backend in Docker/OpenShift
const API_BASE_URL = process.env.REACT_APP_API_URL || '';

function App() {
  const [tasks, setTasks] = useState([]);
  const [newTask, setNewTask] = useState('');
  const [loading, setLoading] = useState(false);
  const [appInfo, setAppInfo] = useState(null);

  useEffect(() => {
    fetchTasks();
    fetchAppInfo();
  }, []);

  const fetchTasks = async () => {
    try {
      setLoading(true);
  const response = await axios.get(`${API_BASE_URL}/api/tasks`);
      setTasks(response.data.tasks);
    } catch (error) {
      console.error('Error fetching tasks:', error);
      alert('Failed to fetch tasks. Please check if the backend is running.');
    } finally {
      setLoading(false);
    }
  };

  const fetchAppInfo = async () => {
    try {
  const response = await axios.get(`${API_BASE_URL}/api/info`);
      setAppInfo(response.data);
    } catch (error) {
      console.error('Error fetching app info:', error);
    }
  };

  const addTask = async (e) => {
    e.preventDefault();
    if (!newTask.trim()) return;

    try {
  const response = await axios.post(`${API_BASE_URL}/api/tasks`, {
        title: newTask,
        completed: false
      });
      setTasks([...tasks, response.data]);
      setNewTask('');
    } catch (error) {
      console.error('Error adding task:', error);
      alert('Failed to add task');
    }
  };

  const toggleTask = async (taskId, completed) => {
    try {
  await axios.put(`${API_BASE_URL}/api/tasks/${taskId}`, {
        completed: !completed
      });
      setTasks(tasks.map(task => 
        task.id === taskId ? { ...task, completed: !completed } : task
      ));
    } catch (error) {
      console.error('Error updating task:', error);
      alert('Failed to update task');
    }
  };

  const deleteTask = async (taskId) => {
    try {
  await axios.delete(`${API_BASE_URL}/api/tasks/${taskId}`);
      setTasks(tasks.filter(task => task.id !== taskId));
    } catch (error) {
      console.error('Error deleting task:', error);
      alert('Failed to delete task');
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🚀 Ville's Task Manager</h1>
        <p>Multi-container Demo App for CSC Rahti</p>
        
        {appInfo && (
          <div className="app-info">
            <small>
              Backend Version: {appInfo.version} | 
              Environment: {appInfo.environment} | 
              Container: {appInfo.container_id}
            </small>
          </div>
        )}
      </header>

      <main className="App-main">
        <form onSubmit={addTask} className="task-form">
          <input
            type="text"
            value={newTask}
            onChange={(e) => setNewTask(e.target.value)}
            placeholder="Enter a new task..."
            className="task-input"
          />
          <button type="submit" className="add-button">Add Task</button>
        </form>

        {loading ? (
          <div className="loading">Loading tasks...</div>
        ) : (
          <div className="tasks-container">
            <h2>Tasks ({tasks.length})</h2>
            {tasks.length === 0 ? (
              <p className="no-tasks">No tasks yet. Add one above!</p>
            ) : (
              <ul className="tasks-list">
                {tasks.map(task => (
                  <li key={task.id} className={`task-item ${task.completed ? 'completed' : ''}`}>
                    <div className="task-content">
                      <input
                        type="checkbox"
                        checked={task.completed}
                        onChange={() => toggleTask(task.id, task.completed)}
                        className="task-checkbox"
                      />
                      <span className="task-title">{task.title}</span>
                      <small className="task-date">
                        {new Date(task.created_at).toLocaleDateString()}
                      </small>
                    </div>
                    <button
                      onClick={() => deleteTask(task.id)}
                      className="delete-button"
                    >
                      Delete
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </main>

      <footer className="App-footer">
        <p>Deployed on CSC Rahti OpenShift Platform</p>
      </footer>
    </div>
  );
}

export default App;

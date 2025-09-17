"use client";

import { useState, useEffect } from "react";
import { timeEntriesAPI, projectsAPI, tasksAPI } from '@/lib/api';

export default function TimePage() {
  const [isTracking, setIsTracking] = useState(false);
  const [currentTime, setCurrentTime] = useState("00:00:00");
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  // Form state
  const [selectedProject, setSelectedProject] = useState("");
  const [selectedTask, setSelectedTask] = useState("");
  const [notes, setNotes] = useState("");

  // Data state
  const [projects, setProjects] = useState<any[]>([]);
  const [tasks, setTasks] = useState<any[]>([]);
  const [timeEntries, setTimeEntries] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [timerStatus, setTimerStatus] = useState<any>(null);

  // Fetch projects, tasks, and time entries on load
  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true);

        const [projectsData, timeEntriesData, timerData] = await Promise.all([
          projectsAPI.list(),
          timeEntriesAPI.list({ limit: 10 }),
          timeEntriesAPI.getTimerStatus()
        ]);

        setProjects(projectsData);
        setTimeEntries(timeEntriesData);
        setTimerStatus(timerData);

        // If timer is running, set tracking state
        if (timerData.is_active) {
          setIsTracking(true);
          setStartTime(new Date(timerData.start_time));
          setSelectedProject(timerData.project_id);
          setSelectedTask(timerData.task_id);
          setNotes(timerData.notes || '');
        }
      } catch (error) {
        console.error('Failed to fetch data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
  }, []);

  // Fetch tasks when project changes
  useEffect(() => {
    if (selectedProject) {
      const fetchTasks = async () => {
        try {
          const tasksData = await tasksAPI.getByProject(selectedProject);
          setTasks(tasksData);
        } catch (error) {
          console.error('Failed to fetch tasks:', error);
        }
      };
      fetchTasks();
    } else {
      setTasks([]);
      setSelectedTask("");
    }
  }, [selectedProject]);

  // Timer effect
  useEffect(() => {
    let interval: NodeJS.Timeout;

    if (isTracking && startTime) {
      interval = setInterval(() => {
        const now = new Date();
        const elapsed = Math.floor((now.getTime() - startTime.getTime()) / 1000);
        setElapsedSeconds(elapsed);

        const hours = Math.floor(elapsed / 3600);
        const minutes = Math.floor((elapsed % 3600) / 60);
        const seconds = elapsed % 60;

        setCurrentTime(
          `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
        );
      }, 1000);
    } else {
      setCurrentTime("00:00:00");
      setElapsedSeconds(0);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isTracking, startTime]);

  const handleStartStop = async () => {
    try {
      if (isTracking) {
        // Stop timer
        await timeEntriesAPI.stopTimer();
        setIsTracking(false);
        setStartTime(null);
        setElapsedSeconds(0);
        setCurrentTime("00:00:00");

        // Refresh time entries
        const timeEntriesData = await timeEntriesAPI.list({ limit: 10 });
        setTimeEntries(timeEntriesData);

        // Clear form
        setSelectedProject("");
        setSelectedTask("");
        setNotes("");
      } else {
        // Start timer
        if (!selectedProject || !selectedTask) {
          alert('Please select a project and task before starting the timer.');
          return;
        }

        await timeEntriesAPI.startTimer(selectedProject, selectedTask, notes);
        setIsTracking(true);
        setStartTime(new Date());
      }
    } catch (error) {
      console.error('Failed to start/stop timer:', error);
      alert('Failed to start/stop timer. Please try again.');
    }
  };

  const handleReset = () => {
    if (isTracking) {
      if (confirm('Are you sure you want to reset the timer? This will stop the current session.')) {
        handleStartStop();
      }
    } else {
      setCurrentTime("00:00:00");
      setElapsedSeconds(0);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'APPROVED': return 'bg-green-100 text-green-800';
      case 'PENDING': return 'bg-yellow-100 text-yellow-800';
      case 'REJECTED': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Time Tracking</h1>
        <p className="text-gray-600">Log your time with our mobile-first timer</p>
      </div>

      <div className="bg-white rounded-lg shadow-lg p-8 mb-8">
        <div className="text-center mb-8">
          <div className="text-6xl font-mono font-bold text-gray-900 mb-4">
            {currentTime}
          </div>
          
          <div className="space-x-4">
            <button
              onClick={handleStartStop}
              disabled={isLoading}
              className={`px-8 py-3 rounded-lg font-semibold text-lg transition-colors disabled:opacity-50 ${
                isTracking
                  ? "bg-red-600 hover:bg-red-700 text-white"
                  : "bg-green-600 hover:bg-green-700 text-white"
              }`}
            >
              {isTracking ? "Stop" : "Start"}
            </button>

            <button
              onClick={handleReset}
              disabled={isLoading}
              className="px-8 py-3 bg-gray-300 hover:bg-gray-400 text-gray-700 rounded-lg font-semibold text-lg transition-colors disabled:opacity-50"
            >
              Reset
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Project
            </label>
            <select
              value={selectedProject}
              onChange={(e) => setSelectedProject(e.target.value)}
              disabled={isTracking || isLoading}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:opacity-50"
            >
              <option value="">Select a project...</option>
              {projects.map((project) => (
                <option key={project.id} value={project.id}>
                  {project.client_name} - {project.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Task
            </label>
            <select
              value={selectedTask}
              onChange={(e) => setSelectedTask(e.target.value)}
              disabled={isTracking || isLoading || !selectedProject}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:opacity-50"
            >
              <option value="">Select a task...</option>
              {tasks.map((task) => (
                <option key={task.id} value={task.id}>
                  {task.name} ({task.category})
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="mt-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Notes
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            disabled={isTracking}
            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100 disabled:opacity-50"
            rows={3}
            placeholder="Add notes about what you're working on..."
          />
        </div>
      </div>

      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Recent Entries</h3>
        </div>
        
        <div className="divide-y divide-gray-200">
          {isLoading ? (
            <div className="p-6 flex items-center justify-center">
              <div className="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : timeEntries.length > 0 ? (
            timeEntries.map((entry) => {
              const duration = Math.round(entry.duration_minutes / 60 * 10) / 10;
              const startTime = new Date(entry.start_at);
              const endTime = entry.end_at ? new Date(entry.end_at) : null;

              return (
                <div key={entry.id} className="p-6 flex justify-between items-center">
                  <div>
                    <p className="font-medium text-gray-900">
                      {entry.project_name || 'Unknown Project'} - {entry.task_name || 'Task'}
                    </p>
                    <p className="text-sm text-gray-500">
                      {startTime.toLocaleDateString()}, {startTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                      {endTime && ` - ${endTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}`}
                    </p>
                    <p className="text-sm text-gray-600">
                      {entry.notes || 'No description'}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-blue-600">{duration}h</p>
                    <span className={`inline-block px-2 py-1 text-xs rounded-full ${getStatusColor(entry.status)}`}>
                      {entry.status || 'Draft'}
                    </span>
                  </div>
                </div>
              );
            })
          ) : (
            <div className="p-6 text-center text-gray-500">
              No time entries found. Start tracking your first session above!
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
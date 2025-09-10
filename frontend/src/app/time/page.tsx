"use client";

import { useState } from "react";

export default function TimePage() {
  const [isTracking, setIsTracking] = useState(false);
  const [currentTime, setCurrentTime] = useState("00:00:00");

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
              onClick={() => setIsTracking(!isTracking)}
              className={`px-8 py-3 rounded-lg font-semibold text-lg transition-colors ${
                isTracking
                  ? "bg-red-600 hover:bg-red-700 text-white"
                  : "bg-green-600 hover:bg-green-700 text-white"
              }`}
            >
              {isTracking ? "Stop" : "Start"}
            </button>
            
            <button className="px-8 py-3 bg-gray-300 hover:bg-gray-400 text-gray-700 rounded-lg font-semibold text-lg transition-colors">
              Reset
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Project
            </label>
            <select className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <option>Select a project...</option>
              <option>ACME Corp - Website Redesign</option>
              <option>TechCorp - Mobile App</option>
              <option>StartupXYZ - Consultation</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Task
            </label>
            <select className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent">
              <option>Select a task...</option>
              <option>Development</option>
              <option>Design</option>
              <option>Consultation</option>
              <option>Project Management</option>
            </select>
          </div>
        </div>

        <div className="mt-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Notes
          </label>
          <textarea
            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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
          <div className="p-6 flex justify-between items-center">
            <div>
              <p className="font-medium text-gray-900">ACME Corp - Development</p>
              <p className="text-sm text-gray-500">Today, 2:30 PM - 4:30 PM</p>
              <p className="text-sm text-gray-600">Working on authentication system</p>
            </div>
            <div className="text-right">
              <p className="font-semibold text-blue-600">2.0h</p>
              <span className="inline-block px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full">
                Approved
              </span>
            </div>
          </div>

          <div className="p-6 flex justify-between items-center">
            <div>
              <p className="font-medium text-gray-900">TechCorp - Consultation</p>
              <p className="text-sm text-gray-500">Yesterday, 10:00 AM - 11:30 AM</p>
              <p className="text-sm text-gray-600">Requirements gathering session</p>
            </div>
            <div className="text-right">
              <p className="font-semibold text-blue-600">1.5h</p>
              <span className="inline-block px-2 py-1 text-xs bg-yellow-100 text-yellow-800 rounded-full">
                Pending
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
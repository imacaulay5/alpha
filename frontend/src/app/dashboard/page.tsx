'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usersAPI, timeEntriesAPI } from '@/lib/api';

export default function DashboardPage() {
  const [currentTime, setCurrentTime] = useState(new Date());
  const [user, setUser] = useState<any>(null);
  const [recentTimeEntries, setRecentTimeEntries] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Update time every minute
  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 60000);
    return () => clearInterval(timer);
  }, []);

  // Fetch user data and recent time entries
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setIsLoading(true);

        // Get current user
        const userData = await usersAPI.getCurrent();
        setUser(userData);

        // Get recent time entries (last 10)
        const timeEntriesData = await timeEntriesAPI.list({
          limit: 10,
          skip: 0
        });
        setRecentTimeEntries(timeEntriesData);
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: true 
    });
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { 
      weekday: 'long',
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center space-x-4">
              <h1 className="text-3xl font-bold text-gray-900">Alpha</h1>
              <div className="hidden md:block h-6 w-px bg-gray-300"></div>
              <div className="hidden md:block">
                <p className="text-sm text-gray-500">{formatDate(currentTime)}</p>
                <p className="text-lg font-semibold text-gray-900">{formatTime(currentTime)}</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/time" className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg font-medium transition-colors duration-200">
                Start Timer
              </Link>
              <div className="w-8 h-8 bg-indigo-600 rounded-full flex items-center justify-center">
                <span className="text-white text-sm font-semibold">
                  {user ? user.name.split(' ').map((n: string) => n[0]).join('').slice(0, 2).toUpperCase() : 'U'}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Welcome Section */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Good {new Date().getHours() < 12 ? 'morning' : new Date().getHours() < 18 ? 'afternoon' : 'evening'}, {user ? user.name.split(' ')[0] : 'there'}! 👋
          </h2>
          <p className="text-gray-600">Here's what's happening with your projects today.</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <span className="text-sm text-green-600 font-medium bg-green-50 px-2 py-1 rounded-full">+12%</span>
            </div>
            <h3 className="text-sm font-medium text-gray-500 mb-1">Hours Today</h3>
            <p className="text-3xl font-bold text-gray-900">7.5</p>
            <p className="text-sm text-gray-600 mt-1">Billable hours logged</p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-amber-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <span className="text-sm text-amber-600 font-medium bg-amber-50 px-2 py-1 rounded-full">3 pending</span>
            </div>
            <h3 className="text-sm font-medium text-gray-500 mb-1">Pending Approvals</h3>
            <p className="text-3xl font-bold text-gray-900">3</p>
            <p className="text-sm text-gray-600 mt-1">Items awaiting approval</p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <span className="text-sm text-emerald-600 font-medium bg-emerald-50 px-2 py-1 rounded-full">Ready</span>
            </div>
            <h3 className="text-sm font-medium text-gray-500 mb-1">Draft Invoices</h3>
            <p className="text-3xl font-bold text-gray-900">2</p>
            <p className="text-sm text-gray-600 mt-1">Ready to send</p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow duration-200">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1" />
                </svg>
              </div>
              <span className="text-sm text-purple-600 font-medium bg-purple-50 px-2 py-1 rounded-full">Overdue</span>
            </div>
            <h3 className="text-sm font-medium text-gray-500 mb-1">Outstanding AR</h3>
            <p className="text-3xl font-bold text-gray-900">$12,450</p>
            <p className="text-sm text-gray-600 mt-1">Awaiting payment</p>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Recent Time Entries */}
          <div className="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-100">
            <div className="p-6 border-b border-gray-100">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900">Recent Time Entries</h3>
                <Link href="/time" className="text-indigo-600 hover:text-indigo-700 text-sm font-medium">
                  View all →
                </Link>
              </div>
            </div>
            <div className="p-6 space-y-4">
              {isLoading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="w-8 h-8 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
                </div>
              ) : recentTimeEntries.length > 0 ? (
                recentTimeEntries.map((entry, index) => {
                  const colors = ['indigo', 'emerald', 'purple', 'blue', 'amber'];
                  const color = colors[index % colors.length];
                  const projectInitials = entry.project_name ? entry.project_name.split(' ').map((n: string) => n[0]).join('').slice(0, 2).toUpperCase() : 'PR';
                  const duration = Math.round(entry.duration_minutes / 60 * 10) / 10;
                  const rate = entry.calculated_rate || 0;
                  const amount = duration * rate;

                  return (
                    <div key={entry.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors duration-200">
                      <div className="flex items-center space-x-4">
                        <div className={`w-10 h-10 bg-${color}-100 rounded-lg flex items-center justify-center`}>
                          <span className={`text-${color}-600 font-semibold text-sm`}>{projectInitials}</span>
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{entry.project_name || 'Unknown Project'} - {entry.task_name || 'Task'}</p>
                          <p className="text-sm text-gray-500">
                            {entry.notes || 'No description'} • {new Date(entry.start_at).toLocaleDateString()}
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className={`text-lg font-semibold text-${color}-600`}>{duration}h</p>
                        <p className="text-xs text-gray-500">${amount.toFixed(2)}</p>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div className="text-center py-8 text-gray-500">
                  No time entries found. <Link href="/time" className="text-indigo-600 hover:text-indigo-700">Log your first entry →</Link>
                </div>
              )}
            </div>
          </div>

          {/* Upcoming Deadlines & Quick Actions */}
          <div className="space-y-6">
            {/* Upcoming Deadlines */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100">
              <div className="p-6 border-b border-gray-100">
                <h3 className="text-lg font-semibold text-gray-900">Upcoming Deadlines</h3>
              </div>
              <div className="p-6 space-y-4">
                <div className="flex items-center justify-between p-4 bg-red-50 rounded-lg border border-red-100">
                  <div>
                    <p className="font-medium text-gray-900">ACME Corp Invoice #001</p>
                    <p className="text-sm text-red-600">Due in 2 days</p>
                  </div>
                  <span className="text-red-700 font-semibold">$4,500</span>
                </div>
                
                <div className="flex items-center justify-between p-4 bg-amber-50 rounded-lg border border-amber-100">
                  <div>
                    <p className="font-medium text-gray-900">Project Milestone Review</p>
                    <p className="text-sm text-amber-600">Due in 5 days</p>
                  </div>
                  <span className="text-amber-700 font-semibold">Review</span>
                </div>

                <div className="flex items-center justify-between p-4 bg-blue-50 rounded-lg border border-blue-100">
                  <div>
                    <p className="font-medium text-gray-900">Weekly Time Report</p>
                    <p className="text-sm text-blue-600">Due Friday</p>
                  </div>
                  <span className="text-blue-700 font-semibold">Submit</span>
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100">
              <div className="p-6 border-b border-gray-100">
                <h3 className="text-lg font-semibold text-gray-900">Quick Actions</h3>
              </div>
              <div className="p-6 space-y-3">
                <Link href="/time" className="flex items-center p-3 bg-indigo-50 rounded-lg hover:bg-indigo-100 transition-colors duration-200 group">
                  <div className="w-8 h-8 bg-indigo-500 rounded-lg flex items-center justify-center mr-3">
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                  </div>
                  <span className="text-gray-900 font-medium group-hover:text-indigo-700">Log Time Entry</span>
                </Link>

                <Link href="/invoices" className="flex items-center p-3 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors duration-200 group">
                  <div className="w-8 h-8 bg-emerald-500 rounded-lg flex items-center justify-center mr-3">
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                  </div>
                  <span className="text-gray-900 font-medium group-hover:text-emerald-700">Create Invoice</span>
                </Link>

                <Link href="/expenses" className="flex items-center p-3 bg-purple-50 rounded-lg hover:bg-purple-100 transition-colors duration-200 group">
                  <div className="w-8 h-8 bg-purple-500 rounded-lg flex items-center justify-center mr-3">
                    <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                  </div>
                  <span className="text-gray-900 font-medium group-hover:text-purple-700">Add Expense</span>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
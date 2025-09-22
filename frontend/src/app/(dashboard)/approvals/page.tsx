'use client';

import { useState, useEffect } from 'react';
import { timeEntriesAPI, usersAPI } from '@/lib/api';

export default function ApprovalsPage() {
  const [pendingItems, setPendingItems] = useState<any[]>([]);
  const [recentDecisions, setRecentDecisions] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedTab, setSelectedTab] = useState('pending');
  const [searchTerm, setSearchTerm] = useState('');
  const [filterUser, setFilterUser] = useState('');

  // Mock data - replace with actual API calls
  const mockPendingItems = [
    {
      id: '1',
      type: 'TIME',
      user_name: 'John Contractor',
      user_email: 'contractor@demo.com',
      project_name: 'Website Redesign',
      task_name: 'Frontend Development',
      start_at: '2024-01-15T09:00:00Z',
      end_at: '2024-01-15T17:30:00Z',
      duration_minutes: 510,
      notes: 'Worked on responsive layout implementation',
      submitted_at: '2024-01-15T18:00:00Z',
      amount: 765.00
    },
    {
      id: '2',
      type: 'TIME',
      user_name: 'Sarah Developer',
      user_email: 'sarah@demo.com',
      project_name: 'Mobile App',
      task_name: 'Backend API',
      start_at: '2024-01-16T10:00:00Z',
      end_at: '2024-01-16T16:00:00Z',
      duration_minutes: 360,
      notes: 'Implemented user authentication endpoints',
      submitted_at: '2024-01-16T16:30:00Z',
      amount: 540.00
    },
    {
      id: '3',
      type: 'EXPENSE',
      user_name: 'Mike Consultant',
      user_email: 'mike@demo.com',
      project_name: 'Cloud Migration',
      task_name: 'Infrastructure Setup',
      amount: 125.50,
      description: 'AWS hosting costs for development environment',
      submitted_at: '2024-01-14T14:00:00Z',
      receipt_url: 'https://example.com/receipt.pdf'
    }
  ];

  const mockRecentDecisions = [
    {
      id: '4',
      type: 'TIME',
      user_name: 'John Contractor',
      project_name: 'Website Redesign',
      task_name: 'UI Design',
      duration_minutes: 480,
      amount: 720.00,
      decision: 'APPROVED',
      decided_at: '2024-01-14T10:30:00Z',
      decided_by: 'Manager User'
    },
    {
      id: '5',
      type: 'EXPENSE',
      user_name: 'Sarah Developer',
      project_name: 'Mobile App',
      description: 'Software license fee',
      amount: 299.00,
      decision: 'REJECTED',
      decided_at: '2024-01-13T15:20:00Z',
      decided_by: 'Manager User',
      comment: 'Please use company license instead'
    }
  ];

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setIsLoading(true);
      // TODO: Replace with actual API calls
      setPendingItems(mockPendingItems);
      setRecentDecisions(mockRecentDecisions);
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleApproval = async (itemId: string, decision: 'APPROVE' | 'REJECT', comment?: string) => {
    try {
      // TODO: Implement actual API call
      console.log(`${decision} item ${itemId}`, comment);

      // Remove from pending items
      setPendingItems(prev => prev.filter(item => item.id !== itemId));

      // Add to recent decisions (mock)
      const item = pendingItems.find(p => p.id === itemId);
      if (item) {
        const newDecision = {
          ...item,
          decision,
          decided_at: new Date().toISOString(),
          decided_by: 'Current User',
          comment
        };
        setRecentDecisions(prev => [newDecision, ...prev]);
      }
    } catch (error) {
      console.error('Failed to process approval:', error);
    }
  };

  const getTypeIcon = (type: string) => {
    if (type === 'TIME') {
      return (
        <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      );
    } else {
      return (
        <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      );
    }
  };

  const getDecisionColor = (decision: string) => {
    switch (decision) {
      case 'APPROVED': return 'bg-green-100 text-green-800';
      case 'REJECTED': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const tabs = [
    { id: 'pending', name: 'Pending', count: pendingItems.length },
    { id: 'recent', name: 'Recent Decisions', count: recentDecisions.length },
  ];

  const filteredItems = selectedTab === 'pending' ? pendingItems : recentDecisions;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Approvals</h1>
            <p className="text-gray-600 mt-1">Review and approve time entries and expenses</p>
          </div>
          <div className="mt-4 sm:mt-0 flex items-center space-x-4">
            <span className="flex items-center text-sm text-gray-600">
              <div className="w-2 h-2 bg-amber-500 rounded-full mr-2"></div>
              {pendingItems.length} pending approval{pendingItems.length !== 1 ? 's' : ''}
            </span>
          </div>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200 mb-6">
          <nav className="-mb-px flex space-x-8">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setSelectedTab(tab.id)}
                className={`flex items-center space-x-2 py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                  selectedTab === tab.id
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <span>{tab.name}</span>
                <span className={`px-2 py-1 rounded-full text-xs ${
                  selectedTab === tab.id ? 'bg-indigo-100 text-indigo-600' : 'bg-gray-100 text-gray-600'
                }`}>
                  {tab.count}
                </span>
              </button>
            ))}
          </nav>
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <svg className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Search submissions..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 placeholder-gray-500 bg-white"
              />
            </div>
          </div>
          <select
            value={filterUser}
            onChange={(e) => setFilterUser(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
          >
            <option value="">All Users</option>
            <option value="john">John Contractor</option>
            <option value="sarah">Sarah Developer</option>
            <option value="mike">Mike Consultant</option>
          </select>
        </div>
      </div>

      {/* Items List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="w-8 h-8 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredItems.length > 0 ? (
            filteredItems.map((item) => (
              <div key={item.id} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-3">
                      <div className="flex-shrink-0">
                        <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
                          {getTypeIcon(item.type)}
                        </div>
                      </div>
                      <div>
                        <div className="flex items-center space-x-2">
                          <h3 className="text-lg font-semibold text-gray-900">{item.user_name}</h3>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            item.type === 'TIME' ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
                          }`}>
                            {item.type}
                          </span>
                          {item.decision && (
                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getDecisionColor(item.decision)}`}>
                              {item.decision}
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-600">{item.project_name} • {item.task_name || item.description}</p>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
                      {item.type === 'TIME' && (
                        <>
                          <div>
                            <p className="text-xs text-gray-500 uppercase tracking-wide">Duration</p>
                            <p className="text-sm font-medium text-gray-900">
                              {Math.round(item.duration_minutes / 60 * 10) / 10}h
                            </p>
                          </div>
                          <div>
                            <p className="text-xs text-gray-500 uppercase tracking-wide">Period</p>
                            <p className="text-sm font-medium text-gray-900">
                              {new Date(item.start_at).toLocaleDateString()} - {new Date(item.end_at).toLocaleDateString()}
                            </p>
                          </div>
                        </>
                      )}
                      <div>
                        <p className="text-xs text-gray-500 uppercase tracking-wide">Amount</p>
                        <p className="text-lg font-bold text-gray-900">${item.amount.toFixed(2)}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 uppercase tracking-wide">Submitted</p>
                        <p className="text-sm font-medium text-gray-900">
                          {new Date(item.submitted_at || item.decided_at).toLocaleDateString()}
                        </p>
                      </div>
                    </div>

                    {(item.notes || item.description) && (
                      <div className="mb-4">
                        <p className="text-xs text-gray-500 uppercase tracking-wide mb-1">Notes</p>
                        <p className="text-sm text-gray-700">{item.notes || item.description}</p>
                      </div>
                    )}

                    {item.comment && (
                      <div className="mb-4">
                        <p className="text-xs text-gray-500 uppercase tracking-wide mb-1">Decision Comment</p>
                        <p className="text-sm text-gray-700">{item.comment}</p>
                      </div>
                    )}

                    {item.receipt_url && (
                      <div className="mb-4">
                        <a
                          href={item.receipt_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center text-sm text-indigo-600 hover:text-indigo-700"
                        >
                          <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.586-6.586a2 2 0 00-2.828-2.828l-6.586 6.586a2 2 0 002.828 2.828L16 9" />
                          </svg>
                          View Receipt
                        </a>
                      </div>
                    )}
                  </div>

                  {selectedTab === 'pending' && (
                    <div className="flex items-center space-x-2 ml-4">
                      <button
                        onClick={() => handleApproval(item.id, 'REJECT')}
                        className="inline-flex items-center px-3 py-2 border border-red-300 text-red-700 bg-red-50 rounded-lg hover:bg-red-100 font-medium transition-colors"
                      >
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                        Reject
                      </button>
                      <button
                        onClick={() => handleApproval(item.id, 'APPROVE')}
                        className="inline-flex items-center px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium transition-colors"
                      >
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                        Approve
                      </button>
                    </div>
                  )}

                  {selectedTab === 'recent' && item.decided_by && (
                    <div className="ml-4 text-right">
                      <p className="text-xs text-gray-500 uppercase tracking-wide">Decided by</p>
                      <p className="text-sm font-medium text-gray-900">{item.decided_by}</p>
                    </div>
                  )}
                </div>
              </div>
            ))
          ) : (
            <div className="text-center py-12 bg-white rounded-xl shadow-sm border border-gray-100">
              <div className="text-gray-400 mb-4">
                <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {selectedTab === 'pending' ? 'No pending approvals' : 'No recent decisions'}
              </h3>
              <p className="text-gray-500">
                {selectedTab === 'pending'
                  ? 'All caught up! No items are waiting for approval.'
                  : 'No approval decisions have been made recently.'
                }
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
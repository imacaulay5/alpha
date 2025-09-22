'use client';

import { useState, useEffect } from 'react';
import { projectsAPI, clientsAPI, tasksAPI } from '@/lib/api';

export default function RulesPage() {
  const [rules, setRules] = useState<any[]>([]);
  const [clients, setClients] = useState<any[]>([]);
  const [projects, setProjects] = useState<any[]>([]);
  const [tasks, setTasks] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showCreateRule, setShowCreateRule] = useState(false);
  const [selectedScope, setSelectedScope] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [showEditRule, setShowEditRule] = useState(false);
  const [editingRule, setEditingRule] = useState<any>(null);

  // Mock rules data - replace with actual API calls
  const mockRules = [
    {
      id: '1',
      name: 'Weekend Premium Rate',
      scope: 'ORG',
      scope_name: 'Organization Wide',
      priority: 1,
      active: true,
      conditions: {
        day_of_week: ['SAT', 'SUN'],
        task_category: 'Development'
      },
      effects: {
        rate: { op: 'multiply', value: 1.5 },
        min_increment_min: { op: 'set', value: 30 }
      },
      created_at: '2024-01-10T10:00:00Z'
    },
    {
      id: '2',
      name: 'ACME Corp Onsite Premium',
      scope: 'CLIENT',
      scope_name: 'ACME Corporation',
      priority: 2,
      active: true,
      conditions: {
        task_category: 'Onsite',
        time_of_day: { from: '09:00', to: '17:00' }
      },
      effects: {
        rate: { op: 'set', value: 185.00 },
        materials_markup_pct: { op: 'set', value: 15 }
      },
      created_at: '2024-01-08T14:30:00Z'
    },
    {
      id: '3',
      name: 'After Hours Multiplier',
      scope: 'PROJECT',
      scope_name: 'Emergency Support Project',
      priority: 3,
      active: true,
      conditions: {
        time_of_day: { from: '18:00', to: '06:00' }
      },
      effects: {
        overtime_multiplier: { op: 'set', value: 2.0 }
      },
      created_at: '2024-01-05T16:45:00Z'
    },
    {
      id: '4',
      name: 'Senior Developer Rate',
      scope: 'USER',
      scope_name: 'Sarah Developer',
      priority: 4,
      active: false,
      conditions: {
        role_title: 'Senior Developer'
      },
      effects: {
        rate: { op: 'set', value: 200.00 }
      },
      created_at: '2024-01-03T11:20:00Z'
    }
  ];

  const [newRule, setNewRule] = useState({
    name: '',
    scope: 'ORG',
    scope_id: '',
    priority: 1,
    active: true,
    conditions: {
      day_of_week: [],
      time_of_day: { from: '', to: '' },
      task_category: '',
      location: ''
    },
    effects: {
      rate: { op: 'set', value: '' },
      min_increment_min: { op: 'set', value: '' },
      overtime_multiplier: { op: 'set', value: '' },
      materials_markup_pct: { op: 'set', value: '' }
    }
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      setIsLoading(true);
      const [projectsData, clientsData] = await Promise.all([
        projectsAPI.list(),
        clientsAPI.list()
      ]);
      setProjects(projectsData);
      setClients(clientsData);
      setRules(mockRules); // Replace with actual rules API call
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getScopeColor = (scope: string) => {
    switch (scope) {
      case 'ORG': return 'bg-purple-100 text-purple-800';
      case 'CLIENT': return 'bg-blue-100 text-blue-800';
      case 'PROJECT': return 'bg-green-100 text-green-800';
      case 'TASK': return 'bg-orange-100 text-orange-800';
      case 'USER': return 'bg-indigo-100 text-indigo-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getScopeIcon = (scope: string) => {
    switch (scope) {
      case 'ORG':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
          </svg>
        );
      case 'CLIENT':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        );
      case 'PROJECT':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
          </svg>
        );
      case 'TASK':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
        );
      case 'USER':
        return (
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        );
      default:
        return null;
    }
  };

  const formatEffect = (effects: any) => {
    const effectStrings = [];

    if (effects.rate && effects.rate.value) {
      if (effects.rate.op === 'set') {
        effectStrings.push(`Rate: $${effects.rate.value}`);
      } else if (effects.rate.op === 'multiply') {
        effectStrings.push(`Rate: ${effects.rate.value}x`);
      }
    }

    if (effects.overtime_multiplier && effects.overtime_multiplier.value) {
      effectStrings.push(`Overtime: ${effects.overtime_multiplier.value}x`);
    }

    if (effects.min_increment_min && effects.min_increment_min.value) {
      effectStrings.push(`Min increment: ${effects.min_increment_min.value}min`);
    }

    if (effects.materials_markup_pct && effects.materials_markup_pct.value) {
      effectStrings.push(`Materials markup: ${effects.materials_markup_pct.value}%`);
    }

    return effectStrings.join(' • ');
  };

  const formatConditions = (conditions: any) => {
    const conditionStrings = [];

    if (conditions.day_of_week && conditions.day_of_week.length > 0) {
      conditionStrings.push(`Days: ${conditions.day_of_week.join(', ')}`);
    }

    if (conditions.time_of_day && conditions.time_of_day.from) {
      conditionStrings.push(`Time: ${conditions.time_of_day.from} - ${conditions.time_of_day.to}`);
    }

    if (conditions.task_category) {
      conditionStrings.push(`Category: ${conditions.task_category}`);
    }

    if (conditions.role_title) {
      conditionStrings.push(`Role: ${conditions.role_title}`);
    }

    return conditionStrings.join(' • ');
  };

  const scopeOptions = [
    { value: 'all', label: 'All Scopes' },
    { value: 'ORG', label: 'Organization' },
    { value: 'CLIENT', label: 'Client' },
    { value: 'PROJECT', label: 'Project' },
    { value: 'TASK', label: 'Task' },
    { value: 'USER', label: 'User' }
  ];

  const filteredRules = rules.filter(rule => {
    const matchesScope = selectedScope === 'all' || rule.scope === selectedScope;
    const matchesSearch = rule.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         rule.scope_name.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesScope && matchesSearch;
  });

  const handleCreateRule = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      // TODO: Implement rule creation API call
      console.log('Creating rule:', newRule);
      setShowCreateRule(false);
      // Reset form
      setNewRule({
        name: '',
        scope: 'ORG',
        scope_id: '',
        priority: 1,
        active: true,
        conditions: {
          day_of_week: [],
          time_of_day: { from: '', to: '' },
          task_category: '',
          location: ''
        },
        effects: {
          rate: { op: 'set', value: '' },
          min_increment_min: { op: 'set', value: '' },
          overtime_multiplier: { op: 'set', value: '' },
          materials_markup_pct: { op: 'set', value: '' }
        }
      });
    } catch (error) {
      console.error('Failed to create rule:', error);
    }
  };

  const handleEditRule = (rule: any) => {
    setEditingRule({...rule});
    setShowEditRule(true);
  };

  const handleUpdateRule = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await rulesAPI.update(editingRule.id, {
        name: editingRule.name,
        priority: editingRule.priority,
        active: editingRule.active,
        rule: {
          conditions: editingRule.conditions,
          effects: editingRule.effects
        }
      });
      setShowEditRule(false);
      setEditingRule(null);
      fetchData();
    } catch (error) {
      console.error('Failed to update rule:', error);
      alert('Failed to update rule. Please try again.');
    }
  };

  const handleDeleteRule = async (ruleId: string, ruleName: string) => {
    if (window.confirm(`Are you sure you want to delete the rule "${ruleName}"? This action cannot be undone.`)) {
      try {
        await rulesAPI.delete(ruleId);
        fetchData();
      } catch (error) {
        console.error('Failed to delete rule:', error);
        alert('Failed to delete rule. Please try again.');
      }
    }
  };

  const handleTestRule = async (rule: any) => {
    try {
      const result = await rulesAPI.test({
        rule: rule,
        context: {
          day_of_week: new Date().toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase(),
          time_of_day: new Date().toTimeString().slice(0, 5),
          task_category: 'Development'
        }
      });
      alert(`Rule test result: ${JSON.stringify(result, null, 2)}`);
    } catch (error) {
      console.error('Failed to test rule:', error);
      alert('Failed to test rule. Please try again.');
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Billing Rules</h1>
            <p className="text-gray-600 mt-1">Configure custom billing rates and conditions</p>
          </div>
          <button
            onClick={() => setShowCreateRule(true)}
            className="mt-4 sm:mt-0 inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
          >
            <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Create Rule
          </button>
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
                placeholder="Search rules..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
              />
            </div>
          </div>
          <select
            value={selectedScope}
            onChange={(e) => setSelectedScope(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
          >
            {scopeOptions.map((option) => (
              <option key={option.value} value={option.value}>{option.label}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Rules List */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="w-8 h-8 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="space-y-4">
          {filteredRules.length > 0 ? (
            filteredRules.map((rule, index) => (
              <div key={rule.id} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-3">
                      <div className="flex items-center space-x-2">
                        <span className="text-sm font-medium text-gray-500">#{rule.priority}</span>
                        <h3 className="text-lg font-semibold text-gray-900">{rule.name}</h3>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getScopeColor(rule.scope)}`}>
                          <span className="mr-1">{getScopeIcon(rule.scope)}</span>
                          {rule.scope}
                        </span>
                        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                          rule.active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {rule.active ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                    </div>

                    <div className="mb-3">
                      <p className="text-sm text-gray-600 mb-1">
                        <span className="font-medium">Scope:</span> {rule.scope_name}
                      </p>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-4">
                      <div>
                        <p className="text-xs text-gray-500 uppercase tracking-wide mb-1">Conditions</p>
                        <p className="text-sm text-gray-700">
                          {formatConditions(rule.conditions) || 'No specific conditions'}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 uppercase tracking-wide mb-1">Effects</p>
                        <p className="text-sm text-gray-700">
                          {formatEffect(rule.effects) || 'No effects configured'}
                        </p>
                      </div>
                    </div>

                    <div className="text-xs text-gray-500">
                      Created {new Date(rule.created_at).toLocaleDateString()}
                    </div>
                  </div>

                  <div className="flex items-center space-x-2 ml-4">
                    <button
                      onClick={() => handleTestRule(rule)}
                      className="p-2 text-gray-400 hover:text-indigo-600 transition-colors"
                      title="Test Rule"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                      </svg>
                    </button>
                    <button
                      onClick={() => handleEditRule(rule)}
                      className="p-2 text-gray-400 hover:text-gray-600 transition-colors"
                      title="Edit"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                    <button
                      onClick={() => handleDeleteRule(rule.id, rule.name)}
                      className="p-2 text-gray-400 hover:text-red-600 transition-colors"
                      title="Delete"
                    >
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="text-center py-12 bg-white rounded-xl shadow-sm border border-gray-100">
              <div className="text-gray-400 mb-4">
                <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No billing rules found</h3>
              <p className="text-gray-500 mb-4">Create your first rule to customize billing rates</p>
              <button
                onClick={() => setShowCreateRule(true)}
                className="inline-flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors"
              >
                <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                Create Rule
              </button>
            </div>
          )}
        </div>
      )}

      {/* Edit Rule Modal */}
      {showEditRule && editingRule && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl max-w-md w-full p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-4">Edit Billing Rule</h2>
            <form onSubmit={handleUpdateRule} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Rule Name</label>
                <input
                  type="text"
                  required
                  value={editingRule.name}
                  onChange={(e) => setEditingRule({...editingRule, name: e.target.value})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Priority</label>
                  <input
                    type="number"
                    min="1"
                    value={editingRule.priority}
                    onChange={(e) => setEditingRule({...editingRule, priority: parseInt(e.target.value)})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                  <select
                    value={editingRule.active ? 'active' : 'inactive'}
                    onChange={(e) => setEditingRule({...editingRule, active: e.target.value === 'active'})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Scope</label>
                <select
                  value={editingRule.scope}
                  onChange={(e) => setEditingRule({...editingRule, scope: e.target.value})}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                >
                  <option value="ORG">Organization Wide</option>
                  <option value="CLIENT">Specific Client</option>
                  <option value="PROJECT">Specific Project</option>
                  <option value="TASK">Specific Task</option>
                  <option value="USER">Specific User</option>
                </select>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => {
                    setShowEditRule(false);
                    setEditingRule(null);
                  }}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  Update Rule
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Create Rule Modal */}
      {showCreateRule && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-xl max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold text-gray-900 mb-4">Create New Billing Rule</h2>
            <form onSubmit={handleCreateRule} className="space-y-6">
              {/* Basic Information */}
              <div className="space-y-4">
                <h3 className="text-lg font-medium text-gray-900">Basic Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Rule Name</label>
                    <input
                      type="text"
                      required
                      value={newRule.name}
                      onChange={(e) => setNewRule({...newRule, name: e.target.value})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="e.g., Weekend Premium Rate"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Priority</label>
                    <input
                      type="number"
                      min="1"
                      value={newRule.priority}
                      onChange={(e) => setNewRule({...newRule, priority: parseInt(e.target.value)})}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Scope</label>
                  <select
                    value={newRule.scope}
                    onChange={(e) => setNewRule({...newRule, scope: e.target.value})}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                  >
                    <option value="ORG">Organization Wide</option>
                    <option value="CLIENT">Specific Client</option>
                    <option value="PROJECT">Specific Project</option>
                    <option value="TASK">Specific Task</option>
                    <option value="USER">Specific User</option>
                  </select>
                </div>
              </div>

              {/* Conditions */}
              <div className="space-y-4">
                <h3 className="text-lg font-medium text-gray-900">Conditions</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Task Category</label>
                    <input
                      type="text"
                      value={newRule.conditions.task_category}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        conditions: {...newRule.conditions, task_category: e.target.value}
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="e.g., Development, Onsite"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Location</label>
                    <input
                      type="text"
                      value={newRule.conditions.location}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        conditions: {...newRule.conditions, location: e.target.value}
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="e.g., Client site, Remote"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Time From</label>
                    <input
                      type="time"
                      value={newRule.conditions.time_of_day.from}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        conditions: {
                          ...newRule.conditions,
                          time_of_day: {...newRule.conditions.time_of_day, from: e.target.value}
                        }
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Time To</label>
                    <input
                      type="time"
                      value={newRule.conditions.time_of_day.to}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        conditions: {
                          ...newRule.conditions,
                          time_of_day: {...newRule.conditions.time_of_day, to: e.target.value}
                        }
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white"
                    />
                  </div>
                </div>
              </div>

              {/* Effects */}
              <div className="space-y-4">
                <h3 className="text-lg font-medium text-gray-900">Effects</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Rate ($)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={newRule.effects.rate.value}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        effects: {...newRule.effects, rate: {...newRule.effects.rate, value: e.target.value}}
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="150.00"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Overtime Multiplier</label>
                    <input
                      type="number"
                      step="0.1"
                      value={newRule.effects.overtime_multiplier.value}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        effects: {...newRule.effects, overtime_multiplier: {...newRule.effects.overtime_multiplier, value: e.target.value}}
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="1.5"
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Min Increment (minutes)</label>
                    <input
                      type="number"
                      value={newRule.effects.min_increment_min.value}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        effects: {...newRule.effects, min_increment_min: {...newRule.effects.min_increment_min, value: e.target.value}}
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="15"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Materials Markup (%)</label>
                    <input
                      type="number"
                      step="0.1"
                      value={newRule.effects.materials_markup_pct.value}
                      onChange={(e) => setNewRule({
                        ...newRule,
                        effects: {...newRule.effects, materials_markup_pct: {...newRule.effects.materials_markup_pct, value: e.target.value}}
                      })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-gray-900 bg-white placeholder-gray-500"
                      placeholder="10"
                    />
                  </div>
                </div>
              </div>

              <div className="flex space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowCreateRule(false)}
                  className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  Create Rule
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
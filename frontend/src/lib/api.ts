import axios from 'axios';

// API base configuration
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear token and redirect to login
      localStorage.removeItem('auth_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API functions
export const authAPI = {
  login: async (email: string, password: string) => {
    const response = await api.post('/v1/auth/login', { email, password });
    return response.data;
  },

  getCurrentUser: async () => {
    const response = await api.get('/v1/auth/me');
    return response.data;
  },

  logout: () => {
    try {
      console.log('Logging out...');

      // Clear auth token from localStorage
      localStorage.removeItem('auth_token');
      localStorage.removeItem('user_info');

      console.log('Tokens cleared, redirecting to login...');

      // Redirect to login page
      window.location.href = '/login';
    } catch (error) {
      console.error('Error during logout:', error);
      // Fallback redirect
      window.location.href = '/login';
    }
  },

  changePassword: async (currentPassword: string, newPassword: string) => {
    const response = await api.post('/v1/auth/change-password', {
      current_password: currentPassword,
      new_password: newPassword,
    });
    return response.data;
  },

  logout: async () => {
    const response = await api.post('/v1/auth/logout');
    return response.data;
  },
};

// Users API functions
export const usersAPI = {
  list: async (skip = 0, limit = 100) => {
    const response = await api.get(`/v1/users/?skip=${skip}&limit=${limit}`);
    return response.data;
  },
  
  create: async (userData: { email: string; name: string; status?: string }) => {
    const response = await api.post('/v1/users/', userData);
    return response.data;
  },
  
  getCurrent: async () => {
    const response = await api.get('/v1/users/me');
    return response.data;
  },
};

// Clients API functions
export const clientsAPI = {
  list: async (skip = 0, limit = 100, search?: string) => {
    const params = new URLSearchParams({ skip: skip.toString(), limit: limit.toString() });
    if (search) params.append('search', search);
    const response = await api.get(`/v1/clients/?${params}`);
    return response.data;
  },

  create: async (clientData: { name: string; billing_contact_email: string; terms?: string }) => {
    const response = await api.post('/v1/clients/', clientData);
    return response.data;
  },

  get: async (clientId: string) => {
    const response = await api.get(`/v1/clients/${clientId}`);
    return response.data;
  },

  update: async (clientId: string, clientData: any) => {
    const response = await api.patch(`/v1/clients/${clientId}`, clientData);
    return response.data;
  },

  delete: async (clientId: string) => {
    const response = await api.delete(`/v1/clients/${clientId}`);
    return response.data;
  },
};

// Projects API functions
export const projectsAPI = {
  list: async (skip = 0, limit = 100, clientId?: string, status?: string, search?: string) => {
    const params = new URLSearchParams({ skip: skip.toString(), limit: limit.toString() });
    if (clientId) params.append('client_id', clientId);
    if (status) params.append('status', status);
    if (search) params.append('search', search);
    const response = await api.get(`/v1/projects/?${params}`);
    return response.data;
  },

  create: async (projectData: {
    name: string;
    code: string;
    client_id: string;
    billing_model?: string;
    start_date?: string;
    end_date?: string;
    notes?: string;
  }) => {
    const response = await api.post('/v1/projects/', projectData);
    return response.data;
  },

  get: async (projectId: string) => {
    const response = await api.get(`/v1/projects/${projectId}`);
    return response.data;
  },

  update: async (projectId: string, projectData: any) => {
    const response = await api.patch(`/v1/projects/${projectId}`, projectData);
    return response.data;
  },

  delete: async (projectId: string) => {
    const response = await api.delete(`/v1/projects/${projectId}`);
    return response.data;
  },
};

// Tasks API functions
export const tasksAPI = {
  list: async (skip = 0, limit = 100, projectId?: string, category?: string, search?: string) => {
    const params = new URLSearchParams({ skip: skip.toString(), limit: limit.toString() });
    if (projectId) params.append('project_id', projectId);
    if (category) params.append('category', category);
    if (search) params.append('search', search);
    const response = await api.get(`/v1/tasks/?${params}`);
    return response.data;
  },

  create: async (taskData: {
    name: string;
    category: string;
    project_id: string;
    is_billable?: boolean;
    default_rate?: number;
    uom?: string;
  }) => {
    const response = await api.post('/v1/tasks/', taskData);
    return response.data;
  },

  get: async (taskId: string) => {
    const response = await api.get(`/v1/tasks/${taskId}`);
    return response.data;
  },

  update: async (taskId: string, taskData: any) => {
    const response = await api.patch(`/v1/tasks/${taskId}`, taskData);
    return response.data;
  },

  delete: async (taskId: string) => {
    const response = await api.delete(`/v1/tasks/${taskId}`);
    return response.data;
  },

  getByProject: async (projectId: string) => {
    const response = await api.get(`/v1/tasks/project/${projectId}`);
    return response.data;
  },

  getCategories: async () => {
    const response = await api.get('/v1/tasks/categories/');
    return response.data;
  },
};

// Time Entries API functions
export const timeEntriesAPI = {
  list: async (params: {
    skip?: number;
    limit?: number;
    project_id?: string;
    task_id?: string;
    user_id?: string;
    status?: string;
    start_date?: string;
    end_date?: string;
  } = {}) => {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.append(key, value.toString());
    });
    const response = await api.get(`/v1/time_entries/?${searchParams}`);
    return response.data;
  },

  create: async (timeEntryData: {
    project_id: string;
    task_id: string;
    start_at: string;
    duration_minutes: number;
    end_at?: string;
    notes?: string;
    geo?: any;
    source?: string;
  }) => {
    const response = await api.post('/v1/time_entries/', timeEntryData);
    return response.data;
  },

  get: async (timeEntryId: string) => {
    const response = await api.get(`/v1/time_entries/${timeEntryId}`);
    return response.data;
  },

  update: async (timeEntryId: string, timeEntryData: any) => {
    const response = await api.patch(`/v1/time_entries/${timeEntryId}`, timeEntryData);
    return response.data;
  },

  delete: async (timeEntryId: string) => {
    const response = await api.delete(`/v1/time_entries/${timeEntryId}`);
    return response.data;
  },

  submit: async (timeEntryId: string) => {
    const response = await api.post(`/v1/time_entries/${timeEntryId}/submit`);
    return response.data;
  },

  approve: async (timeEntryId: string, decision: 'APPROVE' | 'REJECT', comment?: string) => {
    const response = await api.post(`/v1/time_entries/${timeEntryId}/approve`, {
      decision,
      comment,
    });
    return response.data;
  },

  // Timer functions
  startTimer: async (projectId: string, taskId: string, notes?: string) => {
    const response = await api.post('/v1/time_entries/timer/start', {
      project_id: projectId,
      task_id: taskId,
      notes,
    });
    return response.data;
  },

  stopTimer: async () => {
    const response = await api.post('/v1/time_entries/timer/stop');
    return response.data;
  },

  getTimerStatus: async () => {
    const response = await api.get('/v1/time_entries/timer/status');
    return response.data;
  },
};

// Invoices API functions
export const invoicesAPI = {
  list: async (params: {
    skip?: number;
    limit?: number;
    client_id?: string;
    status?: string;
  } = {}) => {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.append(key, value.toString());
    });
    const response = await api.get(`/v1/invoices/?${searchParams}`);
    return response.data;
  },

  create: async (invoiceData: {
    project_id: string;
    range: {
      from: string;
      to: string;
    };
    include: {
      time: boolean;
      expenses: boolean;
      fixed: boolean;
      milestones?: boolean;
    };
    grouping: string;
  }) => {
    const response = await api.post('/v1/invoices/', invoiceData);
    return response.data;
  },

  get: async (invoiceId: string) => {
    const response = await api.get(`/v1/invoices/${invoiceId}`);
    return response.data;
  },

  update: async (invoiceId: string, updates: any) => {
    const response = await api.patch(`/v1/invoices/${invoiceId}`, updates);
    return response.data;
  },

  delete: async (invoiceId: string) => {
    const response = await api.delete(`/v1/invoices/${invoiceId}`);
    return response.data;
  },

  generatePDF: async (invoiceId: string) => {
    const response = await api.post(`/v1/invoices/${invoiceId}/pdf`);
    return response.data;
  },
};

// Approvals API functions
export const approvalsAPI = {
  list: async (params: {
    type?: string;
    status?: string;
    skip?: number;
    limit?: number;
  } = {}) => {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.append(key, value.toString());
    });
    const response = await api.get(`/v1/approvals/?${searchParams}`);
    return response.data;
  },

  decide: async (approvalId: string, decision: 'APPROVE' | 'REJECT', comment?: string) => {
    const response = await api.post(`/v1/approvals/${approvalId}/decision`, {
      decision,
      comment,
    });
    return response.data;
  },
};

// Rules API functions
export const rulesAPI = {
  list: async (params: {
    scope?: string;
    scope_id?: string;
    skip?: number;
    limit?: number;
  } = {}) => {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.append(key, value.toString());
    });
    const response = await api.get(`/v1/rules/?${searchParams}`);
    return response.data;
  },

  create: async (ruleData: {
    name: string;
    scope: string;
    scope_id?: string;
    priority: number;
    rule: any;
    active: boolean;
  }) => {
    const response = await api.post('/v1/rules/', ruleData);
    return response.data;
  },

  get: async (ruleId: string) => {
    const response = await api.get(`/v1/rules/${ruleId}`);
    return response.data;
  },

  update: async (ruleId: string, ruleData: any) => {
    const response = await api.patch(`/v1/rules/${ruleId}`, ruleData);
    return response.data;
  },

  delete: async (ruleId: string) => {
    const response = await api.delete(`/v1/rules/${ruleId}`);
    return response.data;
  },

  test: async (context: any) => {
    const response = await api.post('/v1/rules/test', { context });
    return response.data;
  },
};

// Expenses API functions
export const expensesAPI = {
  list: async (params: {
    skip?: number;
    limit?: number;
    project_id?: string;
    task_id?: string;
    user_id?: string;
    status?: string;
    start_date?: string;
    end_date?: string;
  } = {}) => {
    const searchParams = new URLSearchParams();
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) searchParams.append(key, value.toString());
    });
    const response = await api.get(`/v1/expenses/?${searchParams}`);
    return response.data;
  },

  create: async (expenseData: {
    project_id: string;
    task_id: string;
    amount: number;
    currency: string;
    receipt_url?: string;
    notes?: string;
  }) => {
    const response = await api.post('/v1/expenses/', expenseData);
    return response.data;
  },

  get: async (expenseId: string) => {
    const response = await api.get(`/v1/expenses/${expenseId}`);
    return response.data;
  },

  update: async (expenseId: string, expenseData: any) => {
    const response = await api.patch(`/v1/expenses/${expenseId}`, expenseData);
    return response.data;
  },

  delete: async (expenseId: string) => {
    const response = await api.delete(`/v1/expenses/${expenseId}`);
    return response.data;
  },

  submit: async (expenseId: string) => {
    const response = await api.post(`/v1/expenses/${expenseId}/submit`);
    return response.data;
  },
};

// Health check
export const healthAPI = {
  check: async () => {
    const response = await api.get('/health');
    return response.data;
  },
};

export default api;
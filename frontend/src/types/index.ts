export interface Organization {
  id: string;
  name: string;
  timezone: string;
  currency_code: string;
  created_at: string;
}

export interface User {
  id: string;
  org_id: string;
  email: string;
  name: string;
  status: string;
  created_at: string;
  last_login_at?: string;
}

export interface Client {
  id: string;
  org_id: string;
  name: string;
  billing_contact_email: string;
  terms?: string;
  default_tax_profile?: Record<string, any>;
  created_at: string;
}

export interface Project {
  id: string;
  org_id: string;
  client_id: string;
  name: string;
  code: string;
  status: string;
  start_date?: string;
  end_date?: string;
  notes?: string;
  billing_model: 'HOURLY' | 'FIXED' | 'MILESTONE' | 'RETAINER' | 'T&M' | 'MIXED';
  billing_settings: Record<string, any>;
}

export interface Task {
  id: string;
  org_id: string;
  project_id: string;
  name: string;
  category: string;
  is_billable: boolean;
  default_rate: number;
  uom: 'HOUR' | 'ITEM' | 'DAY';
}

export interface TimeEntry {
  id: string;
  org_id: string;
  user_id: string;
  project_id: string;
  task_id: string;
  start_at: string;
  end_at?: string;
  duration_minutes: number;
  notes?: string;
  status: 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED';
  approved_by?: string;
  approved_at?: string;
  geo?: Record<string, any>;
  source: 'MOBILE' | 'WEB' | 'IMPORT' | 'API';
}

export interface Expense {
  id: string;
  org_id: string;
  user_id: string;
  project_id: string;
  task_id: string;
  amount: number;
  currency: string;
  receipt_url?: string;
  notes?: string;
  status: 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED';
}

export interface Invoice {
  id: string;
  org_id: string;
  client_id: string;
  project_id: string;
  number: string;
  issue_date: string;
  due_date: string;
  status: 'DRAFT' | 'SENT' | 'PAID' | 'VOID';
  subtotal: number;
  tax_total: number;
  total: number;
  currency: string;
  external_ref?: string;
}

export type Role = 'ADMIN' | 'MANAGER' | 'CONTRACTOR' | 'SUBCONTRACTOR' | 'CLIENT_VIEWER';
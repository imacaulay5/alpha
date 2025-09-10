from fastapi import APIRouter
from . import auth, users, clients, projects, tasks, time_entries, expenses, invoices, rules, change_orders, approvals, webhooks

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(clients.router, prefix="/clients", tags=["clients"])
api_router.include_router(projects.router, prefix="/projects", tags=["projects"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
api_router.include_router(time_entries.router, prefix="/time_entries", tags=["time_entries"])
api_router.include_router(expenses.router, prefix="/expenses", tags=["expenses"])
api_router.include_router(invoices.router, prefix="/invoices", tags=["invoices"])
api_router.include_router(rules.router, prefix="/rules", tags=["rules"])
api_router.include_router(change_orders.router, prefix="/change_orders", tags=["change_orders"])
api_router.include_router(approvals.router, prefix="/approvals", tags=["approvals"])
api_router.include_router(webhooks.router, prefix="/webhooks", tags=["webhooks"])
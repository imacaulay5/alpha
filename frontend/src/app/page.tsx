import Link from "next/link";

export default function HomePage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen py-2">
      <main className="flex flex-col items-center justify-center w-full flex-1 px-20 text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-6">
          Contractor Billing
        </h1>
        
        <p className="text-xl text-gray-600 mb-8 max-w-2xl">
          A comprehensive contractor billing platform that addresses key pain points with flexible billing rules, 
          mobile-first time tracking, and powerful subcontractor management.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-4xl">
          <Link href="/dashboard" className="group block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Dashboard</h3>
            <p className="text-gray-600">View your overview with hours, approvals, and invoices</p>
          </Link>

          <Link href="/time" className="group block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Time Tracking</h3>
            <p className="text-gray-600">Mobile-first time entry with offline support</p>
          </Link>

          <Link href="/projects" className="group block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Projects</h3>
            <p className="text-gray-600">Manage your projects and billing settings</p>
          </Link>

          <Link href="/invoices" className="group block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Invoices</h3>
            <p className="text-gray-600">Generate and send professional invoices</p>
          </Link>

          <Link href="/approvals" className="group block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Approvals</h3>
            <p className="text-gray-600">Review and approve time entries and expenses</p>
          </Link>

          <Link href="/rules" className="group block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md transition-shadow">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Billing Rules</h3>
            <p className="text-gray-600">Configure flexible billing rules and rates</p>
          </Link>
        </div>

        <div className="mt-12">
          <Link 
            href="/login"
            className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg transition-colors"
          >
            Get Started
          </Link>
        </div>
      </main>
    </div>
  );
}

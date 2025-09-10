export default function DashboardPage() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600">Welcome to your contractor billing dashboard</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Hours Today</h3>
          <p className="text-3xl font-bold text-blue-600">7.5</p>
          <p className="text-sm text-gray-500">Billable hours logged</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Pending Approvals</h3>
          <p className="text-3xl font-bold text-orange-600">3</p>
          <p className="text-sm text-gray-500">Items awaiting approval</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Draft Invoices</h3>
          <p className="text-3xl font-bold text-green-600">2</p>
          <p className="text-sm text-gray-500">Ready to send</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Outstanding AR</h3>
          <p className="text-3xl font-bold text-purple-600">$12,450</p>
          <p className="text-sm text-gray-500">Awaiting payment</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Time Entries</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">ACME Corp - Development</p>
                <p className="text-sm text-gray-500">2 hours ago</p>
              </div>
              <span className="text-blue-600 font-semibold">2.5h</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <div>
                <p className="font-medium">TechCorp - Consultation</p>
                <p className="text-sm text-gray-500">5 hours ago</p>
              </div>
              <span className="text-blue-600 font-semibold">1.0h</span>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Upcoming Deadlines</h3>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-red-50 rounded">
              <div>
                <p className="font-medium">ACME Corp Invoice #001</p>
                <p className="text-sm text-gray-500">Due in 2 days</p>
              </div>
              <span className="text-red-600 font-semibold">$4,500</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-yellow-50 rounded">
              <div>
                <p className="font-medium">Project Milestone Review</p>
                <p className="text-sm text-gray-500">Due in 5 days</p>
              </div>
              <span className="text-yellow-600 font-semibold">Review</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
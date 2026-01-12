'use client';

import { ProtocolStats } from '../components/ProtocolStats';
import { AgentList } from '../components/AgentList';
import { ReputationChart } from '../components/ReputationChart';

export default function Dashboard() {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4">
          <h1 className="text-3xl font-bold text-gray-900">KYA Protocol Dashboard</h1>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 px-4">
        <div className="mb-8">
          <ProtocolStats />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-bold mb-4">Reputation Trends</h2>
            <ReputationChart />
          </div>

          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-bold mb-4">Recent Activity</h2>
            <p className="text-gray-600">Recent agent activity will appear here</p>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-bold mb-4">All Agents</h2>
          <AgentList />
        </div>
      </main>
    </div>
  );
}

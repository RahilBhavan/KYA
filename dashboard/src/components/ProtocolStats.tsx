'use client';

import { useQuery } from '@apollo/client';
import { GET_PROTOCOL_STATS } from '../lib/graphql/queries';
import { formatEther } from 'ethers';

export function ProtocolStats() {
  const { data, loading, error } = useQuery(GET_PROTOCOL_STATS);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  const stats = data?.protocolStats;

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
      <StatCard
        title="Total Agents"
        value={stats?.totalAgents || 0}
        icon="👥"
      />
      <StatCard
        title="Total Staked"
        value={`${formatEther(stats?.totalStaked || 0)} USDC`}
        icon="💰"
      />
      <StatCard
        title="Total Reputation"
        value={stats?.totalReputationScore || 0}
        icon="⭐"
      />
      <StatCard
        title="Verified Agents"
        value={stats?.totalVerifiedAgents || 0}
        icon="✅"
      />
      <StatCard
        title="Total Claims"
        value={stats?.totalClaims || 0}
        icon="📋"
      />
    </div>
  );
}

function StatCard({ title, value, icon }: { title: string; value: string | number; icon: string }) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600">{title}</p>
          <p className="text-2xl font-bold mt-2">{value}</p>
        </div>
        <div className="text-4xl">{icon}</div>
      </div>
    </div>
  );
}

'use client';

import { useQuery } from '@apollo/client';
import { GET_AGENTS } from '../lib/graphql/queries';
import Link from 'next/link';

export function AgentList() {
  const { data, loading, error } = useQuery(GET_AGENTS, {
    variables: { first: 20 },
  });

  if (loading) return <div>Loading agents...</div>;
  if (error) return <div>Error: {error.message}</div>;

  const agents = data?.agents || [];

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Token ID
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Name
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Category
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Reputation
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Tier
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Staked
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {agents.map((agent: any) => (
            <tr key={agent.id} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap">
                <Link
                  href={`/agent/${agent.tokenId}`}
                  className="text-blue-600 hover:text-blue-800"
                >
                  #{agent.tokenId}
                </Link>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">{agent.name}</td>
              <td className="px-6 py-4 whitespace-nowrap">{agent.category}</td>
              <td className="px-6 py-4 whitespace-nowrap">
                {agent.reputation?.score || 0}
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                {getTierName(agent.reputation?.tier || 0)}
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                {agent.stakes?.[0]?.isVerified ? '✅ Verified' : '❌ Not Verified'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function getTierName(tier: number): string {
  const tiers = ['None', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Whale'];
  return tiers[tier] || 'None';
}

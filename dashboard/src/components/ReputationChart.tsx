'use client';

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export function ReputationChart() {
  // Mock data - in production, fetch from GraphQL
  const data = [
    { date: '2024-01', score: 100 },
    { date: '2024-02', score: 150 },
    { date: '2024-03', score: 200 },
    { date: '2024-04', score: 250 },
    { date: '2024-05', score: 300 },
  ];

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Legend />
        <Line type="monotone" dataKey="score" stroke="#8884d8" name="Reputation Score" />
      </LineChart>
    </ResponsiveContainer>
  );
}

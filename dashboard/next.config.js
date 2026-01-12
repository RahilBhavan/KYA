/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  env: {
    NEXT_PUBLIC_GRAPH_URL: process.env.NEXT_PUBLIC_GRAPH_URL || 'https://api.thegraph.com/subgraphs/name/kya-protocol/kya',
  },
}

module.exports = nextConfig

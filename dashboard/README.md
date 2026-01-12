# KYA Protocol - Analytics Dashboard

Next.js dashboard for KYA Protocol analytics and insights.

## Setup

1. Install dependencies:
```bash
bun install
```

2. Set environment variables:
```bash
NEXT_PUBLIC_GRAPH_URL=https://api.thegraph.com/subgraphs/name/kya-protocol/kya
```

3. Run development server:
```bash
bun run dev
```

4. Build for production:
```bash
bun run build
bun run start
```

## Features

- Real-time protocol metrics
- Agent analytics and insights
- Reputation trends visualization
- Insurance pool statistics
- Transaction history
- Agent search and filtering

## Deployment

Deploy to Vercel:

```bash
vercel deploy
```

Or Netlify:

```bash
netlify deploy --prod
```

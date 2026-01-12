# Monitoring & Alerts Guide

**Purpose**: Guide for setting up contract monitoring, metrics tracking, and alerting for KYA Protocol.

---

## Overview

Production monitoring is essential for:
- Detecting issues early
- Tracking protocol health
- Monitoring economic activity
- Alerting on critical events

---

## Monitoring Services

### Option 1: Tenderly (Recommended)

**Why Tenderly**:
- Excellent Base network support
- Real-time event monitoring
- Transaction simulation
- Gas profiling
- Free tier available

**Setup**:
1. Sign up at https://tenderly.co
2. Create project
3. Add Base Sepolia network
4. Get API key from Settings > Authorization
5. Run: `./script/monitoring-setup.sh`

**Configuration**:
```json
{
  "apiKey": "your_api_key",
  "project": "your_project_slug",
  "username": "your_username",
  "network": "base-sepolia",
  "chainId": 84532
}
```

### Option 2: OpenZeppelin Defender

**Why Defender**:
- Enterprise-grade security
- Multi-signature support
- Automated responses
- Comprehensive monitoring

**Setup**:
1. Sign up at https://defender.openzeppelin.com
2. Create team
3. Get API key and secret
4. Run: `./script/monitoring-setup.sh`

### Option 3: Custom Monitoring

Use web3 libraries to build custom monitoring:
- `ethers.js` for event listening
- `viem` for TypeScript projects
- Custom scripts for specific needs

---

## Contract Monitoring

### Events to Monitor

#### InsuranceVault Events

**Critical Events**:
- `Staked(uint256 indexed tokenId, uint256 amount)` - Staking activity
- `Unstaked(uint256 indexed tokenId, uint256 amount)` - Unstaking activity
- `ClaimSubmitted(bytes32 indexed claimId, uint256 indexed tokenId, uint256 amount)` - Claims
- `ClaimResolved(bytes32 indexed claimId, bool approved, uint256 slashedAmount)` - Resolutions
- `Slashed(uint256 indexed tokenId, uint256 amount, address recipient)` - Slashing events

**Alert On**:
- Large stake amounts (> threshold)
- Claim submissions
- Slashing events
- Unusual unstaking patterns

#### ReputationScore Events

**Critical Events**:
- `ProofVerified(uint256 indexed tokenId, string proofType, uint256 scoreIncrease)` - Proof verifications
- `ReputationUpdated(uint256 indexed tokenId, uint256 oldScore, uint256 newScore, uint8 newTier)` - Score updates
- `BadgeAwarded(uint256 indexed tokenId, string badgeName)` - Badge awards

**Alert On**:
- Rapid score increases
- Tier changes
- Badge awards

#### Paymaster Events

**Critical Events**:
- `GasSponsored(uint256 indexed tokenId, uint256 cost, bytes32 context)` - Gas sponsorship
- `DepositUpdated(uint256 newDeposit)` - Deposit changes

**Alert On**:
- Low deposit balance
- High gas sponsorship
- Deposit depletion

### Monitoring Script

```bash
# Run health check
./script/monitor-contracts.sh

# Or use HealthCheck script
forge script script/HealthCheck.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL
```

---

## Metrics Tracking

### Key Metrics

#### Protocol Metrics

1. **Agent Metrics**
   - Total agents minted
   - Active agents
   - Verified agents
   - Agents by tier

2. **Staking Metrics**
   - Total USDC staked
   - Average stake amount
   - Staking/unstaking rate
   - Staked by tier

3. **Reputation Metrics**
   - Average reputation score
   - Tier distribution
   - Proof verification rate
   - Badge distribution

4. **Claims Metrics**
   - Claims submitted
   - Claims resolved
   - Slashing events
   - Challenge rate

5. **Paymaster Metrics**
   - Gas sponsored
   - Eligible agents
   - Transactions sponsored
   - Deposit balance

### Metrics Collection

#### Using Tenderly

```javascript
// Example: Track staking events
const stakingEvents = await tenderly.getEvents({
  contract: insuranceVaultAddress,
  event: 'Staked',
  fromBlock: startBlock,
  toBlock: 'latest'
});

// Aggregate metrics
const totalStaked = stakingEvents.reduce((sum, event) => 
  sum + BigInt(event.args.amount), 0n
);
```

#### Custom Metrics Script

Create `script/collect-metrics.sh`:

```bash
#!/bin/bash
# Collect protocol metrics

# Get total agents
total_agents=$(cast call $AGENT_REGISTRY "totalAgents()" --rpc-url $RPC_URL)

# Get total staked
total_staked=$(cast call $INSURANCE_VAULT "totalStaked()" --rpc-url $RPC_URL)

# Output metrics
echo "Total Agents: $total_agents"
echo "Total Staked: $total_staked USDC"
```

---

## Alert Configuration

### Critical Alerts

#### 1. Contract Paused

**Trigger**: `InsuranceVault.paused() == true`

**Action**: 
- Immediate notification
- Investigate reason
- Prepare response

**Setup**:
```javascript
// Check pause status
const isPaused = await insuranceVault.paused();
if (isPaused) {
  sendAlert('CRITICAL', 'InsuranceVault is paused');
}
```

#### 2. Large Slashing Event

**Trigger**: `Slashed` event with amount > threshold

**Action**:
- Notify team
- Review claim details
- Monitor for patterns

**Threshold**: > 10,000 USDC

#### 3. Low Paymaster Balance

**Trigger**: `Paymaster.getDeposited() < threshold`

**Action**:
- Fund Paymaster
- Review usage patterns

**Threshold**: < 0.1 ETH

#### 4. Unusual Activity

**Trigger**: 
- Rapid stake/unstake cycles
- Multiple claims in short time
- Unusual proof verification patterns

**Action**:
- Investigate
- Review for potential attacks

### Alert Channels

#### Email Alerts

```bash
# Send email alert
echo "Alert: $MESSAGE" | mail -s "KYA Protocol Alert" team@kya.protocol
```

#### Slack/Discord Webhooks

```bash
# Send to Slack
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"Alert: $MESSAGE\"}"
```

#### SMS Alerts

Use services like Twilio for critical alerts.

---

## Dashboard Creation

### Metrics Dashboard

Create a dashboard showing:

1. **Overview**
   - Total agents
   - Total staked
   - Active verified agents
   - Protocol health status

2. **Activity**
   - Recent staking events
   - Recent claims
   - Recent proof verifications
   - Gas sponsorship activity

3. **Economics**
   - Total USDC locked
   - Fee collection
   - Paymaster balance
   - Average stake amounts

4. **Reputation**
   - Tier distribution
   - Average scores
   - Badge awards
   - Proof verification rate

### Dashboard Tools

- **Grafana**: Custom dashboards
- **Tenderly Dashboard**: Built-in monitoring
- **Defender Dashboard**: OpenZeppelin Defender
- **Custom**: Build with React/Next.js

---

## Health Check Automation

### Automated Health Checks

Set up cron job or scheduled task:

```bash
# Run health check every hour
0 * * * * cd /path/to/KYA && ./script/monitor-contracts.sh >> monitoring/health.log 2>&1
```

### Health Check Script

```bash
#!/bin/bash
# Automated health check

# Run health check
forge script script/HealthCheck.s.sol --rpc-url $RPC_URL > health-check.txt

# Check for issues
if grep -q "✗" health-check.txt; then
    sendAlert("WARNING", "Health check found issues")
fi
```

---

## Error Tracking

### Sentry Integration

1. Sign up at https://sentry.io
2. Create project
3. Get DSN
4. Configure in monitoring

**For JavaScript SDK**:
```javascript
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
});
```

---

## Best Practices

### Monitoring

1. **Monitor Continuously**: 24/7 monitoring for production
2. **Set Appropriate Thresholds**: Not too sensitive, not too lenient
3. **Test Alerts**: Ensure alerts work before production
4. **Document Procedures**: Know what to do when alerts fire
5. **Review Regularly**: Adjust thresholds based on usage

### Alerts

1. **Prioritize**: Critical > High > Medium > Low
2. **Avoid Alert Fatigue**: Don't alert on everything
3. **Actionable**: Alerts should trigger specific actions
4. **Test**: Regularly test alert delivery
5. **Document**: Document alert procedures

---

## Monitoring Checklist

### Setup

- [ ] Monitoring service selected
- [ ] API keys configured
- [ ] Contract addresses added
- [ ] Event monitoring configured
- [ ] Alerts configured
- [ ] Dashboard created

### Operations

- [ ] Health checks automated
- [ ] Metrics collection running
- [ ] Alerts tested
- [ ] Team notified of alerts
- [ ] Procedures documented

---

## Troubleshooting

### Alerts Not Firing

- Check alert configuration
- Verify thresholds
- Test alert delivery
- Check service status

### Metrics Not Updating

- Verify contract addresses
- Check RPC connection
- Review event filters
- Check service logs

---

## Next Steps

1. Set up monitoring service
2. Configure event monitoring
3. Set up alerts
4. Create dashboard
5. Automate health checks
6. Test everything
7. Monitor in production

---

**Last Updated**: 2026-01-06


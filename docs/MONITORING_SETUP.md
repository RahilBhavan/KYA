# Production Monitoring Setup Guide

**Purpose**: Guide for setting up production monitoring and alerting for KYA Protocol.

---

## Overview

This guide covers:
1. Choosing a monitoring solution
2. Setting up contract monitoring
3. Configuring alerts
4. Creating dashboards
5. Automation setup

---

## Step 1: Choose Monitoring Solution

### Recommended: Tenderly

**Why Tenderly?**
- Free tier available
- Excellent Base network support
- Real-time event monitoring
- Transaction simulation
- Gas profiling
- Easy setup

**Setup**:
1. Sign up at https://tenderly.co
2. Create project
3. Add Base Sepolia network
4. Get API key from Settings > Authorization

### Alternative: OpenZeppelin Defender

**Why Defender?**
- Enterprise-grade security
- Integrated with multi-sig
- Advanced automation
- Custom alert rules

**Setup**:
1. Sign up at https://defender.openzeppelin.com
2. Create account
3. Set up monitoring
4. Configure alerts

---

## Step 2: Contract Monitoring Setup

### Using Tenderly

#### Automated Setup

```bash
# 1. Set environment variables
export TENDERLY_API_KEY="your_api_key"
export TENDERLY_PROJECT_SLUG="your_project"
export TENDERLY_USERNAME="your_username"

# 2. Set contract addresses
export AGENT_LICENSE_ADDRESS="0x..."
export AGENT_REGISTRY_ADDRESS="0x..."
# ... etc

# 3. Run setup script
./monitoring/setup-monitoring.sh
```

#### Manual Setup

1. **Add Contracts**:
   - Go to Tenderly dashboard
   - Navigate to Contracts
   - Add each contract address
   - Verify contracts

2. **Configure Events**:
   - Select contract
   - Go to Events tab
   - Enable monitoring for:
     - `AgentMinted`
     - `Staked`
     - `ClaimSubmitted`
     - `ClaimResolved`
     - `ProofVerified`
     - `GasSponsored`
     - `Paused` / `Unpaused`

### Events to Monitor

**Critical Events**:
- `AgentMinted` - New agent registrations
- `Staked` - Staking events
- `Unstaked` - Unstaking events
- `ClaimSubmitted` - Insurance claims
- `ClaimResolved` - Claim resolutions
- `ProofVerified` - Reputation updates
- `GasSponsored` - Paymaster activity
- `Paused` / `Unpaused` - Emergency controls

**Admin Events**:
- `RoleGranted` / `RoleRevoked` - Access control changes
- `SettingsUpdated` - Configuration changes
- `FeesWithdrawn` - Fee withdrawals

---

## Step 3: Alert Configuration

### Critical Alerts (Immediate Response)

#### Contract Paused
- **Trigger**: `Paused` event emitted
- **Channel**: Email + Slack + SMS
- **Action**: Investigate immediately, notify team

#### Large Stake/Unstake
- **Trigger**: Stake/Unstake > 10% of total staked
- **Channel**: Email + Slack
- **Action**: Verify legitimacy, check for attacks

#### Claim Submitted
- **Trigger**: `ClaimSubmitted` event
- **Channel**: Email + Slack
- **Action**: Review claim details, prepare response

#### Admin Role Changes
- **Trigger**: `RoleGranted` or `RoleRevoked` for `DEFAULT_ADMIN_ROLE`
- **Channel**: Email + Slack + SMS
- **Action**: Verify multi-sig approval, investigate if unauthorized

#### Low Contract Balance
- **Trigger**: Balance < 1 ETH or < 1000 USDC
- **Channel**: Email + Slack
- **Action**: Fund contract immediately

### Warning Alerts (Review Required)

#### High Gas Usage
- **Trigger**: Transaction gas > 500k
- **Channel**: Email
- **Action**: Review transaction, check for issues

#### Unusual Activity
- **Trigger**: > 10 transactions in 1 hour from same address
- **Channel**: Email
- **Action**: Investigate pattern, check for abuse

#### Failed Transactions
- **Trigger**: > 10 failed transactions in 1 hour
- **Channel**: Email
- **Action**: Check contract state, review errors

### Informational Alerts (Daily Summary)

#### Daily Activity Summary
- **Schedule**: Daily at 9:00 AM UTC
- **Content**: 
  - New agents registered
  - Total staked amount
  - Claims submitted/resolved
  - Protocol health metrics

#### Weekly Report
- **Schedule**: Weekly on Monday at 9:00 AM UTC
- **Content**:
  - Weekly statistics
  - Growth metrics
  - Notable events
  - Upcoming changes

---

## Step 4: Dashboard Creation

### Real-time Dashboard

**Metrics to Display**:

1. **Protocol Overview**
   - Total agents registered
   - Active staked amount
   - Total claims
   - Recent activity feed

2. **Economic Dashboard**
   - Total Value Staked (TVS)
   - Fee collection
   - Claim payout ratio
   - Average stake per agent

3. **Security Dashboard**
   - Failed transactions
   - Access control events
   - Emergency events
   - Unusual activity

### Dashboard Tools

- **Tenderly Dashboard**: Built-in, easy setup
- **Grafana**: Custom dashboards, more control
- **Dune Analytics**: On-chain analytics
- **Custom Web Dashboard**: Full control

---

## Step 5: Automation

### Automated Responses

#### Health Checks
- **Schedule**: Every hour
- **Action**: Check contract health, verify balances
- **Alert**: If any check fails

#### Daily Reports
- **Schedule**: Daily at 9:00 AM UTC
- **Action**: Generate and send daily summary
- **Channel**: Email

#### Balance Monitoring
- **Schedule**: Every 6 hours
- **Action**: Check contract balances
- **Alert**: If below threshold

---

## Configuration Files

### Tenderly Configuration

See `monitoring/tenderly-config.json` for complete configuration template.

### Environment Variables

```bash
# Tenderly
TENDERLY_API_KEY=your_api_key
TENDERLY_PROJECT_SLUG=your_project
TENDERLY_USERNAME=your_username

# Contract Addresses
AGENT_LICENSE_ADDRESS=0x...
AGENT_REGISTRY_ADDRESS=0x...
REPUTATION_SCORE_ADDRESS=0x...
INSURANCE_VAULT_ADDRESS=0x...
PAYMASTER_ADDRESS=0x...
MERCHANT_SDK_ADDRESS=0x...
```

---

## Testing Alerts

### Test Critical Alerts

1. **Pause Test**:
   - Pause a contract (on testnet)
   - Verify alert triggers
   - Check all channels

2. **Large Transaction Test**:
   - Execute large stake (on testnet)
   - Verify alert triggers
   - Check threshold accuracy

3. **Role Change Test**:
   - Grant/revoke role (on testnet)
   - Verify alert triggers
   - Check alert content

---

## Best Practices

1. **Start Simple**: Begin with critical alerts, add more over time
2. **Tune Thresholds**: Adjust based on actual usage patterns
3. **Avoid Alert Fatigue**: Don't over-alert, use tiers
4. **Regular Review**: Review and update alerts monthly
5. **Document Everything**: Keep alert procedures documented
6. **Test Regularly**: Test alerts on testnet monthly

---

## Troubleshooting

### Alerts Not Triggering

- Check event monitoring is enabled
- Verify contract addresses are correct
- Check alert configuration
- Review Tenderly logs

### Too Many Alerts

- Increase thresholds
- Add filters
- Use alert tiers
- Review and consolidate

### Missing Events

- Verify contract verification
- Check event signatures
- Review contract ABI
- Contact support if needed

---

## Next Steps

After monitoring setup:

1. ✅ All contracts monitored
2. ✅ Critical alerts configured
3. ✅ Dashboard created
4. ✅ Team trained on monitoring
5. ✅ Incident response integrated

---

## Resources

- [Tenderly Documentation](https://docs.tenderly.co/)
- [OpenZeppelin Defender](https://docs.openzeppelin.com/defender/)
- [KYA Monitoring Config](./monitoring/tenderly-config.json)
- [Incident Response Plan](./INCIDENT_RESPONSE.md)

---

**Last Updated**: 2026-01-12

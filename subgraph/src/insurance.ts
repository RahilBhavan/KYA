import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  Staked,
  Unstaked,
  ClaimSubmitted,
  ClaimResolved,
  Slashed,
  UnstakeRequested,
} from "../generated/InsuranceVault/InsuranceVault";
import {
  Stake,
  Claim,
  UnstakeRequest,
  ProtocolStats,
} from "../generated/schema";

/**
 * Handle Staked event
 */
export function handleStaked(event: Staked): void {
  let tokenId = event.params.tokenId.toString();
  
  let stake = Stake.load(tokenId);
  if (stake == null) {
    stake = new Stake(tokenId);
    stake.amount = BigInt.fromI32(0);
    stake.stakedAt = event.block.timestamp;
    stake.isVerified = false;
  }
  
  stake.amount = stake.amount.plus(event.params.amount);
  stake.isVerified = true; // Assuming staking makes agent verified
  stake.lastUpdated = event.block.timestamp;
  stake.save();
  
  // Update protocol stats
  updateStakeStats(event.block.timestamp);
}

/**
 * Handle Unstaked event
 */
export function handleUnstaked(event: Unstaked): void {
  let tokenId = event.params.tokenId.toString();
  
  let stake = Stake.load(tokenId);
  if (stake != null) {
    stake.amount = stake.amount.minus(event.params.amount);
    // Check if still verified (would need to check contract)
    stake.lastUpdated = event.block.timestamp;
    stake.save();
  }
  
  updateStakeStats(event.block.timestamp);
}

/**
 * Handle ClaimSubmitted event
 */
export function handleClaimSubmitted(event: ClaimSubmitted): void {
  let claimId = event.params.claimId.toHexString();
  
  let claim = new Claim(claimId);
  claim.agent = event.params.tokenId.toString();
  claim.merchant = event.params.merchant;
  claim.amount = event.params.amount;
  claim.reason = ""; // Would need to parse from event or call contract
  claim.status = 0; // Pending
  claim.submittedAt = event.block.timestamp;
  claim.resolvedAt = BigInt.fromI32(0);
  claim.save();
  
  // Update protocol stats
  updateClaimStats(event.block.timestamp);
}

/**
 * Handle ClaimResolved event
 */
export function handleClaimResolved(event: ClaimResolved): void {
  let claimId = event.params.claimId.toHexString();
  
  let claim = Claim.load(claimId);
  if (claim != null) {
    claim.status = event.params.valid ? 1 : 2; // 1=valid, 2=invalid
    claim.resolvedAt = event.block.timestamp;
    claim.resolver = event.transaction.from;
    claim.save();
  }
}

/**
 * Handle Slashed event
 */
export function handleSlashed(event: Slashed): void {
  let tokenId = event.params.tokenId.toString();
  
  let stake = Stake.load(tokenId);
  if (stake != null) {
    stake.amount = stake.amount.minus(event.params.amount);
    stake.lastUpdated = event.block.timestamp;
    stake.save();
  }
  
  updateStakeStats(event.block.timestamp);
}

/**
 * Handle UnstakeRequested event
 */
export function handleUnstakeRequested(event: UnstakeRequested): void {
  let tokenId = event.params.tokenId.toString();
  let requestId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  
  let request = new UnstakeRequest(requestId);
  request.stake = tokenId;
  request.requestedAt = event.block.timestamp;
  request.amount = event.params.amount;
  request.status = "pending";
  request.completedAt = BigInt.fromI32(0);
  request.save();
}

/**
 * Update stake statistics
 */
function updateStakeStats(timestamp: BigInt): void {
  let stats = ProtocolStats.load("global");
  if (stats == null) {
    stats = new ProtocolStats("global");
    stats.totalAgents = 0;
    stats.totalStaked = BigInt.fromI32(0);
    stats.totalReputationScore = BigInt.fromI32(0);
    stats.totalClaims = 0;
    stats.totalVerifiedAgents = 0;
  }
  
  // In production, you'd aggregate all Stake entities
  stats.lastUpdated = timestamp;
  stats.save();
}

/**
 * Update claim statistics
 */
function updateClaimStats(timestamp: BigInt): void {
  let stats = ProtocolStats.load("global");
  if (stats == null) {
    stats = new ProtocolStats("global");
    stats.totalAgents = 0;
    stats.totalStaked = BigInt.fromI32(0);
    stats.totalReputationScore = BigInt.fromI32(0);
    stats.totalClaims = 0;
    stats.totalVerifiedAgents = 0;
  }
  
  stats.totalClaims = stats.totalClaims + 1;
  stats.lastUpdated = timestamp;
  stats.save();
}

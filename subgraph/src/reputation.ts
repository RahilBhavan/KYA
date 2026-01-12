import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  ReputationUpdated,
  ProofVerified,
  BadgeAwarded,
} from "../generated/ReputationScore/ReputationScore";
import {
  CategoryScoreUpdated,
} from "../generated/ReputationScoreV2/ReputationScoreV2";
import {
  Agent,
  Reputation,
  ReputationUpdate,
  Badge,
  CategoryScore,
  ProtocolStats,
} from "../generated/schema";

/**
 * Handle ReputationUpdated event
 */
export function handleReputationUpdated(event: ReputationUpdated): void {
  let tokenId = event.params.tokenId.toString();
  
  // Get or create reputation
  let reputation = Reputation.load(tokenId);
  if (reputation == null) {
    reputation = new Reputation(tokenId);
    reputation.score = BigInt.fromI32(0);
    reputation.tier = 0;
    reputation.verifiedProofs = 0;
    
    // Link to agent (find agent by tokenId)
    // In production, you'd query Agent entities
    let agentId = findAgentByTokenId(tokenId);
    if (agentId != null) {
      reputation.agent = agentId;
    }
  }
  
  // Create reputation update record
  let updateId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let update = new ReputationUpdate(updateId);
  update.reputation = tokenId;
  update.oldScore = event.params.oldScore;
  update.newScore = event.params.newScore;
  update.oldTier = reputation.tier;
  update.newTier = event.params.newTier;
  update.timestamp = event.block.timestamp;
  update.transactionHash = event.transaction.hash;
  update.save();
  
  // Update reputation
  reputation.score = event.params.newScore;
  reputation.tier = event.params.newTier;
  reputation.lastUpdated = event.block.timestamp;
  reputation.save();
  
  // Update protocol stats
  updateReputationStats(event.block.timestamp);
}

/**
 * Handle ProofVerified event
 */
export function handleProofVerified(event: ProofVerified): void {
  let tokenId = event.params.tokenId.toString();
  
  let reputation = Reputation.load(tokenId);
  if (reputation == null) {
    // Create if doesn't exist
    reputation = new Reputation(tokenId);
    reputation.score = BigInt.fromI32(0);
    reputation.tier = 0;
    reputation.verifiedProofs = 0;
    
    let agentId = findAgentByTokenId(tokenId);
    if (agentId != null) {
      reputation.agent = agentId;
    }
  }
  
  reputation.verifiedProofs = reputation.verifiedProofs + 1;
  reputation.save();
  
  // Update the latest reputation update with proof info
  let updateId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let update = ReputationUpdate.load(updateId);
  if (update != null) {
    update.proofType = event.params.proofType;
    update.scoreIncrease = event.params.scoreIncrease;
    update.save();
  }
}

/**
 * Handle BadgeAwarded event
 */
export function handleBadgeAwarded(event: BadgeAwarded): void {
  let tokenId = event.params.tokenId.toString();
  let badgeId = tokenId + "-" + event.params.badgeName;
  
  let badge = Badge.load(badgeId);
  if (badge == null) {
    badge = new Badge(badgeId);
    badge.reputation = tokenId;
    badge.name = event.params.badgeName;
    badge.awardedAt = event.block.timestamp;
    badge.tier = 0; // Would need to fetch from contract
    badge.description = ""; // Would need to fetch from contract
    badge.save();
  }
}

/**
 * Handle CategoryScoreUpdated event (V2)
 */
export function handleCategoryScoreUpdated(event: CategoryScoreUpdated): void {
  let tokenId = event.params.tokenId.toString();
  let categoryId = tokenId + "-" + event.params.category;
  
  let categoryScore = CategoryScore.load(categoryId);
  if (categoryScore == null) {
    categoryScore = new CategoryScore(categoryId);
    categoryScore.reputation = tokenId;
    categoryScore.category = event.params.category;
  }
  
  categoryScore.score = event.params.newScore;
  categoryScore.lastUpdated = event.block.timestamp;
  categoryScore.save();
}

/**
 * Find agent by tokenId (helper function)
 * In production, you'd query Agent entities efficiently
 */
function findAgentByTokenId(tokenId: string): string | null {
  // This is a simplified version
  // In production, you'd maintain a mapping or query efficiently
  // For now, return null and handle in a more sophisticated way
  return null;
}

/**
 * Update reputation statistics
 */
function updateReputationStats(timestamp: BigInt): void {
  let stats = ProtocolStats.load("global");
  if (stats == null) {
    stats = new ProtocolStats("global");
    stats.totalAgents = 0;
    stats.totalStaked = BigInt.fromI32(0);
    stats.totalReputationScore = BigInt.fromI32(0);
    stats.totalClaims = 0;
    stats.totalVerifiedAgents = 0;
  }
  
  // In production, you'd aggregate all Reputation entities
  // For now, we just update the timestamp
  stats.lastUpdated = timestamp;
  stats.save();
}

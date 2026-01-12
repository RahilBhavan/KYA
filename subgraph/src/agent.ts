import { BigInt, Bytes, Address } from "@graphprotocol/graph-ts";
import { AgentCreated } from "../generated/AgentRegistry/AgentRegistry";
import { Agent, ProtocolStats, Transaction } from "../generated/schema";

/**
 * Handle AgentCreated event
 */
export function handleAgentCreated(event: AgentCreated): void {
  // Create or update agent
  let agentId = event.params.agentId.toHexString();
  let agent = Agent.load(agentId);
  
  if (agent == null) {
    agent = new Agent(agentId);
    agent.createdAt = event.block.timestamp;
  }
  
  agent.tokenId = event.params.tokenId;
  agent.tbaAddress = event.params.tbaAddress;
  agent.owner = event.params.owner;
  agent.updatedAt = event.block.timestamp;
  
  // Get metadata from AgentLicense (would need to call contract or parse from event)
  // For now, we'll set defaults and update from events
  agent.name = "";
  agent.description = "";
  agent.category = "";
  agent.status = 0; // Active
  
  agent.save();
  
  // Update protocol stats
  updateProtocolStats(event.block.timestamp);
}

/**
 * Update protocol statistics
 */
function updateProtocolStats(timestamp: BigInt): void {
  let stats = ProtocolStats.load("global");
  
  if (stats == null) {
    stats = new ProtocolStats("global");
    stats.totalAgents = 0;
    stats.totalStaked = BigInt.fromI32(0);
    stats.totalReputationScore = BigInt.fromI32(0);
    stats.totalClaims = 0;
    stats.totalVerifiedAgents = 0;
  }
  
  // Count total agents
  // Note: In production, you'd query all Agent entities
  // For now, we increment on each creation
  stats.totalAgents = stats.totalAgents + 1;
  stats.lastUpdated = timestamp;
  
  stats.save();
}

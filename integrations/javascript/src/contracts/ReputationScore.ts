/**
 * ReputationScore Contract Helper
 * Helper functions for interacting with ReputationScore contract
 */

import { ethers } from 'ethers';
import { ProofResult } from '../types';

export interface ReputationData {
  score: bigint;
  tier: number;
  verifiedProofs: number;
  badges: string[];
}

export class ReputationScoreContract {
  private contract: ethers.Contract;

  constructor(
    address: string,
    provider: ethers.Provider,
    signer?: ethers.Signer
  ) {
    const abi = [
      'function verifyProof(uint256 tokenId, string calldata proofType, bytes calldata proof, string calldata metadata) external returns (ProofResult)',
      'function getReputation(uint256 tokenId) external view returns (ReputationData)',
      'function getTier(uint256 tokenId) external view returns (uint8)',
      'function getBadges(uint256 tokenId) external view returns (string[])',
      'function hasBadge(uint256 tokenId, string calldata badgeId) external view returns (bool)',
      'function ZK_PROVER_ROLE() external view returns (bytes32)',
      'event ProofVerified(uint256 indexed tokenId, string indexed proofType, uint256 scoreIncrease)',
    ];

    this.contract = new ethers.Contract(address, abi, signer || provider);
  }

  /**
   * Verify proof (requires ZK_PROVER_ROLE)
   */
  async verifyProof(
    tokenId: number,
    proofType: string,
    proof: string,
    metadata: string
  ): Promise<ProofResult> {
    const result = await this.contract.verifyProof(
      tokenId,
      proofType,
      proof,
      metadata
    );

    return {
      queryId: ethers.keccak256(ethers.toUtf8Bytes(`${tokenId}-${proofType}-${Date.now()}`)),
      verified: result.verified,
      proof: proof,
      metadata: metadata,
    };
  }

  /**
   * Get reputation data for an agent
   */
  async getReputation(tokenId: number): Promise<ReputationData> {
    const data = await this.contract.getReputation(tokenId);
    return {
      score: data.score,
      tier: Number(data.tier),
      verifiedProofs: Number(data.verifiedProofs),
      badges: data.badges,
    };
  }

  /**
   * Get tier for an agent
   */
  async getTier(tokenId: number): Promise<number> {
    return Number(await this.contract.getTier(tokenId));
  }

  /**
   * Get badges for an agent
   */
  async getBadges(tokenId: number): Promise<string[]> {
    return await this.contract.getBadges(tokenId);
  }

  /**
   * Check if agent has a specific badge
   */
  async hasBadge(tokenId: number, badgeId: string): Promise<boolean> {
    return await this.contract.hasBadge(tokenId, badgeId);
  }

  /**
   * Get ZK_PROVER_ROLE constant
   */
  async getZKProverRole(): Promise<string> {
    return await this.contract.ZK_PROVER_ROLE();
  }

  /**
   * Listen for proof verification events
   */
  onProofVerified(
    callback: (tokenId: bigint, proofType: string, scoreIncrease: bigint) => void
  ): void {
    this.contract.on('ProofVerified', callback);
  }
}

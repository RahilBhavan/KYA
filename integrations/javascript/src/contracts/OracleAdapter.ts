/**
 * OracleAdapter Contract Helper
 * Helper functions for interacting with OracleAdapter contract
 */

import { ethers } from 'ethers';
import { ClaimData, ResolutionResult } from '../types';

export class OracleAdapterContract {
  private contract: ethers.Contract;

  constructor(
    address: string,
    provider: ethers.Provider,
    signer?: ethers.Signer
  ) {
    const abi = [
      'function submitClaim(ClaimData calldata claimData) external returns (bytes32)',
      'function processResolution(bytes32 requestId, bool approved, bytes calldata resolutionData) external',
      'function getClaimStatus(bytes32 requestId) external view returns (uint8 status, ResolutionResult memory result)',
      'function getClaim(bytes32 requestId) external view returns (ClaimData memory)',
      'function getOracleRequestId(bytes32 vaultClaimId) external view returns (bytes32)',
      'event ClaimSubmittedToOracle(bytes32 indexed requestId, address indexed submitter)',
      'event ClaimResolvedByOracle(bytes32 indexed requestId, bool approved)',
    ];

    this.contract = new ethers.Contract(address, abi, signer || provider);
  }

  /**
   * Submit claim to oracle
   */
  async submitClaim(claimData: ClaimData): Promise<string> {
    if (!this.contract.signer) {
      throw new Error('Signer required for submitClaim');
    }
    return await this.contract.submitClaim(claimData);
  }

  /**
   * Process resolution (requires admin role)
   */
  async processResolution(
    requestId: string,
    approved: boolean,
    resolutionData: string
  ): Promise<ethers.ContractTransactionResponse> {
    if (!this.contract.signer) {
      throw new Error('Signer required for processResolution');
    }
    return await this.contract.processResolution(requestId, approved, resolutionData);
  }

  /**
   * Get claim status
   */
  async getClaimStatus(requestId: string): Promise<{ status: number; result: ResolutionResult }> {
    const result = await this.contract.getClaimStatus(requestId);
    return {
      status: Number(result.status),
      result: {
        requestId: result.result.requestId,
        resolved: result.result.resolved,
        result: result.result.result,
        timestamp: Number(result.result.timestamp),
        challenger: result.result.challenger,
        resolutionData: result.result.resolutionData,
      },
    };
  }

  /**
   * Get claim data
   */
  async getClaim(requestId: string): Promise<ClaimData> {
    const claim = await this.contract.getClaim(requestId);
    return {
      claimId: claim.claimId,
      tokenId: Number(claim.tokenId),
      merchant: claim.merchant,
      amount: claim.amount.toString(),
      reason: claim.reason,
      evidence: claim.evidence,
    };
  }

  /**
   * Get oracle request ID from vault claim ID
   */
  async getOracleRequestId(vaultClaimId: string): Promise<string> {
    return await this.contract.getOracleRequestId(vaultClaimId);
  }
}

/**
 * InsuranceVault Contract Helper
 * Helper functions for interacting with InsuranceVault contract
 */

import { ethers } from 'ethers';

export interface StakeInfo {
  amount: bigint;
  isVerified: boolean;
  verifiedAt: bigint;
}

export interface Claim {
  tokenId: bigint;
  merchant: string;
  amount: bigint;
  reason: string;
  status: number; // 0=pending, 1=approved, 2=rejected
  submittedAt: bigint;
  resolvedAt: bigint;
}

export class InsuranceVaultContract {
  private contract: ethers.Contract;

  constructor(
    address: string,
    provider: ethers.Provider,
    signer?: ethers.Signer
  ) {
    const abi = [
      'function stake(uint256 tokenId, uint256 amount) external',
      'function unstake(uint256 tokenId, uint256 amount) external',
      'function requestUnstake(uint256 tokenId) external',
      'function submitClaim(uint256 tokenId, uint256 amount, string calldata reason) external returns (bytes32)',
      'function resolveClaim(bytes32 claimId, bool approved) external',
      'function getStakeInfo(uint256 tokenId) external view returns (StakeInfo)',
      'function getClaim(bytes32 claimId) external view returns (Claim)',
      'function isVerified(uint256 tokenId) external view returns (bool)',
      'function ORACLE_ROLE() external view returns (bytes32)',
      'event Staked(uint256 indexed tokenId, uint256 amount)',
      'event Unstaked(uint256 indexed tokenId, uint256 amount)',
      'event ClaimSubmitted(bytes32 indexed claimId, uint256 indexed tokenId, address indexed merchant, uint256 amount)',
      'event ClaimResolved(bytes32 indexed claimId, bool approved)',
    ];

    this.contract = new ethers.Contract(address, abi, signer || provider);
  }

  /**
   * Stake USDC for an agent (requires approval)
   */
  async stake(tokenId: number, amount: bigint): Promise<ethers.ContractTransactionResponse> {
    if (!this.contract.signer) {
      throw new Error('Signer required for stake');
    }
    return await this.contract.stake(tokenId, amount);
  }

  /**
   * Request unstake (starts cooldown for verified agents)
   */
  async requestUnstake(tokenId: number): Promise<ethers.ContractTransactionResponse> {
    if (!this.contract.signer) {
      throw new Error('Signer required for requestUnstake');
    }
    return await this.contract.requestUnstake(tokenId);
  }

  /**
   * Unstake USDC (after cooldown for verified agents)
   */
  async unstake(tokenId: number, amount: bigint): Promise<ethers.ContractTransactionResponse> {
    if (!this.contract.signer) {
      throw new Error('Signer required for unstake');
    }
    return await this.contract.unstake(tokenId, amount);
  }

  /**
   * Submit a claim (requires merchant to sign)
   */
  async submitClaim(
    tokenId: number,
    amount: bigint,
    reason: string
  ): Promise<string> {
    if (!this.contract.signer) {
      throw new Error('Signer required for submitClaim');
    }
    const tx = await this.contract.submitClaim(tokenId, amount, reason);
    const receipt = await tx.wait();
    
    // Extract claimId from event
    const event = receipt.logs.find((log: any) => {
      try {
        const parsed = this.contract.interface.parseLog(log);
        return parsed?.name === 'ClaimSubmitted';
      } catch {
        return false;
      }
    });
    
    if (event) {
      const parsed = this.contract.interface.parseLog(event);
      return parsed?.args[0] as string;
    }
    
    throw new Error('ClaimSubmitted event not found');
  }

  /**
   * Resolve a claim (requires ORACLE_ROLE)
   */
  async resolveClaim(
    claimId: string,
    approved: boolean
  ): Promise<ethers.ContractTransactionResponse> {
    if (!this.contract.signer) {
      throw new Error('Signer required for resolveClaim');
    }
    return await this.contract.resolveClaim(claimId, approved);
  }

  /**
   * Get stake information for an agent
   */
  async getStakeInfo(tokenId: number): Promise<StakeInfo> {
    const info = await this.contract.getStakeInfo(tokenId);
    return {
      amount: info.amount,
      isVerified: info.isVerified,
      verifiedAt: info.verifiedAt,
    };
  }

  /**
   * Get claim information
   */
  async getClaim(claimId: string): Promise<Claim> {
    const claim = await this.contract.getClaim(claimId);
    return {
      tokenId: claim.tokenId,
      merchant: claim.merchant,
      amount: claim.amount,
      reason: claim.reason,
      status: Number(claim.status),
      submittedAt: claim.submittedAt,
      resolvedAt: claim.resolvedAt,
    };
  }

  /**
   * Check if agent is verified
   */
  async isVerified(tokenId: number): Promise<boolean> {
    return await this.contract.isVerified(tokenId);
  }

  /**
   * Get ORACLE_ROLE constant
   */
  async getOracleRole(): Promise<string> {
    return await this.contract.ORACLE_ROLE();
  }

  /**
   * Listen for claim submission events
   */
  onClaimSubmitted(
    callback: (claimId: string, tokenId: bigint, merchant: string, amount: bigint) => void
  ): void {
    this.contract.on('ClaimSubmitted', callback);
  }

  /**
   * Listen for claim resolution events
   */
  onClaimResolved(
    callback: (claimId: string, approved: boolean) => void
  ): void {
    this.contract.on('ClaimResolved', callback);
  }
}

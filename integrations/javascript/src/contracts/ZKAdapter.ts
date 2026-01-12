/**
 * ZKAdapter Contract Helper
 * Helper functions for interacting with ZKAdapter contract
 */

import { ethers } from 'ethers';
import { ProofQuery, ProofResult } from '../types';

export class ZKAdapterContract {
  private contract: ethers.Contract;

  constructor(
    address: string,
    provider: ethers.Provider,
    signer?: ethers.Signer
  ) {
    const abi = [
      'function submitQuery(ProofQuery calldata query) external returns (bytes32)',
      'function processProofAndUpdate(bytes32 queryId, uint256 tokenId, bytes calldata proof, string calldata metadata) external',
      'function getProofStatus(bytes32 queryId) external view returns (uint8 status, ProofResult memory result)',
      'function getQuery(bytes32 queryId) external view returns (ProofQuery memory)',
      'event ProofQuerySubmitted(bytes32 indexed queryId, address indexed agentAddress, string indexed proofType)',
      'event ProofGenerated(bytes32 indexed queryId, bool verified)',
    ];

    this.contract = new ethers.Contract(address, abi, signer || provider);
  }

  /**
   * Submit a proof query
   */
  async submitQuery(query: ProofQuery): Promise<string> {
    if (!this.contract.signer) {
      throw new Error('Signer required for submitQuery');
    }
    return await this.contract.submitQuery(query);
  }

  /**
   * Process proof and update reputation (requires admin role)
   */
  async processProofAndUpdate(
    queryId: string,
    tokenId: number,
    proof: string,
    metadata: string
  ): Promise<ethers.ContractTransactionResponse> {
    if (!this.contract.signer) {
      throw new Error('Signer required for processProofAndUpdate');
    }
    return await this.contract.processProofAndUpdate(queryId, tokenId, proof, metadata);
  }

  /**
   * Get proof status
   */
  async getProofStatus(queryId: string): Promise<{ status: number; result: ProofResult }> {
    const result = await this.contract.getProofStatus(queryId);
    return {
      status: Number(result.status),
      result: {
        queryId: result.result.queryId,
        verified: result.result.verified,
        proof: result.result.proof,
        metadata: result.result.metadata,
      },
    };
  }

  /**
   * Get query data
   */
  async getQuery(queryId: string): Promise<ProofQuery> {
    const query = await this.contract.getQuery(queryId);
    return {
      agentAddress: query.agentAddress,
      proofType: query.proofType,
      queryData: query.queryData,
      startBlock: Number(query.startBlock),
      endBlock: Number(query.endBlock),
    };
  }
}

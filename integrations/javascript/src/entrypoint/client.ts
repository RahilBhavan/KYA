/**
 * ERC-4337 EntryPoint Client
 */

import { ethers } from 'ethers';
import { EntryPointConfig } from '../config';
import { UserOperation, PaymasterData } from '../types';

export class EntryPointClient {
  private config: EntryPointConfig;
  private provider: ethers.Provider;
  private signer?: ethers.Signer;

  constructor(config: EntryPointConfig, provider: ethers.Provider, signer?: ethers.Signer) {
    this.config = config;
    this.provider = provider;
    this.signer = signer;
  }

  /**
   * Create user operation
   */
  async createUserOperation(params: {
    sender: string;
    callData: string;
    nonce?: number;
    callGasLimit?: number;
    verificationGasLimit?: number;
    maxFeePerGas?: bigint;
    maxPriorityFeePerGas?: bigint;
  }): Promise<UserOperation> {
    const nonce = params.nonce ?? await this.getNonce(params.sender);
    
    // Get current gas prices if not provided
    let maxFeePerGas = params.maxFeePerGas;
    let maxPriorityFeePerGas = params.maxPriorityFeePerGas;
    
    if (!maxFeePerGas || !maxPriorityFeePerGas) {
      const feeData = await this.provider.getFeeData();
      maxFeePerGas = maxFeePerGas || (feeData.maxFeePerGas || ethers.parseUnits('20', 'gwei'));
      maxPriorityFeePerGas = maxPriorityFeePerGas || (feeData.maxPriorityFeePerGas || ethers.parseUnits('2', 'gwei'));
    }

    return {
      sender: params.sender,
      nonce: nonce,
      callData: params.callData,
      callGasLimit: params.callGasLimit || 100000,
      verificationGasLimit: params.verificationGasLimit || 100000,
      preVerificationGas: 21000,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    };
  }

  /**
   * Submit user operation to EntryPoint via bundler
   * @param userOp User operation to submit
   * @param bundlerUrl Bundler RPC URL (e.g., Pimlico, Alchemy)
   * @returns User operation hash
   */
  async submitUserOperation(
    userOp: UserOperation,
    bundlerUrl?: string
  ): Promise<string> {
    if (!bundlerUrl) {
      // Use default bundler or direct EntryPoint call
      if (!this.signer) {
        throw new Error('Signer required for direct EntryPoint submission');
      }
      
      const entryPoint = new ethers.Contract(
        this.config.address,
        [
          'function handleOps(tuple(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],address)',
          'function getUserOpHash(tuple(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)) view returns (bytes32)'
        ],
        this.signer
      );
      
      // Get user operation hash
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      
      // Submit via handleOps (requires bundler or direct call)
      // Note: In production, use a bundler service
      throw new Error('Direct EntryPoint submission requires bundler. Use submitUserOperation with bundlerUrl.');
    }
    
    // Submit via bundler RPC
    try {
      const response = await fetch(bundlerUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          jsonrpc: '2.0',
          id: 1,
          method: 'eth_sendUserOperation',
          params: [userOp, this.config.address],
        }),
      });
      
      const data = await response.json();
      if (data.error) {
        throw new Error(`Bundler error: ${data.error.message}`);
      }
      
      return data.result;
    } catch (error: any) {
      throw new Error(`Failed to submit user operation: ${error.message}`);
    }
  }

  /**
   * Get user operation hash
   * @param userOp User operation
   * @returns User operation hash
   */
  async getUserOpHash(userOp: UserOperation): Promise<string> {
    const entryPoint = new ethers.Contract(
      this.config.address,
      ['function getUserOpHash(tuple(address,uint256,bytes,bytes,uint256,uint256,uint256,uint256,uint256,bytes,bytes)) view returns (bytes32)'],
      this.provider
    );
    
    return await entryPoint.getUserOpHash(userOp);
  }

  /**
   * Get nonce for account
   */
  async getNonce(sender: string, key: number = 0): Promise<number> {
    // TODO: Implement EntryPoint.getNonce call
    const entryPoint = new ethers.Contract(
      this.config.address,
      ['function getNonce(address,uint192) view returns (uint256)'],
      this.provider
    );
    
    return Number(await entryPoint.getNonce(sender, key));
  }
}


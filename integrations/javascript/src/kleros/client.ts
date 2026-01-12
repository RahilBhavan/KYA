/**
 * Kleros Client for oracle dispute resolution
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import { KlerosConfig } from '../config';
import { ClaimData, ResolutionResult } from '../types';
import { retry } from '../utils/retry';
import { KlerosError } from '../utils/errors';

export class KlerosClient {
  private config: KlerosConfig;
  private api: AxiosInstance;

  constructor(config: KlerosConfig) {
    this.config = config;
    this.api = axios.create({
      baseURL: config.baseUrl || 'https://api.kleros.io',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }

  /**
   * Submit claim to Kleros arbitration
   * @param claimData Claim data including tokenId, merchant, amount, reason, evidence
   * @returns Dispute ID for tracking
   */
  async submitClaim(claimData: ClaimData): Promise<string> {
    try {
      const response = await retry(
        () => this.api.post('/v1/disputes', {
          chainId: this.config.network === 'base-sepolia' ? 84532 : 8453,
          claimId: claimData.claimId,
          tokenId: claimData.tokenId,
          merchant: claimData.merchant,
          amount: claimData.amount,
          reason: claimData.reason,
          evidence: claimData.evidence,
          arbitrator: this.config.address,
          timestamp: Date.now()
        }),
        {
          maxAttempts: 3,
          delay: 1000,
          backoff: 'exponential',
        }
      );

      return response.data.disputeId;
    } catch (error: any) {
      if (error instanceof AxiosError) {
        throw new KlerosError(
          `Failed to submit claim to Kleros: ${error.message}`,
          error.code,
          error
        );
      }
      throw new KlerosError(`Failed to submit claim to Kleros: ${error.message}`, undefined, error);
    }
  }

  /**
   * Get dispute status and resolution
   * @param disputeId Dispute identifier from submitClaim
   * @returns Resolution result
   */
  async getClaimStatus(disputeId: string): Promise<ResolutionResult> {
    try {
      const response = await retry(
        () => this.api.get(`/v1/disputes/${disputeId}`),
        {
          maxAttempts: 3,
          delay: 1000,
        }
      );
      
      return {
        requestId: disputeId,
        resolved: response.data.resolved || false,
        result: response.data.ruling === 1,
        timestamp: response.data.timestamp || 0,
        challenger: response.data.challenger || null,
        resolutionData: response.data.ruling || null
      };
    } catch (error: any) {
      if (error instanceof AxiosError) {
        throw new KlerosError(
          `Failed to get Kleros dispute status: ${error.message}`,
          error.code,
          error
        );
      }
      throw new KlerosError(`Failed to get Kleros dispute status: ${error.message}`, undefined, error);
    }
  }

  /**
   * Poll for dispute resolution
   * @param disputeId Dispute identifier
   * @param maxAttempts Maximum polling attempts
   * @param delay Delay between attempts in milliseconds
   * @returns Resolution result when ready
   */
  async pollForResolution(
    disputeId: string,
    maxAttempts: number = 120, // Kleros can take longer
    delay: number = 10000 // 10 seconds
  ): Promise<ResolutionResult> {
    for (let i = 0; i < maxAttempts; i++) {
      const status = await this.getClaimStatus(disputeId);
      
      if (status.resolved) {
        return status;
      }

      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, delay));
    }

    throw new Error('Dispute resolution timeout');
  }

  /**
   * Appeal a dispute ruling
   * @param disputeId Dispute identifier
   * @param appellant Appellant address
   * @param evidence Appeal evidence
   * @returns Appeal ID
   */
  async appealDispute(
    disputeId: string,
    appellant: string,
    evidence: any
  ): Promise<string> {
    try {
      const response = await this.api.post(`/v1/disputes/${disputeId}/appeal`, {
        appellant: appellant,
        evidence: evidence,
        timestamp: Date.now()
      });

      return response.data.appealId;
    } catch (error: any) {
      throw new Error(`Failed to appeal dispute: ${error.message}`);
    }
  }
}


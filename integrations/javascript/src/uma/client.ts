/**
 * UMA Client for oracle dispute resolution
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import { UMAConfig } from '../config';
import { ClaimData, ResolutionResult } from '../types';
import { retry } from '../utils/retry';
import { UMAError } from '../utils/errors';

export class UMAClient {
  private config: UMAConfig;
  private api: AxiosInstance;

  constructor(config: UMAConfig) {
    this.config = config;
    this.api = axios.create({
      baseURL: config.baseUrl || 'https://api.umaproject.org',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }

  /**
   * Submit claim to UMA oracle
   * @param claimData Claim data including tokenId, merchant, amount, reason, evidence
   * @returns Request ID for tracking
   */
  async submitClaim(claimData: ClaimData): Promise<string> {
    try {
      const response = await retry(
        () => this.api.post('/v1/claims', {
          chainId: this.config.network === 'base-sepolia' ? 84532 : 8453,
          claimId: claimData.claimId,
          tokenId: claimData.tokenId,
          merchant: claimData.merchant,
          amount: claimData.amount,
          reason: claimData.reason,
          evidence: claimData.evidence,
          timestamp: Date.now()
        }),
        {
          maxAttempts: 3,
          delay: 1000,
          backoff: 'exponential',
        }
      );

      return response.data.requestId;
    } catch (error: any) {
      if (error instanceof AxiosError) {
        throw new UMAError(
          `Failed to submit claim to UMA: ${error.message}`,
          error.code,
          error
        );
      }
      throw new UMAError(`Failed to submit claim to UMA: ${error.message}`, undefined, error);
    }
  }

  /**
   * Get claim status and resolution
   * @param requestId Request identifier from submitClaim
   * @returns Resolution result
   */
  async getClaimStatus(requestId: string): Promise<ResolutionResult> {
    try {
      const response = await retry(
        () => this.api.get(`/v1/claims/${requestId}`),
        {
          maxAttempts: 3,
          delay: 1000,
        }
      );
      
      return {
        requestId: requestId,
        resolved: response.data.resolved || false,
        result: response.data.result || false,
        timestamp: response.data.timestamp || 0,
        challenger: response.data.challenger || null,
        resolutionData: response.data.resolutionData || null
      };
    } catch (error: any) {
      if (error instanceof AxiosError) {
        throw new UMAError(
          `Failed to get claim status: ${error.message}`,
          error.code,
          error
        );
      }
      throw new UMAError(`Failed to get claim status: ${error.message}`, undefined, error);
    }
  }

  /**
   * Poll for claim resolution
   * @param requestId Request identifier
   * @param maxAttempts Maximum polling attempts
   * @param delay Delay between attempts in milliseconds
   * @returns Resolution result when ready
   */
  async pollForResolution(
    requestId: string,
    maxAttempts: number = 60,
    delay: number = 5000
  ): Promise<ResolutionResult> {
    for (let i = 0; i < maxAttempts; i++) {
      const status = await this.getClaimStatus(requestId);
      
      if (status.resolved) {
        return status;
      }

      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, delay));
    }

    throw new Error('Claim resolution timeout');
  }

  /**
   * Challenge a claim
   * @param requestId Request identifier
   * @param challenger Challenger address
   * @param evidence Challenge evidence
   * @returns Challenge ID
   */
  async challengeClaim(
    requestId: string,
    challenger: string,
    evidence: any
  ): Promise<string> {
    try {
      const response = await this.api.post(`/v1/claims/${requestId}/challenge`, {
        challenger: challenger,
        evidence: evidence,
        timestamp: Date.now()
      });

      return response.data.challengeId;
    } catch (error: any) {
      throw new Error(`Failed to challenge claim: ${error.message}`);
    }
  }
}


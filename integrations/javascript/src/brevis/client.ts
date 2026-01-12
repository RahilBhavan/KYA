/**
 * Brevis Client for ZK proof generation
 * 
 * Similar to AxiomClient but for Brevis service
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import { BrevisConfig } from '../config';
import { ProofQuery, ProofResult } from '../types';
import { retry } from '../utils/retry';
import { BrevisError } from '../utils/errors';

export class BrevisClient {
  private config: BrevisConfig;
  private api: AxiosInstance;

  constructor(config: BrevisConfig) {
    this.config = config;
    this.api = axios.create({
      baseURL: config.baseUrl || 'https://api.brevis.network',
      headers: {
        'Authorization': `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }

  /**
   * Generate ZK proof for agent reputation
   * @param query Proof query parameters
   * @returns Proof result
   */
  async generateProof(query: ProofQuery): Promise<ProofResult> {
    try {
      const response = await retry(
        () => this.api.post('/v1/proofs/generate', {
          agentAddress: query.agentAddress,
          proofType: query.proofType,
          queryData: query.queryData,
          startBlock: query.startBlock,
          endBlock: query.endBlock,
          network: this.config.network
        }),
        {
          maxAttempts: 3,
          delay: 1000,
          backoff: 'exponential',
        }
      );

      // Poll for proof completion
      const queryId = response.data.queryId;
      let proof = await this.pollForProof(queryId);

      return {
        queryId: queryId,
        verified: proof.verified,
        proof: proof.proof,
        metadata: proof.metadata
      };
    } catch (error: any) {
      if (error instanceof AxiosError) {
        throw new BrevisError(
          `Failed to generate Brevis proof: ${error.message}`,
          error.code,
          error
        );
      }
      throw new BrevisError(`Failed to generate Brevis proof: ${error.message}`, undefined, error);
    }
  }

  /**
   * Poll for proof generation status
   * @param queryId Query identifier
   * @returns Proof result when ready
   */
  private async pollForProof(queryId: string): Promise<ProofResult> {
    const maxAttempts = 60; // 5 minutes max
    const delay = 5000; // 5 seconds

    for (let i = 0; i < maxAttempts; i++) {
      const response = await this.api.get(`/v1/proofs/${queryId}`);
      
      if (response.data.status === 'completed') {
        return {
          queryId: queryId,
          verified: response.data.verified,
          proof: response.data.proof,
          metadata: response.data.metadata
        };
      }

      if (response.data.status === 'failed') {
        throw new Error(`Proof generation failed: ${response.data.error}`);
      }

      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, delay));
    }

    throw new Error('Proof generation timeout');
  }

  /**
   * Get proof status
   * @param queryId Query identifier
   * @returns Proof status
   */
  async getProofStatus(queryId: string): Promise<ProofResult> {
    try {
      const response = await retry(
        () => this.api.get(`/v1/proofs/${queryId}`),
        {
          maxAttempts: 3,
          delay: 1000,
        }
      );
      
      return {
        queryId: queryId,
        verified: response.data.verified || false,
        proof: response.data.proof || '',
        metadata: response.data.metadata || ''
      };
    } catch (error: any) {
      if (error instanceof AxiosError) {
        throw new BrevisError(
          `Failed to get Brevis proof status: ${error.message}`,
          error.code,
          error
        );
      }
      throw new BrevisError(`Failed to get Brevis proof status: ${error.message}`, undefined, error);
    }
  }
}


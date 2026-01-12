/**
 * Common types for KYA Protocol integrations
 */

export interface ProofQuery {
  agentAddress: string;
  proofType: string;
  queryData: Record<string, any>;
  startBlock?: number;
  endBlock?: number;
}

export interface ProofResult {
  queryId: string;
  verified: boolean;
  proof: string;
  metadata: string;
}

export interface ClaimData {
  claimId: string;
  tokenId: number;
  merchant: string;
  amount: string;
  reason: string;
  evidence?: any;
}

export interface ResolutionResult {
  requestId: string;
  resolved: boolean;
  result: boolean;
  timestamp?: number;
  challenger?: string | null;
  resolutionData?: any;
}

export interface UserOperation {
  sender: string;
  nonce: number;
  callData: string;
  callGasLimit: number;
  verificationGasLimit: number;
  preVerificationGas: number;
  maxFeePerGas: number;
  maxPriorityFeePerGas: number;
  paymasterAndData?: string;
  signature?: string;
}

export interface PaymasterData {
  tokenId: number;
  userOp: UserOperation;
  maxCost: string;
}


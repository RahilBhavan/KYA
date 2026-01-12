/**
 * Basic Usage Examples for KYA Protocol SDK
 */

import { ethers } from 'ethers';
import {
  AxiomClient,
  UMAClient,
  EntryPointClient,
  loadConfig,
  retry,
} from '@kya-protocol/integrations';

// Example 1: Generate ZK Proof with Axiom
async function exampleAxiomProof() {
  const config = loadConfig();
  
  if (!config.axiom) {
    throw new Error('Axiom configuration not found');
  }

  const axiom = new AxiomClient(config.axiom);
  const provider = new ethers.JsonRpcProvider(config.rpcUrl);

  // Generate proof for Uniswap volume
  const proof = await axiom.generateProof({
    agentAddress: '0x...', // TBA address
    proofType: 'UniswapVolume',
    queryData: {
      contract: 'UniswapV3Router',
      minVolume: 10000,
    },
    startBlock: 10000000,
    endBlock: 11000000,
  });

  console.log('Proof generated:', proof.queryId);
  console.log('Verified:', proof.verified);
  console.log('Metadata:', proof.metadata);

  // Submit to ReputationScore contract
  const reputationScore = new ethers.Contract(
    '0x...', // ReputationScore address
    ['function verifyProof(uint256,string,bytes,string)'],
    provider
  );

  // This would be called by the ZK prover (Axiom) with proper role
  // await reputationScore.verifyProof(tokenId, 'UniswapVolume', proof.proof, proof.metadata);
}

// Example 2: Submit Claim to UMA
async function exampleUMAClaim() {
  const config = loadConfig();
  
  if (!config.uma) {
    throw new Error('UMA configuration not found');
  }

  const uma = new UMAClient(config.uma);
  const provider = new ethers.JsonRpcProvider(config.rpcUrl);

  // Submit claim on-chain first
  const insuranceVault = new ethers.Contract(
    '0x...', // InsuranceVault address
    ['function submitClaim(uint256,uint256,string) returns (bytes32)'],
    provider
  );

  const tokenId = 1;
  const claimAmount = ethers.parseUnits('1000', 6); // 1000 USDC
  const reason = 'Malicious behavior detected';

  // Submit claim (requires merchant to sign)
  // const claimId = await insuranceVault.submitClaim(tokenId, claimAmount, reason);

  // Submit to UMA for resolution
  const requestId = await uma.submitClaim({
    claimId: '0x...', // From submitClaim
    tokenId: tokenId,
    merchant: '0x...', // Merchant address
    amount: claimAmount.toString(),
    reason: reason,
    evidence: {
      transactionHash: '0x...',
      description: 'Agent executed malicious transaction',
    },
  });

  console.log('Claim submitted to UMA:', requestId);

  // Poll for resolution
  const resolution = await uma.pollForResolution(requestId);
  console.log('Resolution:', resolution);

  // Resolve on-chain
  if (resolution.resolved) {
    // This would be called by oracle with proper role
    // await insuranceVault.resolveClaim(claimId, resolution.result);
  }
}

// Example 3: Create User Operation for Paymaster
async function exampleUserOperation() {
  const config = loadConfig();
  
  if (!config.entryPoint) {
    throw new Error('EntryPoint configuration not found');
  }

  const provider = new ethers.JsonRpcProvider(config.rpcUrl);
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  const entryPoint = new EntryPointClient(config.entryPoint, provider, signer);

  // Create user operation
  const userOp = entryPoint.createUserOperation({
    sender: '0x...', // Agent TBA address
    callData: '0x...', // Encoded function call
    nonce: await entryPoint.getNonce('0x...'), // Get nonce
  });

  // Get user operation hash
  const userOpHash = await entryPoint.getUserOpHash(userOp);

  // Sign user operation
  const signature = await signer.signMessage(ethers.getBytes(userOpHash));
  userOp.signature = signature;

  // Submit via bundler (e.g., Pimlico)
  const bundlerUrl = 'https://api.pimlico.io/v1/base-sepolia/rpc';
  const userOpHashResult = await entryPoint.submitUserOperation(userOp, bundlerUrl);

  console.log('User operation submitted:', userOpHashResult);
}

// Example 4: Error Handling with Retry
async function exampleWithRetry() {
  const config = loadConfig();
  const axiom = new AxiomClient(config.axiom!);

  try {
    const proof = await retry(
      () => axiom.generateProof({
        agentAddress: '0x...',
        proofType: 'UniswapVolume',
        queryData: { minVolume: 10000 },
      }),
      {
        maxAttempts: 5,
        delay: 2000,
        backoff: 'exponential',
      }
    );

    console.log('Proof generated:', proof);
  } catch (error: any) {
    if (error.name === 'AxiomError') {
      console.error('Axiom error:', error.message);
      console.error('Code:', error.code);
    } else {
      console.error('Unexpected error:', error);
    }
  }
}

// Run examples
async function main() {
  try {
    // await exampleAxiomProof();
    // await exampleUMAClaim();
    // await exampleUserOperation();
    // await exampleWithRetry();
    console.log('Examples ready - uncomment to run');
  } catch (error) {
    console.error('Error:', error);
  }
}

if (require.main === module) {
  main();
}


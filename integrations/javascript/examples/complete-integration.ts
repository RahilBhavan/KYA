/**
 * Complete Integration Example
 * Demonstrates full workflow: ZK proof generation, claim submission, and resolution
 */

import { ethers } from 'ethers';
import {
  AxiomClient,
  UMAClient,
  EntryPointClient,
  ReputationScoreContract,
  InsuranceVaultContract,
  ZKAdapterContract,
  OracleAdapterContract,
  loadConfig,
} from '@kya-protocol/integrations';

/**
 * Complete workflow example
 */
async function completeWorkflow() {
  // Load configuration
  const config = loadConfig();
  if (!config.rpcUrl) {
    throw new Error('RPC_URL not configured');
  }

  const provider = new ethers.JsonRpcProvider(config.rpcUrl);
  const signer = config.privateKey
    ? new ethers.Wallet(config.privateKey, provider)
    : undefined;

  // Contract addresses (should be from deployment)
  const REPUTATION_SCORE_ADDRESS = process.env.REPUTATION_SCORE_ADDRESS || '0x...';
  const INSURANCE_VAULT_ADDRESS = process.env.INSURANCE_VAULT_ADDRESS || '0x...';
  const ZK_ADAPTER_ADDRESS = process.env.ZK_ADAPTER_ADDRESS || '0x...';
  const ORACLE_ADAPTER_ADDRESS = process.env.ORACLE_ADAPTER_ADDRESS || '0x...';

  // Initialize contracts
  const reputationScore = new ReputationScoreContract(
    REPUTATION_SCORE_ADDRESS,
    provider,
    signer
  );

  const insuranceVault = new InsuranceVaultContract(
    INSURANCE_VAULT_ADDRESS,
    provider,
    signer
  );

  const zkAdapter = new ZKAdapterContract(
    ZK_ADAPTER_ADDRESS,
    provider,
    signer
  );

  const oracleAdapter = new OracleAdapterContract(
    ORACLE_ADAPTER_ADDRESS,
    provider,
    signer
  );

  // Example: Generate ZK proof and update reputation
  async function generateAndVerifyProof() {
    if (!config.axiom) {
      throw new Error('Axiom configuration not found');
    }

    const axiom = new AxiomClient(config.axiom);
    const tokenId = 1;
    const tbaAddress = '0x...'; // Agent TBA address

    // Step 1: Generate proof via Axiom
    console.log('Generating ZK proof via Axiom...');
    const proof = await axiom.generateProof({
      agentAddress: tbaAddress,
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

    // Step 2: Submit query to ZKAdapter
    console.log('Submitting query to ZKAdapter...');
    const queryId = await zkAdapter.submitQuery({
      agentAddress: tbaAddress,
      proofType: 'UniswapVolume',
      queryData: {
        contract: 'UniswapV3Router',
        minVolume: 10000,
      },
      startBlock: 10000000,
      endBlock: 11000000,
    });

    // Step 3: Process proof and update reputation (requires admin role)
    console.log('Processing proof and updating reputation...');
    await zkAdapter.processProofAndUpdate(
      queryId,
      tokenId,
      proof.proof,
      proof.metadata
    );

    // Step 4: Verify reputation updated
    const reputation = await reputationScore.getReputation(tokenId);
    console.log('Reputation updated:', {
      score: reputation.score.toString(),
      tier: reputation.tier,
      verifiedProofs: reputation.verifiedProofs,
    });
  }

  // Example: Submit claim and resolve via oracle
  async function submitAndResolveClaim() {
    if (!config.uma) {
      throw new Error('UMA configuration not found');
    }

    const uma = new UMAClient(config.uma);
    const tokenId = 1;
    const claimAmount = ethers.parseUnits('1000', 6); // 1000 USDC
    const reason = 'Malicious behavior detected';

    // Step 1: Submit claim on-chain
    console.log('Submitting claim on-chain...');
    if (!signer) {
      throw new Error('Signer required for submitClaim');
    }

    const claimId = await insuranceVault.submitClaim(
      tokenId,
      claimAmount,
      reason
    );
    console.log('Claim submitted:', claimId);

    // Step 2: Submit to UMA oracle
    console.log('Submitting claim to UMA oracle...');
    const requestId = await uma.submitClaim({
      claimId: claimId,
      tokenId: tokenId,
      merchant: signer.address,
      amount: claimAmount.toString(),
      reason: reason,
      evidence: {
        transactionHash: '0x...',
        description: 'Agent executed malicious transaction',
      },
    });
    console.log('Claim submitted to UMA:', requestId);

    // Step 3: Submit to OracleAdapter
    console.log('Submitting to OracleAdapter...');
    const oracleRequestId = await oracleAdapter.submitClaim({
      claimId: claimId,
      tokenId: tokenId,
      merchant: signer.address,
      amount: claimAmount.toString(),
      reason: reason,
      evidence: {
        transactionHash: '0x...',
      },
    });

    // Step 4: Poll for resolution
    console.log('Polling for resolution...');
    const resolution = await uma.pollForResolution(requestId);
    console.log('Resolution received:', resolution);

    // Step 5: Process resolution on-chain (requires admin role)
    if (resolution.resolved) {
      console.log('Processing resolution on-chain...');
      await oracleAdapter.processResolution(
        oracleRequestId,
        resolution.result,
        JSON.stringify(resolution.resolutionData || {})
      );
      console.log('Resolution processed');
    }
  }

  // Example: Use Paymaster for gasless transactions
  async function usePaymaster() {
    if (!config.entryPoint) {
      throw new Error('EntryPoint configuration not found');
    }

    const entryPoint = new EntryPointClient(config.entryPoint, provider, signer);
    const tbaAddress = '0x...'; // Agent TBA address
    const paymasterAddress = process.env.PAYMASTER_ADDRESS || '0x...';

    // Create user operation
    const userOp = await entryPoint.createUserOperation({
      sender: tbaAddress,
      callData: '0x...', // Encoded function call
    });

    // Add paymaster data
    const paymasterData = ethers.AbiCoder.defaultAbiCoder().encode(
      ['uint256', 'bytes'],
      [1, '0x'] // tokenId, userOp
    );
    userOp.paymasterAndData = ethers.concat([paymasterAddress, paymasterData]);

    // Get user operation hash
    const userOpHash = await entryPoint.getUserOpHash(userOp);

    // Sign user operation (if needed)
    if (signer) {
      const signature = await signer.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = signature;
    }

    // Submit via bundler
    const bundlerUrl = process.env.BUNDLER_URL || 'https://api.pimlico.io/v1/base-sepolia/rpc';
    const result = await entryPoint.submitUserOperation(userOp, bundlerUrl);
    console.log('User operation submitted:', result);
  }

  // Run examples
  console.log('Complete integration examples ready');
  console.log('Uncomment to run:');
  // await generateAndVerifyProof();
  // await submitAndResolveClaim();
  // await usePaymaster();
}

if (require.main === module) {
  completeWorkflow().catch(console.error);
}

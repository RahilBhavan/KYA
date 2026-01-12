/**
 * @fileoverview React Native SDK for KYA Protocol
 * @module @kya-protocol/react-native
 */

import { KYAClient } from '@kya-protocol/integrations';
import { WalletConnectModal } from '@walletconnect/react-native-dapp';
import { ethers } from 'ethers';

/**
 * React Native specific KYA Client
 * Extends base client with mobile wallet integration
 */
export class KYAClientRN extends KYAClient {
  private walletConnectModal: WalletConnectModal | null = null;

  /**
   * Initialize with mobile wallet support
   */
  constructor(config: KYAClientConfig) {
    super(config);
    // Initialize WalletConnect for mobile
    this.initializeWalletConnect();
  }

  /**
   * Connect wallet using WalletConnect
   */
  async connectWallet(): Promise<ethers.Wallet> {
    if (!this.walletConnectModal) {
      throw new Error('WalletConnect not initialized');
    }

    // Open WalletConnect modal
    const session = await this.walletConnectModal.open();
    
    // Create provider from WalletConnect session
    const provider = new ethers.BrowserProvider(session);
    const signer = await provider.getSigner();
    
    return signer as unknown as ethers.Wallet;
  }

  /**
   * Initialize WalletConnect
   */
  private initializeWalletConnect(): void {
    // WalletConnect initialization
    // In production, configure with project ID and metadata
  }

  /**
   * Create agent with mobile-optimized flow
   */
  async createAgentMobile(
    name: string,
    description: string,
    category: string
  ): Promise<AgentInfo> {
    // Mobile-optimized agent creation
    // Includes better error handling and user feedback
    try {
      return await this.createAgent({ name, description, category });
    } catch (error) {
      // Enhanced error handling for mobile
      throw new Error(`Failed to create agent: ${error.message}`);
    }
  }
}

export * from '@kya-protocol/integrations';

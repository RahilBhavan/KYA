/**
 * Configuration for KYA Protocol integrations
 */

export interface AxiomConfig {
  apiKey: string;
  address?: string;
  network: string;
  baseUrl?: string;
}

export interface BrevisConfig {
  apiKey: string;
  address?: string;
  network: string;
  baseUrl?: string;
}

export interface UMAConfig {
  apiKey: string;
  address?: string;
  network: string;
  baseUrl?: string;
}

export interface KlerosConfig {
  apiKey: string;
  address?: string;
  network: string;
  baseUrl?: string;
}

export interface EntryPointConfig {
  address: string;
  network: string;
}

export interface IntegrationConfig {
  axiom?: AxiomConfig;
  brevis?: BrevisConfig;
  uma?: UMAConfig;
  kleros?: KlerosConfig;
  entryPoint?: EntryPointConfig;
  rpcUrl?: string;
  privateKey?: string;
}

/**
 * Load configuration from environment variables
 */
export function loadConfig(): IntegrationConfig {
  return {
    axiom: process.env.AXIOM_API_KEY ? {
      apiKey: process.env.AXIOM_API_KEY,
      address: process.env.AXIOM_ADDRESS,
      network: process.env.NETWORK || 'base-sepolia',
      baseUrl: process.env.AXIOM_BASE_URL
    } : undefined,
    brevis: process.env.BREVIS_API_KEY ? {
      apiKey: process.env.BREVIS_API_KEY,
      address: process.env.BREVIS_ADDRESS,
      network: process.env.NETWORK || 'base-sepolia',
      baseUrl: process.env.BREVIS_BASE_URL
    } : undefined,
    uma: process.env.UMA_API_KEY ? {
      apiKey: process.env.UMA_API_KEY,
      address: process.env.UMA_ADDRESS,
      network: process.env.NETWORK || 'base-sepolia',
      baseUrl: process.env.UMA_BASE_URL
    } : undefined,
    kleros: process.env.KLEROS_API_KEY ? {
      apiKey: process.env.KLEROS_API_KEY,
      address: process.env.KLEROS_ADDRESS,
      network: process.env.NETWORK || 'base-sepolia',
      baseUrl: process.env.KLEROS_BASE_URL
    } : undefined,
    entryPoint: {
      address: process.env.ENTRY_POINT_ADDRESS || '0x0000000071727De22E5E9d8BAf0edAc6f37da032',
      network: process.env.NETWORK || 'base-sepolia'
    },
    rpcUrl: process.env.RPC_URL,
    privateKey: process.env.PRIVATE_KEY
  };
}


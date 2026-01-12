import { gql } from '@apollo/client';

/**
 * Get all agents
 */
export const GET_AGENTS = gql`
  query GetAgents($first: Int, $skip: Int) {
    agents(first: $first, skip: $skip, orderBy: createdAt, orderDirection: desc) {
      id
      tokenId
      tbaAddress
      owner
      name
      category
      status
      createdAt
      reputation {
        score
        tier
        verifiedProofs
      }
      stakes {
        amount
        isVerified
      }
    }
  }
`;

/**
 * Get agent by tokenId
 */
export const GET_AGENT = gql`
  query GetAgent($tokenId: BigInt!) {
    agent(id: $tokenId) {
      id
      tokenId
      tbaAddress
      owner
      name
      description
      category
      reputation {
        score
        tier
        verifiedProofs
        badges {
          name
          description
        }
        categoryScores {
          category
          score
        }
      }
      stakes {
        amount
        isVerified
        stakedAt
      }
      claims {
        id
        amount
        status
        submittedAt
      }
    }
  }
`;

/**
 * Get protocol statistics
 */
export const GET_PROTOCOL_STATS = gql`
  query GetProtocolStats {
    protocolStats(id: "global") {
      totalAgents
      totalStaked
      totalReputationScore
      totalClaims
      totalVerifiedAgents
      lastUpdated
    }
  }
`;

/**
 * Get reputation updates
 */
export const GET_REPUTATION_UPDATES = gql`
  query GetReputationUpdates($tokenId: BigInt!, $first: Int) {
    reputationUpdates(
      where: { reputation: $tokenId }
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      oldScore
      newScore
      oldTier
      newTier
      proofType
      scoreIncrease
      timestamp
    }
  }
`;

/**
 * Search agents
 */
export const SEARCH_AGENTS = gql`
  query SearchAgents($search: String!) {
    agents(
      where: {
        or: [
          { name_contains_nocase: $search }
          { description_contains_nocase: $search }
          { category_contains_nocase: $search }
        ]
      }
      first: 20
    ) {
      id
      tokenId
      name
      category
      reputation {
        score
        tier
      }
    }
  }
`;

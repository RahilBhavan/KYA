# Axiom Setup - Alternative Methods

Since the Axiom CLI requires Rust installation, here are alternative ways to get the Axiom contract address.

---

## Option 1: Install Rust + Axiom CLI (Full Setup)

### Step 1: Install Rust

```bash
# Install Rust (this will also install Cargo)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Follow the prompts, then reload your shell
source ~/.cargo/env

# Verify installation
rustc --version
cargo --version
```

### Step 2: Install Axiom CLI

```bash
# Install Axiom CLI
cargo +1.86 install --locked --git https://github.com/axiom-crypto/axiom-api-cli.git --tag v1.0.1 cargo-axiom

# Verify installation
cargo axiom --version
```

### Step 3: Get API Key and Register

```bash
# 1. Sign up at https://axiom.xyz
# 2. Get API key from Dashboard → API Keys
# 3. Register with CLI
export AXIOM_API_KEY=your_api_key_here
cargo axiom register --api-key $AXIOM_API_KEY
```

### Step 4: Get Contract Address

```bash
# Get address for Base Sepolia
cargo axiom get-address --chain-id 84532

# Get address for Base Mainnet
cargo axiom get-address --chain-id 8453
```

---

## Option 2: Check Axiom Documentation (No Installation Required)

### Method 1: Check Official Documentation

1. **Visit Axiom Documentation**:
   - Go to: https://docs.axiom.xyz/
   - Navigate to "Contract Addresses" or "Deployments" section
   - Look for Base Sepolia (Chain ID: 84532) or Base Mainnet (Chain ID: 8453)

2. **Find AxiomV2Query Contract**:
   - The contract you need is typically called "AxiomV2Query"
   - Look for the address on Base Sepolia testnet

3. **Add to `.env`**:
   ```bash
   AXIOM_ADDRESS=0x...  # Address from documentation
   ```

### Method 2: Check Axiom GitHub

1. **Visit Axiom GitHub**:
   - Go to: https://github.com/axiom-crypto
   - Look for deployment documentation or contract addresses

2. **Check Recent Releases**:
   - Check release notes for deployment addresses
   - Look for Base network deployments

---

## Option 3: Contact Axiom Support

### Method 1: Discord

1. **Join Axiom Discord**:
   - Visit: https://discord.gg/axiom
   - Ask in support channel: "What is the AxiomV2Query contract address for Base Sepolia?"

### Method 2: Email/Support

1. **Contact Axiom Team**:
   - Email: support@axiom.xyz
   - Ask for Base Sepolia contract addresses

### Method 3: Twitter/Social Media

1. **Reach Out on Social Media**:
   - Twitter: @axiom_xyz
   - Ask for Base Sepolia deployment addresses

---

## Option 4: Search BaseScan

### Method 1: Search for Axiom Contracts

1. **Go to BaseScan**:
   - Base Sepolia: https://sepolia.basescan.org
   - Search for: "Axiom" or "AxiomV2Query"

2. **Verify Contract**:
   - Check if it's the official Axiom contract
   - Verify with Axiom team if unsure

3. **Add to `.env`**:
   ```bash
   AXIOM_ADDRESS=0x...  # Address from BaseScan
   ```

### Method 2: Check Recent Deployments

1. **Look for Recent Contract Creations**:
   - Filter by contract name containing "Axiom"
   - Check deployment dates
   - Verify with Axiom team

---

## Option 5: Use Axiom API (If Available)

### Check API Documentation

1. **Visit Axiom API Docs**:
   - Check if they have a REST API endpoint for contract addresses
   - Look for: https://api.axiom.xyz or similar

2. **Query API**:
   ```bash
   # Example (if API exists)
   curl https://api.axiom.xyz/v1/contracts/base-sepolia
   ```

---

## Quick Reference: What You Need

**For Base Sepolia Testnet**:
- Contract Name: `AxiomV2Query` (or similar)
- Chain ID: `84532`
- Network: Base Sepolia

**For Base Mainnet**:
- Contract Name: `AxiomV2Query` (or similar)
- Chain ID: `8453`
- Network: Base Mainnet

---

## Verification After Getting Address

Once you have the address, verify it:

```bash
# Check if contract exists
cast code $AXIOM_ADDRESS --rpc-url $BASE_SEPOLIA_RPC_URL

# Should return bytecode (not empty)
```

---

## Recommended Approach

**If you just need the address quickly**:
1. ✅ Check Axiom documentation (Option 2) - Fastest
2. ✅ Search BaseScan (Option 4) - If documentation doesn't have it
3. ✅ Contact Axiom support (Option 3) - If you can't find it

**If you plan to use Axiom extensively**:
1. ✅ Install Rust + CLI (Option 1) - Best for ongoing use
2. ✅ Get API key and set up full integration

---

## Note

**The Axiom address is optional** - The protocol works without it. You only need it if you want to enable:
- ZK proof verification
- Badge system
- Proof-based reputation updates

You can deploy the protocol first and add Axiom later when you have the address.

---

**Last Updated**: 2026-01-06

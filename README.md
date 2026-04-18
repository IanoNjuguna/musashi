# Musashi SDK: Forge Programmable Index Funds on Cardano

Musashi provides the core smart contracts and off-chain tooling required to quickly deploy secure, Oracle-priced Index Funds on the Cardano blockchain.

### Architecture
Musashi operates via a unified **Dual-Validator ETF Architecture**. Developers can choose between two models when deploying a fund:

#### 1. Open-Ended Fund (`open_pool.ak`)
The standard, elastic-supply model. As users deposit ADA, the smart contract mints new `$INDEX` tokens. As they withdraw, the tokens are burned. The Net Asset Value (NAV) perfectly pegs to the underlying collateral.

#### 2. Closed-Ended Fund (`closed_pool.ak`)
The "Meme Coin in a Three-Piece Suit" model. The fund creator mints a strictly fixed supply (e.g. 1,000,000 tokens) upfront and locks them in the pool. The contract then acts as an Automated Vending Machine, dispensing tokens to depositors at the exact Oracle-derived NAV price until the reserve runs dry. No tokens can ever be minted or burned.

### Fund Actions (Open & Closed)
1. **Deposit (Mint/Buy):** Users deposit Cardano Native Assets (like `$ADA`, `$DJED`, or `$SNEK`) directly into the central Index Pool.
2. **NAV Calculation:** The smart contract is secured by Charli3 Oracle Feeds to dynamically calculate the global pool's Net Asset Value (NAV) in USD.
3. **Distribution:** Based on this NAV, the smart contract either mints or dispenses proportionate, fractional `$INDEX` tokens for the user.
4. **Withdrawal (Burn/Sell):** Users can return their `$INDEX` tokens at any time to seamlessly withdraw their exact proportional slice of the pool's underlying collateral.
5. **Yield Compounding (Open Pool):** Cardano's native staking rewards can be periodically injected into the pool via the `CompoundYield` action. By increasing the pool's `$ADA` reserves without minting new `$INDEX` tokens, the Net Asset Value (NAV) of the fund proportionally appreciates.

## Development Status

- ✅ **Phase 1:** Oracle & Security Layer (Completed)
- ✅ **Phase 2:** The ETF Pool Validator & NAV Math (Completed)
- 🚧 **Phase 3:** Off-Chain Integration & SDK Builder (In Progress)

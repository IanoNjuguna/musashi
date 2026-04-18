# Musashi SDK: 48-Hour MVP Roadmap

## Phase 1: Oracle & Data Layer (Day 1 Morning)

- [x] **Task 1:** Set up an Aiken project (`aiken new musashi/core`).
- [x] **Task 2:** Import `charli3-aiken-lib`.
- [x] **Task 3:** Define a `PriceIdentifier` to ensure the contract only listens to official Charli3 feeds (verify Policy ID).
* **Guide:** [Aiken Documentation](https://aiken-lang.org/installation) | [Charli3 Integration Repo](https://github.com/Charli3-Official)

## Phase 2: The ETF Pool Validator (Day 1 Afternoon/Night)
- [x] **Task 1:** Write the `MintIndex` function. It must validate that the user is receiving the correct fractional share of the pool based on NAV math and Oracle pricing.
- [x] **Task 2:** Write the `BurnIndex` logic. It ensures users can return $INDEX tokens to withdraw a proportional share of the $ADA pool safely.
- [x] **Task 3:** Architecture Pivot. Replaced complex MakerDAO-style CDP Vault mechanics (and liquidation risks) with a unified ETF Pool model.
* **Guide:** Implemented standard Net Asset Value (NAV) mathematical verifications in Aiken.

## Phase 3: Integration & Testing (Day 2)
- [ ] **Task 1:** Use a Python or JS SDK to build the "Pull" request. This script triggers the Charli3 node to provide a fresh price.
- [ ] **Task 2:** Write a deployment script to the **Preview Testnet**.
- [ ] **Task 3:** Verification. Perform a "Mint -> Price Drop -> Burn" cycle to ensure the math holds.
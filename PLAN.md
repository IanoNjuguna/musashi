# Musashi SDK: 48-Hour MVP Roadmap

## Phase 1: Oracle & Data Layer (Day 1 Morning)

- [x] **Task 1:** Set up an Aiken project (`aiken new musashi/core`).
- [x] **Task 2:** Import `charli3-aiken-lib`.
- [ ] **Task 3:** Define a `PriceIdentifier` to ensure the contract only listens to official Charli3 feeds (verify Policy ID).
* **Guide:** [Aiken Documentation](https://aiken-lang.org/installation) | [Charli3 Integration Repo](https://github.com/Charli3-Official)

## Phase 2: The Vault Validator (Day 1 Afternoon/Night)
- [ ] **Task 1:** Write the `mint_index` function. It must validate that the user is providing enough $ADA based on the $INDEX price fetched from the Oracle.
- [ ] **Task 2:** Implement a **Liquidation Logic** placeholder. If the collateral value drops, the vault must be markable for liquidation.
- [ ] **Task 3:** Set up a 0.3% "Streaming Fee" logic to ensure platform profitability.
* **Guide:** Look into the "EUTXO Debt Ledger" pattern for tracking synthetic mints.

## Phase 3: Integration & Testing (Day 2)
- [ ] **Task 1:** Use a Python or JS SDK to build the "Pull" request. This script triggers the Charli3 node to provide a fresh price.
- [ ] **Task 2:** Write a deployment script to the **Preview Testnet**.
- [ ] **Task 3:** Verification. Perform a "Mint -> Price Drop -> Burn" cycle to ensure the math holds.
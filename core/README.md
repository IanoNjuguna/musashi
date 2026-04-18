# musashi/core

Aiken smart contracts for the **Musashi SDK** — an index fund protocol built on Cardano.

Users deposit CIP-30 tokens (e.g. `$DJED` or `$ADA`) as collateral into a vault to mint synthetic index tokens (`$INDEX`). Collateral ratios are enforced on-chain using price data from [Charli3](https://charli3.io) decentralised oracles.

---

## Project Structure

```
core/
├── lib/
│   ├── oracle_datum.ak       # Charli3 oracle datum types (ported to stdlib v3)
│   └── price_identifier.ak   # PriceIdentifier — pins contract to official oracle feed
├── validators/
│   └── placeholder.ak        # Vault validator scaffold (Phase 2 — WIP)
└── env/                      # Environment-specific config
```

---

## Modules

### `oracle_datum`
A stdlib v3-compatible port of the [Charli3 oracle datum library](https://github.com/Charli3-Official/oracle-integration-aiken).

Provides the `OracleDatum` type and helpers to safely read price, timestamp, and expiry from a Charli3 oracle UTXO.

### `price_identifier`
Defines the `PriceIdentifier` type — a feed identity anchor that prevents the vault from accepting spoofed oracle data.

Provides:
- `validate_oracle` — checks feed identity and data freshness
- `get_verified_price` — validates and returns the price in one call, fails hard on invalid input

---

## Development

**Run tests:**
```sh
aiken check
```

**Build contracts:**
```sh
aiken build
```

**Generate docs:**
```sh
aiken docs
```

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `aiken-lang/stdlib` | `v3.0.0` | Aiken standard library (Plutus v3) |

> **Note:** The official `Charli3-Official/oracle-integration-aiken` library targets stdlib v1.9.0 (Plutus v2) and is incompatible with this project. Oracle datum types have been ported locally into `lib/oracle_datum.ak`.

---

## Resources

- [Aiken Documentation](https://aiken-lang.org)
- [Charli3 Oracle Docs](https://docs.charli3.io)
- [Cardano Developer Portal](https://developers.cardano.org)

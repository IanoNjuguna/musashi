// oracle_datum.ak
//
// WHY THIS FILE EXISTS:
// Charli3's official `oracle-integration-aiken` library was built against
// stdlib v1.9.0 (Plutus v2). Our project uses stdlib v3.0.0 (Plutus v3).
// The module paths changed significantly between these versions and the two
// are not compatible. Rather than downgrade the whole project, we port the
// ~30 lines of Charli3 oracle types we actually need and stay on the modern
// stack. The logic is identical — only the import paths differ.
//
// Source: https://github.com/Charli3-Official/oracle-integration-aiken
// Attribution: Charli3-Official (Apache-2.0)

use aiken/cbor
use aiken/collection/pairs
use aiken/crypto.{Blake2b_224, Hash}

// ─── Types ───────────────────────────────────────────────────────────────────

/// A map of integer key → integer value pairs.
/// Charli3 encodes price data with known keys:
///   0 = price, 1 = timestamp, 2 = expiry
pub type PriceMap =
  Pairs<Int, Int>

/// The three variants Charli3 supports in their oracle datum.
/// We only use GenericData; SharedData and ExtendedData are reserved for
/// future Charli3 protocol upgrades.
pub type PriceData {
  SharedData
  ExtendedData
  GenericData { price_map: PriceMap }
}

/// Top-level oracle datum. This is the type you find sitting in a Charli3
/// oracle UTXO on-chain.
pub type OracleDatum {
  price_data: PriceData,
}

/// ValidatorHash identifies a specific Plutus script on Cardano.
/// We use it to confirm we are reading from the *official* Charli3 oracle
/// UTXO and not a spoofed one.
///
/// WHY ByteArray: In stdlib v3, script hashes are Blake2b-224 digests
/// (28 bytes). The Hash<Blake2b_224, Script> alias from v1 resolves to
/// the same underlying ByteArray — we just express it directly here.
pub type ValidatorHash =
  Hash<Blake2b_224, ByteArray>

// ─── Getters ─────────────────────────────────────────────────────────────────

/// Extracts the price (key 0) from a PriceData.
/// Fails hard if the key is missing or the data is not GenericData.
/// WHY: silent failures (returning 0) in DeFi create exploitable edge cases.
pub fn get_price(price_data: PriceData) -> Int {
  when price_data is {
    GenericData { price_map } ->
      when pairs.get_first(price_map, 0) is {
        Some(price) -> price
        None -> fail @"Price not found"
      }
    _ -> fail @"Invalid PriceData variant"
  }
}

/// Extracts the timestamp (key 1) from a PriceData.
pub fn get_timestamp(price_data: PriceData) -> Int {
  when price_data is {
    GenericData { price_map } ->
      when pairs.get_first(price_map, 1) is {
        Some(timestamp) -> timestamp
        None -> fail @"Timestamp not found"
      }
    _ -> fail @"Invalid PriceData variant"
  }
}

/// Extracts the expiry (key 2) from a PriceData.
pub fn get_expiry(price_data: PriceData) -> Int {
  when price_data is {
    GenericData { price_map } ->
      when pairs.get_first(price_map, 2) is {
        Some(expiry) -> expiry
        None -> fail @"Expiry not found"
      }
    _ -> fail @"Invalid PriceData variant"
  }
}

/// Returns True if `current_time` is before or at the oracle's expiry.
/// WHY: stale price data could be used to exploit vault collateral ratios.
pub fn is_oracle_valid(oracle_datum: OracleDatum, current_time: Int) -> Bool {
  current_time <= get_expiry(oracle_datum.price_data)
}

/// Convenience: get price directly from an OracleDatum.
pub fn get_oracle_price(oracle_datum: OracleDatum) -> Int {
  get_price(oracle_datum.price_data)
}

/// Convenience: get timestamp directly from an OracleDatum.
pub fn get_oracle_timestamp(oracle_datum: OracleDatum) -> Int {
  get_timestamp(oracle_datum.price_data)
}

/// Constructs a test OracleDatum from raw values. Useful in unit tests.
pub fn create_oracle_datum(price: Int, timestamp: Int, expiry: Int) -> OracleDatum {
  OracleDatum {
    price_data: GenericData {
      price_map: [Pair(0, price), Pair(1, timestamp), Pair(2, expiry)],
    },
  }
}

// ─── Tests ───────────────────────────────────────────────────────────────────

test create_and_get_price() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  get_price(datum.price_data) == 2723 && get_oracle_price(datum) == 2723
}

test create_and_get_timestamp() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  get_timestamp(datum.price_data) == 1720056807332 && get_oracle_timestamp(datum) == 1720056807332
}

test create_and_get_expiry() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  get_expiry(datum.price_data) == 1720078407332
}

test is_oracle_valid_within_expiry() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  is_oracle_valid(datum, 1720056807332) == True
}

test is_oracle_invalid_past_expiry() {
  let datum = create_oracle_datum(2723, 1720056807332, 1720078407332)
  is_oracle_valid(datum, 1720078407333) == False
}

test oracle_datum_cbor_diagnostic() {
  let datum =
    OracleDatum {
      price_data: GenericData(
        [Pair(0, 490850), Pair(1, 1707172554600), Pair(2, 1707176154600)],
      ),
    }
  let expected =
    @"121([_ 123([_ {_ 0: 490850, 1: 1707172554600, 2: 1707176154600 }])])"
  cbor.diagnostic(datum) == expected
}

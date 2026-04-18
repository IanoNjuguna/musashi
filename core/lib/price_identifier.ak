// price_identifier.ak
//
// WHY THIS FILE EXISTS:
// In a Cardano smart contract, you can't blindly trust any UTXO sitting at
// a script address. An attacker could place a fake "oracle" UTXO with a
// fabricated price. The PriceIdentifier solves this by locking in the
// ValidatorHash of the *official* Charli3 oracle script. Our contract will
// ONLY accept price data if the oracle UTXO's script matches this exact
// hash — making oracle spoofing impossible on-chain.

use cardano/assets.{PolicyId}
use oracle_datum.{OracleDatum, ValidatorHash, get_oracle_price, is_oracle_valid}

// ─── Types ───────────────────────────────────────────────────────────────────

/// PriceIdentifier pins the contract to one specific Charli3 oracle feed.
///
/// `oracle_policy_id` is the PolicyId of the token minted by the official
/// Charli3 oracle script. When validating a transaction, we confirm the
/// oracle UTXO holds this token — proving it originated from the real oracle.
pub type PriceIdentifier {
  oracle_policy_id: PolicyId,
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Validates that:
///   1. We are reading from the correct oracle feed (spoof prevention).
///   2. The oracle data has not expired (staleness prevention).
///
/// Returns True only when BOTH conditions pass.
pub fn validate_oracle(
  identifier: PriceIdentifier,
  oracle_validator_hash: ValidatorHash,
  datum: OracleDatum,
  current_time: Int,
) -> Bool {
  // Step 1: Feed identity check.
  // WHY: Without this, an attacker submits a valid-looking OracleDatum
  //      from a script they control, with a price of their choosing.
  let correct_feed = oracle_validator_hash == identifier.oracle_policy_id

  // Step 2: Freshness check.
  // WHY: An old price feed (e.g. from before a price crash) could let an
  //      attacker mint $INDEX with under-collateralised $ADA.
  let not_expired = is_oracle_valid(datum, current_time)

  correct_feed && not_expired
}

/// Validates the oracle and returns the price in one call.
/// Fails the entire transaction if validation does not pass.
///
/// WHY FAIL HARD: In DeFi, a silent failure (returning 0 or None) is more
/// dangerous than a hard revert. We want the TX rejected outright.
pub fn get_verified_price(
  identifier: PriceIdentifier,
  oracle_validator_hash: ValidatorHash,
  datum: OracleDatum,
  current_time: Int,
) -> Int {
  expect True =
    validate_oracle(identifier, oracle_validator_hash, datum, current_time)
  get_oracle_price(datum)
}

// ─── Tests ───────────────────────────────────────────────────────────────────

test validate_oracle_rejects_wrong_feed() {
  let identifier = PriceIdentifier { oracle_policy_id: #"deadbeef" }
  // Simulates a spoofed oracle with a different script hash
  let wrong_hash: ValidatorHash = #"cafebabe"
  let datum = oracle_datum.create_oracle_datum(5000, 1000, 9999999999999)
  validate_oracle(identifier, wrong_hash, datum, 1000) == False
}

test validate_oracle_rejects_expired_data() {
  let identifier = PriceIdentifier { oracle_policy_id: #"deadbeef" }
  let correct_hash: ValidatorHash = #"deadbeef"
  // Expiry at 500, current_time is 9999 — data is stale
  let datum = oracle_datum.create_oracle_datum(5000, 100, 500)
  validate_oracle(identifier, correct_hash, datum, 9999) == False
}

test validate_oracle_accepts_valid_feed() {
  let identifier = PriceIdentifier { oracle_policy_id: #"deadbeef" }
  let correct_hash: ValidatorHash = #"deadbeef"
  let datum = oracle_datum.create_oracle_datum(5000, 1000, 9999999999999)
  validate_oracle(identifier, correct_hash, datum, 1000) == True
}

test get_verified_price_returns_correct_value() {
  let identifier = PriceIdentifier { oracle_policy_id: #"deadbeef" }
  let correct_hash: ValidatorHash = #"deadbeef"
  let datum = oracle_datum.create_oracle_datum(5000, 1000, 9999999999999)
  get_verified_price(identifier, correct_hash, datum, 1000) == 5000
}

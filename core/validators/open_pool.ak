use aiken/collection/list
use aiken/interval.{Finite}
use cardano/address.{Script}
use cardano/assets.{lovelace_of}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use oracle_datum.{OracleDatum}
use price_identifier.{PriceIdentifier, get_verified_price}

// ─── Types ───────────────────────────────────────────────────────────────────

/// Represents the global state of the Musashi Index Pool.
pub type PoolDatum {
  total_index_supply: Int,    // Total circulating supply of $INDEX tokens
}

/// The actions users can take on the Pool.
pub type PoolAction {
  // Deposit collateral to mint fractional $INDEX tokens based on NAV
  MintIndex
  // Return $INDEX tokens to withdraw proportional underlying collateral
  BurnIndex
  // Inject staking rewards into the pool to automatically increase NAV
  CompoundYield
}

// ─── Validator ───────────────────────────────────────────────────────────────

validator musashi_pool(oracle_config: PriceIdentifier, max_supply_cap: Int) {
  
  /// Controls access to the central pool UTXO.
  spend(
    datum: Option<PoolDatum>,
    redeemer: PoolAction,
    utxo: OutputReference,
    self: Transaction,
  ) {
    // Ensure we are working with a valid active pool state
    expect Some(old_pool_state) = datum
    
    // STEP 1: Track State Changes
    // Find the old pool state (Input) and new pool state (Output)
    expect Some(own_input) =
      list.find(self.inputs, fn(i) { i.output_reference == utxo })
    let pool_address = own_input.output.address
    let old_ada = lovelace_of(own_input.output.value)

    expect Some(own_output) =
      list.find(self.outputs, fn(o) { o.address == pool_address })
    let new_ada = lovelace_of(own_output.value)

    expect InlineDatum(datum_data) = own_output.datum
    expect new_pool_state: PoolDatum = datum_data

    // STEP 2: Oracle Fetching
    // Fetch the Live Oracle Price to calculate TVL
    expect Some(oracle_input) =
      list.find(
        self.reference_inputs,
        fn(input) {
          when input.output.address.payment_credential is {
            Script(hash) -> hash == oracle_config.oracle_policy_id
            _ -> False
          }
        },
      )
    expect InlineDatum(oracle_datum_data) = oracle_input.output.datum
    expect oracle_datum: OracleDatum = oracle_datum_data
    expect Finite(current_time) = self.validity_range.upper_bound.bound_type
    
    let ada_price =
      get_verified_price(
        oracle_config,
        oracle_config.oracle_policy_id,
        oracle_datum,
        current_time,
      )

    // STEP 3: The NAV Math
    when redeemer is {
      MintIndex -> {
        let deposited_ada = new_ada - old_ada
        expect deposited_ada > 0

        let minted_tokens = new_pool_state.total_index_supply - old_pool_state.total_index_supply
        expect minted_tokens > 0

        // Enforce the Creator's Hard Cap (If max_supply_cap is 0, the pool is uncapped!)
        let is_within_cap =
          if max_supply_cap > 0 {
            new_pool_state.total_index_supply <= max_supply_cap
          } else {
            True
          }
        expect is_within_cap

        let deposited_usd = deposited_ada * ada_price

        if old_pool_state.total_index_supply == 0 {
          // Genesis Mint: Your initial USD TVL determines the starting index supply!
          minted_tokens == deposited_usd
        } else {
          // Ongoing Mint: Calculate fractional ownership using Net Asset Value (NAV)
          // Mathematical Formula: (Minted Indexed / Old Supply) = (Deposited USD / Old Pool TVL)
          // We cross-multiply to avoid floating point division in Aiken:
          let old_tvl_usd = old_ada * ada_price
          
          (minted_tokens * old_tvl_usd) == (deposited_usd * old_pool_state.total_index_supply)
        }
      }
      
      BurnIndex -> {
        let withdrawn_ada = old_ada - new_ada
        expect withdrawn_ada > 0

        let burned_tokens = old_pool_state.total_index_supply - new_pool_state.total_index_supply
        expect burned_tokens > 0

        let withdrawn_usd = withdrawn_ada * ada_price
        let old_tvl_usd = old_ada * ada_price

        // Reverse NAV Formula: (Withdrawn USD / Old Pool TVL) == (Burned Tokens / Old Supply)
        // Cross-multiplied to avoid decimals:
        (withdrawn_usd * old_pool_state.total_index_supply) == (burned_tokens * old_tvl_usd)
      }

      CompoundYield -> {
        // 1. Strictly enforce that the $INDEX supply does NOT change
        expect new_pool_state.total_index_supply == old_pool_state.total_index_supply
        
        // 2. Strictly enforce that the injected ADA increases the pool TVL
        expect new_ada > old_ada
        
        True
      }
    }
  }
}

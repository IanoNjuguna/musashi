use aiken/collection/list
use aiken/interval.{Finite}
use cardano/address.{Script}
use cardano/assets.{lovelace_of}
use cardano/transaction.{InlineDatum, OutputReference, Transaction}
use oracle_datum.{OracleDatum}
use price_identifier.{PriceIdentifier, get_verified_price}

// ─── Types ───────────────────────────────────────────────────────────────────

pub type ClosedPoolDatum {
  total_fixed_supply: Int,    // E.g., 1,000,000 (Indestructible Hard Cap)
  available_reserve: Int,     // How many $INDEX tokens remain inside the Vault
}

pub type PoolAction {
  // Deposit ADA to withdraw $INDEX from the Vault reserve
  BuyIndex
  // Return $INDEX to the Vault reserve to withdraw ADA
  SellIndex
}

// ─── Validator ───────────────────────────────────────────────────────────────

validator closed_pool(oracle_config: PriceIdentifier) {
  
  spend(
    datum: Option<ClosedPoolDatum>,
    redeemer: PoolAction,
    utxo: OutputReference,
    self: Transaction,
  ) {
    expect Some(old_pool_state) = datum
    
    // 1. Locate UTXOs
    expect Some(own_input) =
      list.find(self.inputs, fn(i) { i.output_reference == utxo })
    let pool_address = own_input.output.address
    let old_ada = lovelace_of(own_input.output.value)

    expect Some(own_output) =
      list.find(self.outputs, fn(o) { o.address == pool_address })
    let new_ada = lovelace_of(own_output.value)

    expect InlineDatum(datum_data) = own_output.datum
    expect new_pool_state: ClosedPoolDatum = datum_data

    // 2. Fetch Live Oracle Price (For TVL USD Calculation)
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

    // 3. Security Core: The Fixed Supply must NEVER change!
    expect new_pool_state.total_fixed_supply == old_pool_state.total_fixed_supply

    // 4. Vending Machine Math
    when redeemer is {
      BuyIndex -> {
        let deposited_ada = new_ada - old_ada
        expect deposited_ada > 0

        let dispensed_tokens = old_pool_state.available_reserve - new_pool_state.available_reserve
        expect dispensed_tokens > 0

        let deposited_usd = deposited_ada * ada_price

        if old_pool_state.available_reserve == old_pool_state.total_fixed_supply {
          // Genesis Buy (Establishing NAV value of the fixed supply based on initial USD deposit)
          dispensed_tokens == deposited_usd
        } else {
          // Standard AMM NAV Dispensing Formula:
          // (Dispensed Tokens / Total Fixed Supply) == (Deposited USD / Old Pool TVL)
          let old_tvl_usd = old_ada * ada_price
          
          (dispensed_tokens * old_tvl_usd) == (deposited_usd * old_pool_state.total_fixed_supply)
        }
      }
      
      SellIndex -> {
        let withdrawn_ada = old_ada - new_ada
        expect withdrawn_ada > 0

        let returned_tokens = new_pool_state.available_reserve - old_pool_state.available_reserve
        expect returned_tokens > 0

        let withdrawn_usd = withdrawn_ada * ada_price
        let old_tvl_usd = old_ada * ada_price

        // Standard AMM NAV Refund Formula:
        // (Withdrawn USD / Old Pool TVL) == (Returned Tokens / Total Fixed Supply)
        (withdrawn_usd * old_pool_state.total_fixed_supply) == (returned_tokens * old_tvl_usd)
      }
    }
  }
}

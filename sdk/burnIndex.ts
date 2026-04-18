import { MeshTxBuilder, type Data } from '@meshsdk/core';
import { fetchCharli3Price } from './fetchOraclePrice.js';

export async function buildBurnIndexTx(
    txBuilder: MeshTxBuilder,
    userAddress: string,
    poolAddress: string,
    withdrawnAda: string,   // How much Lovelace the user is extracting based on NAV
    burnedIndexTokens: string, // How many $INDEX tokens they are destroying
    oracleAddress: string,
    oracleAssetPolicy: string
) {
    console.log("Constructing BurnIndex Transaction...");

    // 1. Fetch the Live Oracle Data
    const { utxo: oracleUtxo } = await fetchCharli3Price(oracleAddress, oracleAssetPolicy);

    // 2. Fetch the current Pool UTXO
    // NOTE: In production, query this from the blockchain via Blockfrost.
    const oldPoolAda = "10000000000"; // 10,000 ADA currently in pool
    const oldIndexSupply = 5000n;     // 5,000 $INDEX tokens in circulation

    // 3. Define our Plutus Redeemer (The PoolAction: BurnIndex!)
    // In Aiken: PoolAction { MintIndex (0), BurnIndex (1), CompoundYield (2) }
    const burnIndexRedeemer: Data = {
        alternative: 1, 
        fields: []
    };

    // 4. Define the updated Pool Datum
    // The pool's total supply strictly decreases because tokens are being destroyed.
    const newSupply = oldIndexSupply - BigInt(burnedIndexTokens);
    const newPoolDatum: Data = {
        alternative: 0,
        fields: [newSupply]
    };

    // 5. Build the massive Hackathon-winning transaction!
    await txBuilder
        // Supply Charli3 Oracle as Read-Only Reference
        .readOnlyTxInReference(
            oracleUtxo.input.txHash,
            oracleUtxo.input.outputIndex
        )
        // Consume the Old Pool UTXO
        // .txIn(poolTxHash, poolTxIndex) 
        // .txInInlineDatumPresent()
        // .txInRedeemerValue(burnIndexRedeemer)
        
        // Output the New Pool UTXO with the withdrawn ADA REMOVED, and the new reduced Datum
        .txOut(poolAddress, [{ unit: "lovelace", quantity: (BigInt(oldPoolAda) - BigInt(withdrawnAda)).toString() }])
        .txOutInlineDatumValue(newPoolDatum)

        // Burn the user's $INDEX tokens!
        // .mintPlutusScriptV3() ...
        // Provide negative quantity to burn them.
        .mint("-".concat(burnedIndexTokens), "YOUR_INDEX_POLICY_ID", "")
        
        // Return the extracted $ADA collateral straight into the user's wallet!
        .txOut(userAddress, [{ unit: "lovelace", quantity: withdrawnAda }])
        
        .changeAddress(userAddress)
        .complete();

    return txBuilder;
}

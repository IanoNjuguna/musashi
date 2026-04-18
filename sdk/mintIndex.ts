import { MeshTxBuilder, type Asset, type Data } from '@meshsdk/core';
import { fetchCharli3Price } from './fetchOraclePrice.js';

// You can store your API key in a .env file later!
// import dotenv from 'dotenv';
// dotenv.config();

export async function buildMintIndexTx(
    txBuilder: MeshTxBuilder,
    userAddress: string,
    poolAddress: string,
    depositedAda: string,   // How much Lovelace the user is depositing
    mintedIndexTokens: string, // How many $INDEX tokens the frontend math calculated
    oracleAddress: string,
    oracleAssetPolicy: string
) {
    console.log("Constructing MintIndex Transaction...");

    // 1. Fetch the Live Oracle Data
    const { utxo: oracleUtxo } = await fetchCharli3Price(oracleAddress, oracleAssetPolicy);

    // 2. Fetch the current Pool UTXO (The giant bucket)
    // NOTE: In reality, we'd query Blockfrost for the pool UTXO using `poolAddress`
    // For this mock, we assume we fetched it and it has old data:
    const oldPoolAda = "10000000000"; // 10,000 ADA currently in pool
    const oldIndexSupply = 5000n;     // 5,000 $INDEX tokens in circulation

    // 3. Define our Plutus Redeemer (The PoolAction: MintIndex!)
    // In Aiken, PoolAction { MintIndex, BurnIndex, CompoundYield }
    // MintIndex is the 0th constructor.
    const mintIndexRedeemer: Data = {
        alternative: 0,
        fields: []
    };

    // 4. Define the updated Pool Datum
    // The pool's total supply of $INDEX tokens increases by the amount we are minting!
    const newSupply = oldIndexSupply + BigInt(mintedIndexTokens);
    const newPoolDatum: Data = {
        alternative: 0,
        fields: [newSupply]
    };

    // 5. Build the massive Hackathon-winning transaction!
    await txBuilder
        // Supply the Charli3 Oracle as a Read-Only Reference
        .readOnlyTxInReference(
            oracleUtxo.input.txHash,
            oracleUtxo.input.outputIndex
        )
        // Consume the Old Pool UTXO
        // .txIn(poolTxHash, poolTxIndex) 
        // .txInInlineDatumPresent()
        // .txInRedeemerValue(mintIndexRedeemer)
        
        // Output the New Pool UTXO with the deposited ADA ADDED, and the new Datum
        .txOut(poolAddress, [{ unit: "lovelace", quantity: (BigInt(oldPoolAda) + BigInt(depositedAda)).toString() }])
        .txOutInlineDatumValue(newPoolDatum)

        // Mint the new $INDEX tokens directly into the user's wallet!
        // .mintPlutusScriptV3() ...
        .txOut(userAddress, [{ unit: "YOUR_INDEX_POLICY_ID", quantity: mintedIndexTokens }])
        
        .changeAddress(userAddress)
        .complete();

    return txBuilder;
}

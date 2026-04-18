import { BlockfrostProvider, type UTxO } from '@meshsdk/core';
import * as dotenv from 'dotenv';

// Load environment variables from .env
dotenv.config();

const apiKey = process.env.BLOCKFROST_API_KEY;
if (!apiKey) {
    throw new Error("BLOCKFROST_API_KEY is missing from your .env file!");
}

// Set up the connection to the Cardano Blockchain (Preview Testnet)
const blockfrost = new BlockfrostProvider(apiKey);

/**
 * Phase 3 Task 1: Locating the Live Charli3 Data Feed!
 * This function scans the blockchain to find the specific UTXO holding the official Charli3 Oracle Token.
 */
export async function fetchCharli3Price(oracleAddress: string, oracleAssetPolicy: string): Promise<{ utxo: UTxO, inlineDatumCbor: string | undefined }> {
    console.log("Scanning blockchain for Charli3 oracle data...");

    // 1. Fetch all UTXOs sitting at the Charli3 Oracle Contract Address
    const utxos = await blockfrost.fetchAddressUTxOs(oracleAddress);

    // 2. Filter through them to find the exact UTXO holding the official Charli3 Token (Asset Policy)
    const oracleUtxo = utxos.find(utxo => 
        utxo.output.amount.some(asset => asset.unit.startsWith(oracleAssetPolicy))
    );

    if (!oracleUtxo) {
        throw new Error("Oracle UTXO not found! The feed might be temporarily down or the address is incorrect.");
    }

    // 3. Extract the Inline Datum (This contains the Plutus v3 data we parsed in Phase 1!)
    // When we build the transaction to mint $INDEX, we must pass this exact UTXO as a 'reference_input'.
    const datum = oracleUtxo.output.plutusData;
    
    console.log("Live Oracle Datum successfully acquired:", datum);
    
    // The datum is returned as a CBOR hex string. 
    // MeshJS can pass this directly into our Aiken Smart Contract!
    return {
        utxo: oracleUtxo,
        inlineDatumCbor: datum
    };
}

import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can register doctors only as contract owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const doctor = accounts.get('wallet_1')!;
    const nonOwner = accounts.get('wallet_2')!;

    let block = chain.mineBlock([
      Tx.contractCall('chain-clinic', 'register-doctor', 
        [types.principal(doctor.address)], deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    block = chain.mineBlock([
      Tx.contractCall('chain-clinic', 'register-doctor',
        [types.principal(doctor.address)], nonOwner.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

Clarinet.test({
  name: "Patients can grant and revoke access to doctors",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const patient = accounts.get('wallet_1')!;
    const doctor = accounts.get('wallet_2')!;

    // Register doctor first
    chain.mineBlock([
      Tx.contractCall('chain-clinic', 'register-doctor',
        [types.principal(doctor.address)], accounts.get('deployer')!.address)
    ]);

    // Grant access
    let block = chain.mineBlock([
      Tx.contractCall('chain-clinic', 'grant-access',
        [types.principal(doctor.address)], patient.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Revoke access
    block = chain.mineBlock([
      Tx.contractCall('chain-clinic', 'revoke-access',
        [types.principal(doctor.address)], patient.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Only authorized doctors can add and view records",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const patient = accounts.get('wallet_1')!;
    const doctor = accounts.get('wallet_2')!;
    const unauthorized = accounts.get('wallet_3')!;

    // Setup: Register doctor and grant access
    chain.mineBlock([
      Tx.contractCall('chain-clinic', 'register-doctor',
        [types.principal(doctor.address)], deployer.address),
      Tx.contractCall('chain-clinic', 'grant-access',
        [types.principal(doctor.address)], patient.address)
    ]);

    // Test adding record
    let block = chain.mineBlock([
      Tx.contractCall('chain-clinic', 'add-record',
        [types.ascii("hash123"), 
         types.principal(patient.address),
         types.ascii("test data")], 
        doctor.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);

    // Test unauthorized access
    block = chain.mineBlock([
      Tx.contractCall('chain-clinic', 'get-records',
        [types.principal(patient.address)],
        unauthorized.address)
    ]);
    block.receipts[0].result.expectErr().expectUint(100);
  }
});

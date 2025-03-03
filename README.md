# ChainClinic
A decentralized medical records platform built on Stacks blockchain using Clarity smart contracts.

## Features
- Store and manage medical records on-chain 
- Role-based access control (patients, doctors, hospitals)
- Records encryption and secure sharing
- Audit trail of record access
- Patient consent management

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Add a new medical record (doctor only)
(contract-call? .chain-clinic add-record 
  "QmHash123" 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  "Encrypted Record Data")

;; Grant access to a doctor
(contract-call? .chain-clinic grant-access
  'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; View patient records (authorized only)
(contract-call? .chain-clinic get-records
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment

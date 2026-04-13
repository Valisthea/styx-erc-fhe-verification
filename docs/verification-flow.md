# FHE Computation Verification Flow

## End-to-End Flow

```
1. Circuit Registration
   Developer → registerCircuit(circuitHash, keccak256(verificationKey), gateCount, schemeId)
             → CircuitRegistered emitted

2. Encrypted Computation
   User → calls encrypted contract function
        → FHE co-processor picks up encrypted inputs
        → executes circuit off-chain (GPU/FPGA/ASIC)
        → generates IVC proof (Nova / Halo2 / SuperNova)

3. Proof Submission
   Co-processor → submitProof(circuitHash, inputCommitment, resultCommitment, verificationKey, proof)
   Contract checks:
     a. keccak256(verificationKey) == stored verificationKeyHash
     b. |proof.timestamp - block.timestamp| <= maxTimestampDrift()
     c. proof.proverAddress == msg.sender
     d. IVC proof valid against verificationKey
   executionId = keccak256(circuitHash || inputCommitment || resultCommitment || msg.sender || block.number)
   → ExecutionVerified(executionId, circuitHash, prover, resultCommitment)

4. Result Consumption
   DependentContract.isResultVerified(executionId) → true
   DependentContract.verifyResultProvenance(executionId, circuitHash, inputCommitment, resultCommitment)

5. Optional: Dispute
   Challenger → disputeResult(executionId, counterProof)
   If upheld → isDisputed(executionId) = true
             → slashProver(prover, executionId, challenger)
             → ChallengerRewarded(challenger, reward, executionId)
```

## Circuit Upgrade Flow

```
Original: circuitHash → verificationKeyHash_v0
Upgrade:  registerCircuitUpgrade(circuitHash, keccak256(newVerificationKey))
          → CircuitUpgraded(circuitHash, 0, 1, newKeyHash)
          → latestCircuitVersion(circuitHash) == 1
          → Historical proofs (v0) remain verifiable
          → New proofs use v1 key
```

## Deactivation with Grace Period

```
deactivateCircuit(circuitHash, gracePeriod=86400)
→ CircuitDeactivating(circuitHash, caller, block.timestamp + 86400)
→ isCircuitActive(circuitHash) = true (still active during grace period)
→ After 24 hours: isCircuitActive returns false
→ New submitProof calls revert with CircuitNotActive
→ Historical results remain valid forever
```

## Chained Computation

```
Step 1: submitProof(circuitA, input1, result1, ...) → executionId_A
Step 2: submitProof(circuitB, result1, result2, ...) → executionId_B
        (result1 from step 1 is the input to step 2)

Verify: isChainedExecution(executionId_A, executionId_B) → true
        verifyExecutionChain([executionId_A, executionId_B]) → true
```

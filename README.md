# ERC-8229: FHE Computation Verification

**Canonical proposal:** [ethereum/ERCs#1682](https://github.com/ethereum/ERCs/pull/1682) · **Discussion:** [Ethereum Magicians](https://ethereum-magicians.org/t/erc-8229-fhe-computation-verification/28217)

The authoritative text is the one in the pull request; this repository is a working mirror.

> On-chain verification of FHE computation correctness via recursive zero-knowledge proofs.

**Status:** Draft · **Author:** [@Valisthea](https://github.com/Valisthea) · **Created:** 2026-04-17 · **Requires:** ERC-165

---

## Abstract

FHE lets smart contracts compute on encrypted data. But FHE alone is not enough — you need **verification**. Without it, the off-chain co-processor executing the computation could return arbitrary results. The user can't check (data is encrypted). The contract can't check (never sees plaintext).

This standard defines how FHE circuits are registered, how recursive IVC proofs of correct execution are submitted and verified on-chain, and how dependent contracts consume verified results. One compact proof (≤ 1 KB) attests to arbitrarily complex encrypted computations.

**This is the trust layer that makes blind computation trustless.**

## Key Innovations (OMEGA Fixes Applied)

| Fix | Change |
|---|---|
| M-01 | `registerCircuit` stores `keccak256(verificationKey)` — not the full key (saves 99% storage cost) |
| M-01 | `submitProof` takes full `verificationKey` in calldata and verifies hash on-chain |
| M-02 | `executionId` computed on-chain (`keccak256(circuit\|\|input\|\|result\|\|sender\|\|block)`) — no caller manipulation |
| M-03 | `disputeResult(executionId, counterProof)` — challenge mechanism with `isDisputed()` |
| M-03 | Challenger reward in `slashProver` (`challengerRewardBps`) |
| M-04 | `proofSystemId() bytes4` instead of `proofSystem() string` (gas-efficient comparison) |
| M-05 | `proverAddress` in public inputs — binds proof to prover identity |
| M-06 | `registerCircuitUpgrade()` + `latestCircuitVersion()` + `CircuitUpgraded` event |
| M-07 | `deactivateCircuit(circuitHash, gracePeriod)` — protects in-flight computations |
| M-08 | Freshness check: `\|proof.timestamp - block.timestamp\| <= maxTimestampDrift()` |

## Core Interface

```solidity
interface IERC8229 {
    // Circuit management
    function registerCircuit(bytes32 circuitHash, bytes32 verificationKeyHash, uint256 gateCount, bytes4 schemeId) external;
    function registerCircuitUpgrade(bytes32 circuitHash, bytes32 newVerificationKeyHash) external;
    function deactivateCircuit(bytes32 circuitHash, uint256 gracePeriod) external;

    // Proof submission (executionId computed on-chain)
    function submitProof(bytes32 circuitHash, bytes32 inputCommitment, bytes32 resultCommitment, bytes calldata verificationKey, bytes calldata proof) external returns (bytes32 executionId);
    function submitProofBatch(...) external returns (bytes32[] memory executionIds);

    // Dispute
    function disputeResult(bytes32 executionId, bytes calldata counterProof) external;

    // Queries
    function isResultVerified(bytes32 executionId) external view returns (bool);
    function isDisputed(bytes32 executionId) external view returns (bool);
    function verifyResultProvenance(bytes32 executionId, bytes32 circuitHash, bytes32 inputCommitment, bytes32 resultCommitment) external view returns (bool);

    // Config
    function proofSystemId() external view returns (bytes4);
    function maxTimestampDrift() external view returns (uint256);
}
```

## Repository Structure

```
styx-erc-fhe-verification/
├── eip/
│   └── eip-zzzz.md                        # Official EIP draft
├── contracts/
│   └── interfaces/
│       ├── IERC8229.sol                   # Core interface (all OMEGA fixes)
│       ├── IERC8229_ProverRegistry.sol    # Prover staking, slashing + challenger reward
│       └── IERC8229_Chaining.sol          # Multi-step computation pipeline verification
├── docs/
│   └── verification-flow.md
├── test/
│   └── .gitkeep
└── SECURITY.md
```

## STYX Protocol Layer Stack

| Layer | Codename | ERC |
|---|---|---|
| L1 | Veil | [ERC-1680](https://github.com/Valisthea/styx-erc-encrypted-token) — Encrypted Token Interface |
| L2 | Prism | **This standard** — FHE Computation Verification |
| L3 | Oblivion | [ERC-1681](https://github.com/Valisthea/styx-erc-cryptographic-amnesia) — Cryptographic Amnesia Interface |

## License

[CC0-1.0](./LICENSE) · Valisthea · Kairos Lab

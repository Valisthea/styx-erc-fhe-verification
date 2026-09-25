// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

/// @title ERC-8229 FHE Computation Verification Interface
/// @author Valisthea (@Valisthea)
/// @notice Interface for on-chain verification of FHE computation correctness
///         via recursive zero-knowledge proofs (IVC).

interface IERC8229 {

    // ─── Types ───────────────────────────────────────

    struct CircuitInfo {
        bytes32 circuitHash;          // Unique identifier (hash of circuit structure)
        bytes32 verificationKeyHash;  // Keccak256 hash of the verification key (fix OMEGA M-01)
        address registrant;           // Who registered this circuit
        uint256 gateCount;            // Total FHE gates in the circuit
        uint256 registeredAt;         // Block timestamp of registration
        uint256 currentVersion;       // Latest circuit version (incremented on upgrade)
        bool active;                  // Whether the circuit accepts new proofs
        bytes4 schemeId;              // FHE scheme identifier (bytes4, not string)
    }

    struct ExecutionResult {
        bytes32 executionId;          // Unique execution identifier (computed on-chain)
        bytes32 circuitHash;          // Which circuit was executed
        bytes32 inputCommitment;      // Poseidon commitment to encrypted inputs
        bytes32 resultCommitment;     // Poseidon commitment to encrypted outputs
        bytes32 proofHash;            // Keccak256 of the submitted proof
        address prover;               // Co-processor that submitted the proof
        uint256 verifiedAt;           // Block timestamp of verification
        bool verified;                // Whether the proof was accepted
        bool disputed;                // Whether the result has been disputed
    }

    // ─── Custom Errors ───────────────────────────────

    error CircuitAlreadyRegistered(bytes32 circuitHash);
    error CircuitNotRegistered(bytes32 circuitHash);
    error CircuitNotActive(bytes32 circuitHash);
    error ProofVerificationFailed(bytes32 executionId, bytes32 circuitHash);
    error ExecutionAlreadySubmitted(bytes32 executionId);
    error VerificationKeyHashMismatch(bytes32 circuitHash, bytes32 provided, bytes32 stored);
    error InvalidInputCommitment(bytes32 executionId);
    error GateCountExceedsLimit(uint256 gateCount, uint256 maxGates);
    error UnauthorizedCircuitRegistrant(address caller);
    error CircuitInGracePeriod(bytes32 circuitHash, uint256 deactivatesAt);
    error ExecutionNotVerified(bytes32 executionId);
    error ExecutionAlreadyDisputed(bytes32 executionId);

    // ─── Events ──────────────────────────────────────

    /// @notice Emitted when a new circuit is registered.
    /// @param circuitHash          Unique circuit identifier.
    /// @param registrant           Address that registered the circuit.
    /// @param gateCount            Number of FHE gates.
    /// @param verificationKeyHash  Keccak256 hash of the verification key.
    event CircuitRegistered(
        bytes32 indexed circuitHash,
        address indexed registrant,
        uint256 gateCount,
        bytes32 verificationKeyHash
    );

    /// @notice Emitted when a circuit is upgraded to a new version.
    /// @param circuitHash          Circuit that was upgraded.
    /// @param previousVersion      Previous version number.
    /// @param newVersion           New version number.
    /// @param newVerificationKeyHash  Hash of the new verification key.
    event CircuitUpgraded(
        bytes32 indexed circuitHash,
        uint256 previousVersion,
        uint256 newVersion,
        bytes32 newVerificationKeyHash
    );

    /// @notice Emitted when a circuit enters its grace period before deactivation.
    /// @param circuitHash    Circuit entering grace period.
    /// @param deactivatesAt  Timestamp at which deactivation takes effect.
    event CircuitDeactivating(
        bytes32 indexed circuitHash,
        address indexed deactivatedBy,
        uint256 deactivatesAt
    );

    /// @notice Emitted when an execution proof is submitted and verified.
    /// @param executionId       Unique execution identifier (computed on-chain).
    /// @param circuitHash       Circuit that was executed.
    /// @param prover            Co-processor that submitted the proof.
    /// @param resultCommitment  Commitment to the encrypted output.
    event ExecutionVerified(
        bytes32 indexed executionId,
        bytes32 indexed circuitHash,
        address indexed prover,
        bytes32 resultCommitment
    );

    /// @notice Emitted when a proof fails verification.
    event ExecutionRejected(
        bytes32 indexed executionId,
        bytes32 indexed circuitHash,
        address indexed prover
    );

    /// @notice Emitted when a verified result is disputed with a counter-proof.
    /// @param executionId    Disputed execution.
    /// @param challenger     Address that submitted the counter-proof.
    /// @param counterProofHash  Hash of the counter-proof.
    event ResultDisputed(
        bytes32 indexed executionId,
        address indexed challenger,
        bytes32 counterProofHash
    );

    // ─── Circuit Registry ────────────────────────────

    /// @notice Register a new FHE circuit for verification.
    /// @dev    OMEGA M-01: stores only the hash of the verification key on-chain.
    ///         This avoids storing large key bytes in contract storage.
    ///         The full verificationKey is supplied at proof-submission time
    ///         (see submitProof) and verified against this stored hash.
    ///         circuitHash MUST be Keccak256 of the circuit's canonical gate-level
    ///         representation. Only authorized registrants may call this.
    /// @param  circuitHash          Unique circuit identifier.
    /// @param  verificationKeyHash  Keccak256(verificationKey) — stored on-chain.
    /// @param  gateCount            Number of FHE gates in the circuit.
    /// @param  schemeId             FHE scheme identifier as bytes4.
    function registerCircuit(
        bytes32 circuitHash,
        bytes32 verificationKeyHash,
        uint256 gateCount,
        bytes4 schemeId
    ) external;

    /// @notice Register an upgrade to an existing circuit's verification key.
    /// @dev    Increments currentVersion and updates verificationKeyHash.
    ///         Previous version proofs remain valid (historical results are immutable).
    ///         Only the original registrant or governance may upgrade.
    ///         Emits CircuitUpgraded.
    /// @param  circuitHash             Circuit to upgrade.
    /// @param  newVerificationKeyHash  Keccak256 of the new verification key.
    function registerCircuitUpgrade(
        bytes32 circuitHash,
        bytes32 newVerificationKeyHash
    ) external;

    /// @notice Returns the latest version number for a circuit.
    /// @dev    0 if the circuit has never been upgraded (initial version = 0).
    /// @param  circuitHash  Circuit to query.
    /// @return Latest version number.
    function latestCircuitVersion(bytes32 circuitHash)
        external
        view
        returns (uint256);

    /// @notice Schedule deactivation of a circuit with a grace period.
    /// @dev    During the grace period, existing submissions are still accepted.
    ///         After the grace period elapses, the circuit is deactivated.
    ///         New proofs submitted after deactivation revert with CircuitNotActive.
    ///         Emits CircuitDeactivating. Only registrant or governance may call.
    /// @param  circuitHash  Circuit to deactivate.
    /// @param  gracePeriod  Seconds until deactivation takes effect.
    function deactivateCircuit(bytes32 circuitHash, uint256 gracePeriod) external;

    /// @notice Returns circuit information.
    function circuitInfo(bytes32 circuitHash)
        external
        view
        returns (CircuitInfo memory);

    /// @notice Returns whether a circuit is registered and currently active.
    function isCircuitActive(bytes32 circuitHash)
        external
        view
        returns (bool);

    // ─── Proof Submission & Verification ─────────────

    /// @notice Submit an execution proof for verification.
    /// @dev    OMEGA M-01: verificationKey supplied here, verified against stored hash:
    ///           require(keccak256(verificationKey) == circuitInfo.verificationKeyHash)
    ///
    ///         OMEGA M-02: executionId is computed on-chain to prevent caller manipulation:
    ///           executionId = keccak256(abi.encodePacked(
    ///             circuitHash, inputCommitment, resultCommitment, msg.sender, block.number
    ///           ))
    ///         The computed executionId is returned and emitted — callers MUST NOT pre-specify it.
    ///
    ///         OMEGA M-05: Freshness check — the timestamp in the proof's public inputs
    ///         MUST satisfy: |proof.timestamp - block.timestamp| <= maxTimestampDrift().
    ///         Stale proofs (e.g. from a previous block's context) MUST be rejected.
    ///
    ///         If proof is valid: stores ExecutionResult, emits ExecutionVerified.
    ///         If invalid: reverts with ProofVerificationFailed.
    ///
    /// @param  circuitHash       Which circuit was executed.
    /// @param  inputCommitment   Poseidon commitment to the encrypted inputs.
    /// @param  resultCommitment  Poseidon commitment to the encrypted outputs.
    /// @param  verificationKey   Full verification key — verified against stored hash.
    /// @param  proof             The IVC execution proof (Nova/Halo2/SuperNova).
    /// @return executionId       The on-chain computed unique execution identifier.
    function submitProof(
        bytes32 circuitHash,
        bytes32 inputCommitment,
        bytes32 resultCommitment,
        bytes calldata verificationKey,
        bytes calldata proof
    ) external returns (bytes32 executionId);

    /// @notice Batch-submit multiple execution proofs atomically.
    /// @dev    Each proof verified independently. Entire batch reverts on any failure.
    ///         executionIds are computed on-chain for each element and returned.
    /// @param  circuitHashes      Array of circuit hashes.
    /// @param  inputCommitments   Array of input commitments.
    /// @param  resultCommitments  Array of result commitments.
    /// @param  verificationKeys   Array of full verification keys.
    /// @param  proofs             Array of IVC proofs.
    /// @return executionIds       On-chain computed execution IDs for each element.
    function submitProofBatch(
        bytes32[] calldata circuitHashes,
        bytes32[] calldata inputCommitments,
        bytes32[] calldata resultCommitments,
        bytes[] calldata verificationKeys,
        bytes[] calldata proofs
    ) external returns (bytes32[] memory executionIds);

    /// @notice Dispute a previously verified result with a counter-proof.
    /// @dev    Allows anyone to challenge a verification result that was accepted
    ///         but is believed to be incorrect (e.g. prover generated a valid-looking
    ///         proof for an incorrect computation).
    ///         The counterProof MUST demonstrate that the resultCommitment is
    ///         inconsistent with the stated circuit and inputCommitment.
    ///         If the dispute is upheld: result is marked disputed, prover may be slashed.
    ///         Emits ResultDisputed.
    /// @param  executionId   Execution to challenge.
    /// @param  counterProof  ZK proof demonstrating result incorrectness.
    function disputeResult(bytes32 executionId, bytes calldata counterProof) external;

    // ─── Result Queries ──────────────────────────────

    /// @notice Returns whether a specific execution has been verified.
    function isResultVerified(bytes32 executionId)
        external
        view
        returns (bool);

    /// @notice Returns whether a specific execution is under dispute.
    function isDisputed(bytes32 executionId)
        external
        view
        returns (bool);

    /// @notice Returns the full execution result metadata.
    function executionResult(bytes32 executionId)
        external
        view
        returns (ExecutionResult memory);

    /// @notice Returns the result commitment for a verified execution.
    /// @dev    Reverts with ExecutionNotVerified if the execution is not verified.
    function verifiedResultCommitment(bytes32 executionId)
        external
        view
        returns (bytes32);

    /// @notice Verify full provenance: circuit, inputs, and result all match.
    function verifyResultProvenance(
        bytes32 executionId,
        bytes32 circuitHash,
        bytes32 inputCommitment,
        bytes32 resultCommitment
    ) external view returns (bool);

    // ─── Configuration ───────────────────────────────

    /// @notice Maximum gate count allowed per circuit.
    function maxGateCount() external view returns (uint256);

    /// @notice Maximum proof size in bytes.
    function maxProofSize() external view returns (uint256);

    /// @notice Maximum allowed drift between proof timestamp and block.timestamp.
    /// @dev    Used for freshness check in submitProof.
    ///         RECOMMENDED: 300 seconds (5 minutes).
    function maxTimestampDrift() external view returns (uint256);

    /// @notice Returns the supported proof system identifier as bytes4.
    /// @dev    OMEGA M-04: bytes4 instead of string for gas efficiency and
    ///         comparability. Well-known values:
    ///           0x4e6f7661 = "Nova"
    ///           0x48616c32 = "Hal2" (Halo2)
    ///           0x534e6f76 = "SNov" (SuperNova)
    function proofSystemId() external view returns (bytes4);
}

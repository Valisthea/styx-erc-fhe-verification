// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

import "./IERCZZZZ.sol";

/// @title ERC-ZZZZ Prover Registry Extension
/// @author Valisthea (@Valisthea)
/// @notice Tracks co-processor reputation, stake, and slashing.
///         For networks with multiple competing co-processors.
interface IERCZZZZ_ProverRegistry is IERCZZZZ {

    struct ProverInfo {
        address prover;
        uint256 stake;               // Slashable stake in wei
        uint256 totalExecutions;     // Lifetime verified executions
        uint256 failedExecutions;    // Lifetime rejected proofs
        uint256 registeredAt;        // Registration timestamp
        bool active;                 // Whether the prover is currently active
    }

    // ─── Events ──────────────────────────────────────

    /// @notice Emitted when a prover registers with stake.
    event ProverRegistered(address indexed prover, uint256 stake);

    /// @notice Emitted when a prover is slashed for a disputed/invalid proof.
    /// @param prover       The slashed co-processor.
    /// @param amount       Amount slashed in wei.
    /// @param executionId  Execution that triggered the slash.
    /// @param challenger   Address that triggered the slash (receives reward).
    event ProverSlashed(
        address indexed prover,
        uint256 amount,
        bytes32 indexed executionId,
        address indexed challenger
    );

    /// @notice Emitted when a challenger receives their slash reward.
    /// @param challenger   Address that successfully challenged.
    /// @param reward       Reward amount in wei.
    /// @param executionId  Execution that was successfully disputed.
    event ChallengerRewarded(
        address indexed challenger,
        uint256 reward,
        bytes32 indexed executionId
    );

    // ─── Functions ───────────────────────────────────

    /// @notice Register as a co-processor by staking collateral.
    /// @dev    Requires msg.value >= minProverStake().
    ///         Staked ETH is slashable if a proof is successfully disputed.
    function registerProver() external payable;

    /// @notice Returns prover information.
    function proverInfo(address prover)
        external view returns (ProverInfo memory);

    /// @notice Returns whether an address is a registered active prover.
    function isProverActive(address prover)
        external view returns (bool);

    /// @notice Slash a prover for a successfully disputed proof.
    /// @dev    OMEGA M-03: challenger receives a portion of the slash as reward.
    ///         Reward = slashAmount * challengerRewardBps / 10000.
    ///         Remaining slash is sent to a protocol treasury or burned.
    ///         Only callable by governance or the dispute resolution contract
    ///         after a successful disputeResult() call.
    ///         Emits ProverSlashed and ChallengerRewarded.
    /// @param  prover       Co-processor to slash.
    /// @param  executionId  Execution that was disputed.
    /// @param  challenger   Address that submitted the successful counter-proof.
    function slashProver(
        address prover,
        bytes32 executionId,
        address challenger
    ) external;

    /// @notice Basis points of slashed amount paid to the successful challenger.
    /// @dev    RECOMMENDED: 1000 bps = 10%.
    function challengerRewardBps() external view returns (uint256);

    /// @notice Minimum stake required to register as a prover.
    function minProverStake() external view returns (uint256);
}

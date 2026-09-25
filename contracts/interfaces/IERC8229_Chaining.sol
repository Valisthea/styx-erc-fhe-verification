// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

import "./IERC8229.sol";

/// @title ERC-8229 Computation Chaining Extension
/// @author Valisthea (@Valisthea)
/// @notice Enables verified composition of encrypted computations.
///         For multi-step FHE pipelines where the output of one computation
///         is the input of the next.
interface IERC8229_Chaining is IERC8229 {

    /// @notice Emitted when a chained execution is verified.
    event ChainVerified(
        bytes32[] executionChain,
        bytes32 finalResultCommitment
    );

    /// @notice Verify that execution B consumed the verified output of execution A.
    /// @dev    Checks that B's inputCommitment == A's resultCommitment.
    ///         Both executions MUST be independently verified.
    ///         Returns false (not revert) if either execution is unverified.
    /// @param  executionA  The upstream execution (source of output).
    /// @param  executionB  The downstream execution (consumer of input).
    /// @return True if B's input is provably A's verified output.
    function isChainedExecution(
        bytes32 executionA,
        bytes32 executionB
    ) external view returns (bool);

    /// @notice Verify an ordered chain of executions end-to-end.
    /// @dev    For each consecutive pair (i, i+1) in executionChain:
    ///           executionChain[i].resultCommitment == executionChain[i+1].inputCommitment
    ///         All executions MUST be verified and none disputed.
    ///         Emits ChainVerified on success.
    /// @param  executionChain  Ordered array of execution IDs (length >= 2).
    /// @return True if the entire chain is valid and all executions verified.
    function verifyExecutionChain(bytes32[] calldata executionChain)
        external view returns (bool);
}

# Security Policy

## Scope

Security reports are welcome for:

- **Verification bypass** — invalid proof accepted, executionId collision
- **Verification key substitution** — hash mismatch not caught
- **executionId manipulation** — on-chain computation flawed
- **Freshness check bypass** — stale proofs accepted
- **Prover binding bypass** — proof re-used by different sender
- **Dispute mechanism flaws** — challenge incorrectly upheld or blocked
- **Grace period bypass** — circuit deactivated before grace period ends
- **Challenger reward manipulation** — reward calculation exploited

## Reporting

**Do NOT open a public GitHub issue for security vulnerabilities.**

**Email:** security@kairoslab.xyz

Include: description, affected component, proof of concept, suggested mitigation.

## Response

| Stage | Timeline |
|---|---|
| Acknowledgement | 48 hours |
| Initial assessment | 5 business days |
| Coordinated disclosure | After fix |

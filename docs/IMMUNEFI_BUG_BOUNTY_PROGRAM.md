# Immunefi Bug Bounty Program Setup (P4-DL-006)

This document defines the launch-ready bug bounty program plan for Immunefi.

## Status
- [x] Immunefi program setup checklist drafted
- [x] Bounty tiers defined
- [x] Scope documented
- [x] Rules established
- [x] Initial funding recommendation documented

## 1) Program Creation Checklist

1. Create project account on Immunefi under protocol owner account.
2. Complete project profile:
   - Project name: DeFi Yield Aggregator
   - Website + docs + repository links
   - Primary security contact email
3. Configure submission workflow:
   - SLA target for first response: 24 hours
   - Triage target: 3 business days
   - Resolution target: severity-based
4. Add payout wallet/multisig for bounty disbursement.

## 2) Bounty Tiers

| Severity | Reward |
|----------|--------|
| Critical | $50,000 |
| High | $10,000 |
| Medium | $2,500 |
| Low | $500 |

### Severity Guidance
- **Critical**: direct loss of funds, unauthorized mint/drain, permanent lock of significant TVL.
- **High**: major protocol compromise without immediate full drain.
- **Medium**: meaningful security impact with constrained blast radius.
- **Low**: limited-impact security issues and hardening findings.

## 3) Scope

### In Scope
- Smart contracts under `contracts/`
- Deployment and protocol scripts under `scripts/`
- Frontend security-sensitive flows under `frontend/src/` (auth/wallet/signature/payout paths)

### Out of Scope
- Third-party dependencies unless exploited through protocol-specific misuse
- Issues requiring compromised private keys or admin devices
- Social engineering, phishing, and physical attacks
- Best-practice suggestions without exploit path

## 4) Rules

1. No testing on mainnet production contracts without explicit approval.
2. Use testnets/local forks for proof of concept.
3. Do not access or exfiltrate user private data.
4. Do not perform denial-of-service against production infrastructure.
5. Provide reproducible steps and impact statement in every report.
6. Follow coordinated disclosure until fix is deployed.

## 5) Initial Funding Recommendation

Recommended initial pool: **$100,000**

Rationale:
- Covers at least two critical findings or a mixed distribution of high/medium severity reports.
- Demonstrates strong commitment to external security research.
- Can be topped up after first program performance review.

## 6) Submission Template Requirements

Each report should include:
- Summary
- Affected component
- Severity claim and reasoning
- Reproduction steps / PoC
- Impact analysis
- Suggested remediation

## 7) Launch Readiness Checklist

- [ ] Immunefi profile published
- [ ] Scope reviewed by engineering and legal
- [ ] Multisig bounty wallet funded
- [ ] Internal triage owner assigned
- [ ] Incident response runbook linked
- [ ] Public announcement drafted

---
Owner: Security / Protocol Team
Issue reference: #54

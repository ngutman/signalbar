# Security Policy

SignalBar is an early open-source macOS utility and does not currently have a formal security program or bounty.

## Reporting a vulnerability

Once the repository is public, please prefer GitHub private vulnerability reporting if it is enabled for the repo.

If private reporting is not available yet, do **not** open a public issue for sensitive vulnerabilities that could put users at risk.

## Scope notes

SignalBar is designed to avoid especially sensitive behaviors:
- no packet capture
- no root privileges
- no background daemons
- no telemetry collection
- only lightweight network probes against configured targets

Current sensitive areas to review carefully:
- release/signing scripts
- watched-target persistence
- any future packaging, update, or auto-start behavior
- any future permissions or credential handling

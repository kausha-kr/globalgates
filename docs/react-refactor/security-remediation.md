# Tracked Secret Remediation

## Discovery

The baseline repository tracked the following sensitive configuration:

- A PEM private key and its certificate
- OAuth client IDs and client secrets for four providers
- Database, mail, JWT, AWS, messaging, map, and payment credentials

The private key and configuration were also present in earlier commits. Removing
them from the current tree does not invalidate or erase those historical values.

## Current-branch remediation

- Removed the tracked PEM files.
- Disabled TLS by default for local development.
- Changed TLS certificate paths to external file paths.
- Replaced embedded credentials with environment-variable references.
- Removed a hard-coded Google Maps key and expired S3 signed URLs from frontend files.
- Stopped the settings controller and shared logging aspect from serializing member objects.
- Added `.env.example` with variable names and non-secret placeholders.
- Kept actual local environment files and PEM files excluded from Git.

## Required owner action

Every credential that appeared in Git history must be treated as compromised.
Rotate or revoke the original values at each provider before making the project
public. TLS private keys must be replaced with a newly generated key pair.

Rotation inventory: database, mail, JWT, AWS, messaging, Google Maps, Bootpay,
Kakao, Naver, Facebook, Google OAuth, and the TLS certificate/private key pair.
Provider-side rotation cannot be completed from this repository and must be
confirmed in each account console.

## History policy

The public portfolio branches are rebuilt from the verified current tree so
the commits containing credentials are no longer reachable from GitHub branch
or tag references. The original history is retained only in a local bundle for
recovery and must never be published. Provider-side credential rotation is
still required because removing Git history cannot invalidate copied values.

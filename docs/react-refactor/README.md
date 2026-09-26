# GlobalGates React Refactor

This directory records the evidence used for the React portfolio refactor.

## Safety baseline

- Base branch: `master`
- Work branch: `codex/react-refactor`
- Base commit: `a607537bd2cc7a8339320852229d07c162cfb319`
- Recovery tag: `backup/pre-react-20260924`
- The original worktree and its untracked files are not modified.

## Migration targets

The estimation list is the first React migration slice. Its REST API is already
separated from the Thymeleaf page, while rendering, filtering, modal state, and
status updates are currently coordinated through imperative DOM code.

The second slice is estimation registration. Expert search, product loading,
form validation, AI review, and submission are now explicit React states. See
`estimation-register-case.md` for the decisions and browser evidence.

The API boundary is covered separately in `estimation-api-contract-case.md`.
It records authenticated requester enforcement, unauthenticated request
rejection, and the restored test compilation baseline.

## Evidence set

Each portfolio case uses the same five-part evidence set:

1. `01-before`: original screen
2. `02-error`: reproduced error or usability problem
3. `03-code`: relevant implementation change
4. `04-after`: improved screen
5. `05-test`: test or build result

Screenshots are stored under `docs/react-refactor/evidence/<case-id>/` and are
linked from the matching case document.

## Commit policy

- One behavioral change per commit.
- Tests and documentation ship with the related change.
- Existing behavior remains available until the React replacement is verified.
- Revert with `git revert <commit>`; do not rewrite shared history.

## Security gate

The baseline repository tracked OAuth configuration and PEM key files. The
current React branch removes tracked keys and uses environment-based
configuration. See `security-remediation.md`. Historical credentials still
require rotation before the repository can be made public.

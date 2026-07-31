---
name: ship-it
description: "Push or deploy an already-verified change and confirm its externally observable state. Use only when explicitly invoked as $ship-it."
---

# Ship It

Move a verified change to an explicitly authorized external destination, then distinguish source publication from deployment.

## Authorization gate

Do not push, open or merge a pull request, deploy, redeploy, or change production state unless the user's current request explicitly authorizes that external action.

Before acting, resolve:

1. the repository and remote;
2. the source branch and destination branch;
3. whether the user authorizes a push, a deployment, or both;
4. the target environment: preview, staging, or production.

Invoking this skill without naming the external action or environment is not production authorization. Ask one specific question when the missing choice changes the destination or blast radius. Never fall back to production because preview or staging is unavailable.

## Preflight

- Confirm the working directory, Git root, branch, dirty state, remote, and applicable repository instructions.
- Preserve unrelated changes.
- Run the repository's required tests, type checks, builds, and secret scan.
- Stop on a red gate. Report the command and failure; do not push through it.
- Confirm the commit being shipped and the exact diff it contains.

## Publish source safely

- Push only the authorized feature branch.
- Never push directly to a protected default branch.
- Follow the repository's pull-request and review policy.
- Never force-push or rewrite shared history without separate explicit authority.
- Record the pushed commit identifier and remote branch.

A successful push means only that source reached the remote. It does not prove that a deployment started or completed.

## Deploy only when authorized

Use the deployment mechanism already configured by the project. Do not introduce a provider, create infrastructure, or switch environments as a fallback.

- If push-to-deploy is configured, identify the deployment associated with the pushed commit.
- If an explicit deploy command is required, run it only for the authorized environment.
- If the project exposes no configured deployment path, stop and report the missing mechanism.

## Verify the external state

Use the configured provider's API, CLI, dashboard connector, or health endpoint to verify:

1. the deployment references the expected commit;
2. the terminal state is successful;
3. the returned URL belongs to the authorized environment;
4. the URL responds as expected, when a safe read-only check is available.

Do not report "live" from a push result, a queued build, or a locally successful build. If deployment fails, return the actual terminal state and relevant log excerpt without exposing secrets.

## Return

Report:

- what external action was authorized and performed;
- branch and commit;
- push status;
- deployment environment and terminal status, if deployment was authorized;
- verified URL, if one exists;
- any check that could not be performed.

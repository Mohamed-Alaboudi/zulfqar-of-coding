---
name: collaborator-handoff
description: Create a self-contained setup and access handoff for a human teammate. Use only when explicitly requested for collaborator onboarding.
---

# Collaborator handoff

Apply this skill only for an explicit request to onboard a human teammate, contractor, or intern to a repository. It is not a continuation handoff for another agent session and not a repository-hygiene task.

Produce one standalone Markdown onboarding document, either at a user-approved location or inline if requested. It must let a teammate clone, configure, run, validate, and deploy the project without prior context.

First inspect the repository to determine its remote, default branch, package manager, required environment-variable names, development command, validation commands, and deployment model. Do not guess commands or infrastructure. Mark genuinely unknown organization-specific details as clear TODOs.

Include two sections:

1. A setup runbook covering clone, dependency installation, configuration, local run, validation, and deployment using the repository's actual commands.
2. An access checklist covering repository membership, least-privilege service access, and the deployment authorization requirements that affect a teammate's first change.

Never include secret or token values. Name required values and identify the approved secret-distribution process. Prefer narrowly scoped, individually issued access, do not perform invitations or grants without explicit authorization, and advise a harmless first change to verify access and deployment.

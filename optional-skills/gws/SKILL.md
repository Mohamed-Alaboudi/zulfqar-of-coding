---
name: gws
description: Use a gws CLI found on PATH for Google Workspace reads and explicitly approved writes. Use for Gmail, Calendar, Drive, Sheets, Docs, Tasks, Contacts, Chat, Meet, Forms, or Keep; not for analytics, cloud infrastructure, or unrelated services.
---

# Google Workspace CLI

Translate a Google Workspace request into the narrowest supported `gws` call. Run reads when the
request authorizes access; preview every external write and wait for explicit approval.

## Establish the boundary

1. Resolve the CLI with `command -v gws`. If unavailable, stop and give platform-neutral
   installation guidance from the tool's official documentation.
2. Use only authentication already configured by the caller. Never inspect, print, copy, or modify
   token files. If authentication or a required scope is missing, report the missing access and give
   the caller the relevant `gws auth` command to run themselves.
3. Inspect `gws schema <service.resource.method>` when a method or parameter is uncertain. Do not
   guess an API shape.

## Classify before executing

- Treat list, get, search, and other read-only methods as reads. Run them without an additional
  confirmation when they are within the user's request.
- Treat send, create, insert, update, patch, delete, trash, move, sharing, permission, membership,
  and any POST, PUT, PATCH, or DELETE operation as an external write.
- When classification is uncertain, treat the operation as a write.

For each write, show:

- the service and action;
- the human-readable target;
- the important payload fields;
- whether it is reversible; and
- the exact `gws` command or an equivalent concise command summary.

Then stop and wait for an explicit approval of that preview. A general request to use Google
Workspace is not approval for an unpreviewed write. If the command changes after approval, preview
it again. Do not silently combine a write with a read sequence or broaden an approval to later
writes.

## Execute narrowly

Prefer the smallest response fields, result limits, and date range that answer the request. Use
pagination only when the complete result set is necessary. Avoid exposing unrelated personal data
in command output or the final answer.

After an approved write, report the result and, when a safe read is available, read back the changed
resource. Never perform a permanent or bulk delete without a target-by-target preview and explicit
approval. Never grant external access unless the user clearly requested the exact recipient and
permission level.

## Handle failures

- On an authentication or insufficient-scope error, do not retry in a loop. State which service
  needs access and leave the authentication step to the caller.
- On a schema or validation error, inspect the method schema and correct only the rejected fields.
- On a partial batch failure, stop before retrying writes, list confirmed successes and failures,
  and request approval for any retry.

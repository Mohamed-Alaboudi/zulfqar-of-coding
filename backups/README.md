# Backup policy

Backups are local recovery artifacts and must not be published. Keep dated snapshots outside the repository or in an ignored `backups/local/` directory.

Safe backup metadata may record:

- creation time;
- tool and version;
- source revision;
- restore instructions;
- a content hash that cannot reveal the content.

Never include active configuration, auth stores, `.env` files, tokens, cookies, session history, project memory, transcripts, personal data, plugin caches, marketplace clones, binaries, or raw skill-pack snapshots.

The repository’s `precompact-backup` hook documents a separate session-continuity mechanism. It is not authorization to publish the resulting payload.

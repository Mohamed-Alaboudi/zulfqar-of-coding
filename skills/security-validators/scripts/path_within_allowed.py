#!/usr/bin/env python3
"""Path-traversal boundary check: is a path really inside an allowed root.

Provenance: pattern reimplemented from modelcontextprotocol/servers,
src/filesystem/path-validation.ts (isPathWithinAllowedDirectories). This is
an original Python rewrite of that pattern, not a port or transliteration
of the TypeScript source. Dependency-free, stdlib only.

The bug this exists to prevent: naive containment checks compare with a
plain string prefix, e.g. `path.startswith(allowed_dir)`. That is wrong
because "/allowed-evil" also starts with the string "/allowed" without
being inside it. The fix is a separator-boundary check: after confirming
the prefix match, either the remainder is empty (exact match) or the
matched allowed dir must be immediately followed by a path separator
before the rest of the path continues.
"""

from __future__ import annotations

import os


def is_path_within_allowed(candidate: str, allowed_dirs: list[str]) -> bool:
    """Return True if `candidate` resolves to a location inside one of
    `allowed_dirs`. False on any malformed input, ambiguous input, or a
    path that escapes every allowed root. Never raises.

    Steps, in order:
      1. Type/emptiness guard.
      2. Reject embedded NUL bytes (not valid in real filesystem paths;
         some OS/library layers truncate at NUL, which is itself a
         historical path-check bypass).
      3. Normalize + resolve to an absolute, symlink-agnostic form.
      4. Require the resolved candidate to be absolute.
      5. For each allowed dir, normalize + resolve it the same way, then
         do the boundary-safe containment check described above.
    """
    if not isinstance(candidate, str) or not candidate:
        return False
    if not isinstance(allowed_dirs, list) or not allowed_dirs:
        return False
    if "\x00" in candidate:
        return False

    try:
        resolved = os.path.realpath(os.path.normpath(candidate))
    except (OSError, ValueError):
        return False
    if not os.path.isabs(resolved):
        return False

    for raw_dir in allowed_dirs:
        if not isinstance(raw_dir, str) or not raw_dir or "\x00" in raw_dir:
            continue
        try:
            allowed = os.path.realpath(os.path.normpath(raw_dir))
        except (OSError, ValueError):
            continue
        if not os.path.isabs(allowed):
            continue

        if resolved == allowed:
            return True

        # Filesystem root is a degenerate case: os.sep + os.sep would be a
        # double separator, so root gets its own check instead of the
        # general `allowed + sep` prefix below.
        if allowed == os.sep:
            if resolved.startswith(os.sep):
                return True
            continue

        # The boundary check: `allowed` must be followed by a real
        # separator, not just any character, before we call it a match.
        # This is what stops "/allowed-x" from matching allowed dir
        # "/allowed" (a bare prefix match would wrongly allow it).
        prefix = allowed + os.sep
        if resolved.startswith(prefix):
            return True

    return False


if __name__ == "__main__":
    # Inline self-tests. Exercised on every run of this file; no test
    # framework dependency by design (this file has zero imports beyond
    # stdlib os).

    # Same path as the allowed dir: allowed.
    assert is_path_within_allowed("/allowed", ["/allowed"]) is True

    # Genuine subdirectory: allowed.
    assert is_path_within_allowed("/allowed/sub/file.txt", ["/allowed"]) is True

    # The boundary-check subtlety this validator exists for: a sibling
    # directory that merely shares a string prefix must NOT match.
    assert is_path_within_allowed("/allowed-x/file.txt", ["/allowed"]) is False
    assert is_path_within_allowed("/allowed-evil", ["/allowed"]) is False

    # Classic traversal via ".." must resolve out and get rejected.
    assert is_path_within_allowed("/allowed/../etc/passwd", ["/allowed"]) is False

    # Null byte anywhere in the candidate is an automatic reject.
    assert is_path_within_allowed("/allowed/f\x00ile", ["/allowed"]) is False

    # Relative paths are never accepted even if they would resolve inside
    # (caller is expected to pass paths meant to already be absolute;
    # accepting relative input here would make the check depend on CWD).
    assert is_path_within_allowed("relative/path", ["/allowed"]) is False

    # Empty / malformed inputs degrade to False, never an exception.
    assert is_path_within_allowed("", ["/allowed"]) is False
    assert is_path_within_allowed("/allowed/file", []) is False
    assert is_path_within_allowed("/allowed/file", ["not-a-list-item-that-matters", 5]) is False  # type: ignore[list-item]

    # Root as the sole allowed dir permits any absolute path.
    assert is_path_within_allowed("/anything/at/all", ["/"]) is True

    # Multiple allowed dirs: match against any one of them.
    assert is_path_within_allowed("/b/file", ["/a", "/b"]) is True
    assert is_path_within_allowed("/c/file", ["/a", "/b"]) is False

    print("path_within_allowed.py: all self-tests passed")

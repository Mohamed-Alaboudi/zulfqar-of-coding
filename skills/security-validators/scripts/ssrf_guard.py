#!/usr/bin/env python3
"""SSRF guard for fetching agent-influenced or otherwise untrusted URLs.

Provenance: pattern reimplemented from qazbnm456/awesome-web-security,
scripts/ci/pr_review.py (the `_host_is_non_public` / `_BlockInternalRedirect`
/ `check_reachability` trio used to fetch attacker-controlled PR URLs from
inside CI). This is an original Python rewrite of that pattern, not a copy
of the source file. Dependency-free, stdlib only.

Threat model: a URL is untrusted the moment any part of it (path, host, or
the whole string) can be influenced by an LLM, a PR body, a web page, or
any other agent-reachable input. Without this guard, "just fetch the URL"
is an SSRF primitive: the untrusted party can point the fetch at
169.254.169.254 (cloud metadata), at localhost, at an RFC1918 address, or
at a public-looking host that redirects to one of those on request.

Three defenses, all required together:
  1. Scheme allowlist: only http/https. Blocks file://, gopher://, ftp://,
     and friends that some libraries still honor.
  2. IP-literal pre-filter: resolve the hostname and reject if ANY
     resolved address is private, loopback, link-local, reserved,
     multicast, unspecified, or the well-known cloud metadata address.
  3. Manual redirect handling: do not let the HTTP client auto-follow
     redirects. Re-run the same pre-filter on the Location header before
     following it. A public URL that 30x-es to an internal one must not
     sail through on hop 2 just because hop 1 passed.

Residual risk (documented, not silently ignored): step 2 checks the
hostname at request time, not at connect time. A host that resolves
public now and private a few milliseconds later at the TCP connect (DNS
rebinding) is not fully closed by a hostname-level check. For a use case
that only needs a small classification signal back (not response bodies
routed anywhere sensitive), that residual is normally acceptable; for
higher-stakes fetches, pin the resolved IP and connect to it directly
instead of the hostname.
"""

from __future__ import annotations

import ipaddress
import socket
import urllib.error
import urllib.request
from urllib.parse import urlparse

ALLOWED_SCHEMES = ("http", "https")

# Cloud metadata endpoints are link-local addresses but are called out
# explicitly here because they are the single most common real-world SSRF
# target (AWS/GCP/Azure/DigitalOcean all serve credentials from
# 169.254.169.254). is_link_local already catches it; the explicit set
# below is a belt-and-suspenders documentation aid plus a place to add
# other known-bad literals later.
_EXPLICIT_BLOCK = {"169.254.169.254", "::ffff:169.254.169.254"}


def _resolves_to_blocked_address(host: str) -> bool:
    """True if `host` is empty, unresolvable-in-a-suspicious-way, or
    resolves to any address in a blocked range. False means every
    resolved address looked like an ordinary public address.
    """
    if not host:
        return True
    if host in _EXPLICIT_BLOCK:
        return True

    try:
        infos = socket.getaddrinfo(host, None)
    except socket.gaierror:
        # Cannot resolve at all: let the real connection attempt fail
        # with its own error rather than mislabeling this as "blocked".
        return False

    for info in infos:
        raw_addr = info[4][0]
        try:
            addr = ipaddress.ip_address(raw_addr.split("%")[0])
        except ValueError:
            # Could not parse the address the resolver handed back.
            # Fail closed: an address we cannot classify is treated as
            # blocked rather than assumed safe.
            return True
        if str(addr) in _EXPLICIT_BLOCK:
            return True
        if (
            addr.is_private
            or addr.is_loopback
            or addr.is_link_local
            or addr.is_reserved
            or addr.is_multicast
            or addr.is_unspecified
        ):
            return True
    return False


def is_url_safe_to_fetch(url: str) -> tuple[bool, str]:
    """Pre-flight check only, no network fetch performed here beyond DNS
    resolution. Returns (True, "ok") or (False, reason).
    """
    if not url or not isinstance(url, str):
        return False, "empty or non-string url"
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        return False, f"scheme not allowed: {parsed.scheme!r}"
    host = parsed.hostname or ""
    if _resolves_to_blocked_address(host):
        return False, f"host resolves to a blocked address range: {host!r}"
    return True, "ok"


class _SingleHopSafeRedirect(urllib.request.HTTPRedirectHandler):
    """Re-validates the Location header against the same blocklist before
    following it, and refuses to follow more than one hop total. urllib's
    default handler blindly follows redirects, which would let a public
    URL 30x its way to an internal target after the initial check passed.
    """

    def __init__(self) -> None:
        super().__init__()
        self._hops_followed = 0

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if self._hops_followed >= 1:
            raise urllib.error.URLError("refusing to follow a second redirect hop")
        ok, reason = is_url_safe_to_fetch(newurl)
        if not ok:
            raise urllib.error.URLError(f"redirect target blocked: {reason}")
        self._hops_followed += 1
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def safe_fetch(url: str, *, method: str = "HEAD", timeout: int = 15,
                user_agent: str = "security-validators-ssrf-guard"):
    """Fetch `url` with the SSRF guard applied to both the initial request
    and one redirect hop. Raises ValueError before any network call if the
    pre-flight check fails. Returns the urllib response object on success;
    caller is responsible for closing it (use as a context manager).
    """
    ok, reason = is_url_safe_to_fetch(url)
    if not ok:
        raise ValueError(f"refusing to fetch: {reason}")

    opener = urllib.request.build_opener(_SingleHopSafeRedirect())
    req = urllib.request.Request(url, method=method, headers={"User-Agent": user_agent})
    return opener.open(req, timeout=timeout)


if __name__ == "__main__":
    # Inline self-tests exercising the pre-flight logic without requiring
    # network access (DNS resolution of the literals below is either
    # instantaneous, since they are IP literals, or already cached).

    # Scheme allowlist.
    ok, reason = is_url_safe_to_fetch("file:///etc/passwd")
    assert ok is False and "scheme" in reason

    ok, reason = is_url_safe_to_fetch("gopher://example.com/")
    assert ok is False and "scheme" in reason

    # Cloud metadata IP literal, the single most common real SSRF target.
    ok, reason = is_url_safe_to_fetch("http://169.254.169.254/latest/meta-data/")
    assert ok is False

    # Loopback and private-range literals.
    ok, reason = is_url_safe_to_fetch("http://127.0.0.1:8080/admin")
    assert ok is False

    ok, reason = is_url_safe_to_fetch("http://10.0.0.5/internal")
    assert ok is False

    ok, reason = is_url_safe_to_fetch("http://192.168.1.1/")
    assert ok is False

    # localhost by name resolves to a loopback address and must also be
    # blocked, not just the IP literal form.
    ok, reason = is_url_safe_to_fetch("http://localhost/")
    assert ok is False

    # A well-formed public https URL should pass the pre-flight shape
    # checks. (We do not assert True here unconditionally: DNS resolution
    # of a real public hostname depends on network availability in the
    # sandbox this runs in, and this self-test suite must not require
    # network access to pass.) Verify instead that it is not rejected for
    # scheme or for being an unparseable host.
    parsed_ok, parsed_reason = is_url_safe_to_fetch("https://example.com/path")
    assert "scheme" not in parsed_reason

    # Empty / malformed input.
    ok, reason = is_url_safe_to_fetch("")
    assert ok is False

    print("ssrf_guard.py: all self-tests passed")

# Optional Trivy repository assurance

Trivy complements the toolkit's native secret gate with dependency vulnerability, infrastructure-as-code misconfiguration, license, and SBOM-aware repository analysis. It is optional because its vulnerability database download, scan time, and findings are unnecessary for many documentation-only repositories.

The wrapper uses Trivy `v0.72.0` pinned to its published container digest, mounts only this repository read-only, and fails on HIGH or CRITICAL findings:

```shell
scripts/run-trivy.sh
```

Preview the exact portable command without starting Docker or pulling an image:

```shell
scripts/run-trivy.sh --print-command
```

Operational boundaries:

- Review the image pin and upstream release notes before updating it.
- Secret scanning remains the responsibility of `scripts/scan-secrets.sh`; the Trivy wrapper does not duplicate it or suppress this toolkit's synthetic scanner fixtures.
- The first scan downloads vulnerability data over the network into the disposable container.
- The non-sensitive vulnerability database is retained in the `zulfqar-trivy-cache` Docker volume so later scans do not re-download it; remove that volume separately when you want to reclaim it.
- Keep private registries, production clusters, cloud credentials, and unrelated host paths outside the container.
- Treat findings as evidence to investigate, not an automatic compliance decision.
- Generate or publish SBOMs only when the repository owner has approved the artifact and its dependency disclosure.

Upstream: [aquasecurity/trivy](https://github.com/aquasecurity/trivy), Apache-2.0. The toolkit points to and runs the upstream image; it does not vendor Trivy code or databases.

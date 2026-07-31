#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="${REPO_ROOT}/scripts/validate-skill-catalog.sh"
FIXTURE_ROOT="$(mktemp -d)"

cleanup() {
  case "${FIXTURE_ROOT}" in
    /tmp/*|/var/folders/*) rm -rf -- "${FIXTURE_ROOT}" ;;
    *) printf 'refusing to remove unexpected fixture path: %s\n' "${FIXTURE_ROOT}" >&2 ;;
  esac
}
trap cleanup EXIT

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

expect_failure() {
  local label="$1" catalog="$2"
  if bash "${VALIDATOR}" \
    --repo-root="${FIXTURE_ROOT}/repo" \
    --catalog="${catalog}" >"${FIXTURE_ROOT}/validator-output" 2>&1; then
    printf 'FAIL: %s unexpectedly passed\n' "${label}" >&2
    exit 1
  fi
}

[ -f "${VALIDATOR}" ] || {
  printf 'FAIL: skill catalog validator is missing\n' >&2
  exit 1
}

mkdir -p \
  "${FIXTURE_ROOT}/repo/skills/core" \
  "${FIXTURE_ROOT}/repo/optional-skills/extra" \
  "${FIXTURE_ROOT}/repo/docs"

cat >"${FIXTURE_ROOT}/repo/skills/core/SKILL.md" <<'SKILL'
---
name: core
description: Default fixture skill.
---
SKILL
cat >"${FIXTURE_ROOT}/repo/optional-skills/extra/SKILL.md" <<'SKILL'
---
name: extra
description: Optional fixture skill.
---
SKILL
printf '%s\n' core >"${FIXTURE_ROOT}/repo/skills/manifest.txt"
cat >"${FIXTURE_ROOT}/repo/docs/PROVENANCE.yaml" <<'YAML'
- artifact: upstream-one
  relationship: pointer
YAML

core_hash="$(sha256_file "${FIXTURE_ROOT}/repo/skills/core/SKILL.md")"
extra_hash="$(sha256_file "${FIXTURE_ROOT}/repo/optional-skills/extra/SKILL.md")"
valid_catalog="${FIXTURE_ROOT}/valid.tsv"
{
  printf 'record_id\tconcept_id\tname\tsource\tsha256\townership\tdisposition\tcanonical_path\tprovenance_id\tagents\tpublic_reason\n'
  printf 'repo-core\tcore\tcore\trepository\t%s\tauthor\tdefault\tskills/core/SKILL.md\t-\tall\tDefault fixture body.\n' "${core_hash}"
  printf 'local-extra\textra\textra\tagents-shared\t%s\tauthor\toptional\toptional-skills/extra/SKILL.md\t-\tall\tOptional fixture body.\n' "${extra_hash}"
  printf 'upstream-third\tthird\tthird\tclaude-active\t-\tthird-party\tpointer\t-\tupstream-one\tclaude\tThird-party pointer.\n'
  printf 'system-skill\tsystem\tsystem\tcodex-system\t-\tsystem\texcluded\t-\t-\tnone\tSystem-managed exclusion.\n'
} >"${valid_catalog}"

bash "${VALIDATOR}" \
  --repo-root="${FIXTURE_ROOT}/repo" \
  --catalog="${valid_catalog}" >/dev/null

duplicate_owner="${FIXTURE_ROOT}/duplicate-owner.tsv"
cp "${valid_catalog}" "${duplicate_owner}"
printf 'duplicate-extra\textra\textra-two\tclaude-active\t%s\tauthor\toptional\toptional-skills/extra/SKILL.md\t-\tclaude\tDuplicate concept owner.\n' \
  "${extra_hash}" >>"${duplicate_owner}"
expect_failure "duplicate concept owner" "${duplicate_owner}"

missing_body="${FIXTURE_ROOT}/missing-body.tsv"
sed 's#optional-skills/extra/SKILL.md#optional-skills/missing/SKILL.md#' \
  "${valid_catalog}" >"${missing_body}"
expect_failure "missing canonical body" "${missing_body}"

missing_provenance="${FIXTURE_ROOT}/missing-provenance.tsv"
sed 's/upstream-one/missing-upstream/' "${valid_catalog}" >"${missing_provenance}"
expect_failure "pointer without provenance" "${missing_provenance}"

missing_body_provenance="${FIXTURE_ROOT}/missing-body-provenance.tsv"
awk -F '\t' 'BEGIN { OFS = FS } NR == 2 { $9 = "missing-upstream" } { print }' \
  "${valid_catalog}" >"${missing_body_provenance}"
expect_failure "body with unknown provenance" "${missing_body_provenance}"

manifest_drift="${FIXTURE_ROOT}/manifest-drift.tsv"
sed 's/\tdefault\t/\toptional\t/' "${valid_catalog}" >"${manifest_drift}"
expect_failure "manifest and default catalog drift" "${manifest_drift}"

mkdir -p "${FIXTURE_ROOT}/repo/optional-skills/orphan"
cat >"${FIXTURE_ROOT}/repo/optional-skills/orphan/SKILL.md" <<'SKILL'
---
name: orphan
description: Uncataloged optional fixture skill.
---
SKILL
expect_failure "uncataloged optional body" "${valid_catalog}"
rm -rf -- "${FIXTURE_ROOT}/repo/optional-skills/orphan"

bash "${VALIDATOR}" \
  --repo-root="${REPO_ROOT}" \
  --catalog="${REPO_ROOT}/catalog/skills.tsv" >/dev/null

printf 'skill catalog: PASS\n'

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CATALOG=""

for arg in "$@"; do
  case "${arg}" in
    --repo-root=*) REPO_ROOT="${arg#--repo-root=}" ;;
    --catalog=*) CATALOG="${arg#--catalog=}" ;;
    -h|--help)
      printf 'Usage: %s [--repo-root=PATH] [--catalog=PATH]\n' "$0"
      exit 0
      ;;
    *)
      printf 'validate-skill-catalog: unknown argument: %s\n' "${arg}" >&2
      exit 2
      ;;
  esac
done

if [ -z "${CATALOG}" ]; then
  CATALOG="${REPO_ROOT}/catalog/skills.tsv"
fi

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

[ -f "${CATALOG}" ] || fail "catalog not found: ${CATALOG}"
[ -f "${REPO_ROOT}/skills/manifest.txt" ] || fail "default manifest is missing"
[ -f "${REPO_ROOT}/docs/PROVENANCE.yaml" ] || fail "provenance ledger is missing"

expected_header='record_id	concept_id	name	source	sha256	ownership	disposition	canonical_path	provenance_id	agents	public_reason'
IFS= read -r actual_header <"${CATALOG}"
[ "${actual_header}" = "${expected_header}" ] || fail "catalog header does not match the required schema"

if grep -Eq '(/Users/|/home/[^[:space:]]+|[A-Za-z]:\\)' "${CATALOG}"; then
  fail "catalog contains an absolute home or drive path"
fi

work_dir="$(mktemp -d)"
cleanup() {
  case "${work_dir}" in
    /tmp/*|/var/folders/*) rm -rf -- "${work_dir}" ;;
    *) printf 'refusing to remove unexpected validator path: %s\n' "${work_dir}" >&2 ;;
  esac
}
trap cleanup EXIT

tail -n +2 "${CATALOG}" >"${work_dir}/rows"
[ -s "${work_dir}/rows" ] || fail "catalog has no records"

awk -F '\t' '
  NF != 11 {
    printf "line %d has %d fields, expected 11\n", NR + 1, NF > "/dev/stderr"
    bad = 1
    next
  }
  $1 == "" || $2 == "" || $3 == "" || $11 == "" {
    printf "line %d has an empty required field\n", NR + 1 > "/dev/stderr"
    bad = 1
  }
  seen_record[$1]++ {
    printf "duplicate record_id: %s\n", $1 > "/dev/stderr"
    bad = 1
  }
  $4 !~ /^(repository|claude-active|claude-backup|agents-shared|agents-backup|codex-local|codex-system)$/ {
    printf "invalid source on line %d: %s\n", NR + 1, $4 > "/dev/stderr"
    bad = 1
  }
  $6 !~ /^(repository|author|third-party|system|generated|private|unknown)$/ {
    printf "invalid ownership on line %d: %s\n", NR + 1, $6 > "/dev/stderr"
    bad = 1
  }
  $7 !~ /^(default|optional|pointer|excluded|superseded)$/ {
    printf "invalid disposition on line %d: %s\n", NR + 1, $7 > "/dev/stderr"
    bad = 1
  }
  $10 !~ /^(all|claude|codex|shared|none)$/ {
    printf "invalid agents value on line %d: %s\n", NR + 1, $10 > "/dev/stderr"
    bad = 1
  }
  $5 != "-" && $5 !~ /^[0-9a-f]{64}$/ {
    printf "invalid sha256 on line %d\n", NR + 1 > "/dev/stderr"
    bad = 1
  }
  $7 == "default" || $7 == "optional" {
    owner_count[$2]++
    if (owner_count[$2] > 1) {
      printf "multiple body owners for concept_id: %s\n", $2 > "/dev/stderr"
      bad = 1
    }
    if ($8 == "-") {
      printf "body record has no canonical_path: %s\n", $1 > "/dev/stderr"
      bad = 1
    }
    if (seen_path[$8]++) {
      printf "duplicate canonical_path: %s\n", $8 > "/dev/stderr"
      bad = 1
    }
  }
  $7 != "default" && $7 != "optional" && $8 != "-" {
    printf "non-body record has canonical_path: %s\n", $1 > "/dev/stderr"
    bad = 1
  }
  $7 == "pointer" && ($6 != "third-party" || $9 == "-") {
    printf "pointer record lacks third-party ownership or provenance: %s\n", $1 > "/dev/stderr"
    bad = 1
  }
  END { exit bad ? 1 : 0 }
' "${work_dir}/rows" || fail "catalog schema validation failed"

while IFS=$'\t' read -r record_id concept_id name source sha256 ownership disposition canonical_path provenance_id agents public_reason; do
  if [ "${provenance_id}" != "-" ]; then
    grep -Eq "^[[:space:]]*-?[[:space:]]*artifact:[[:space:]]*${provenance_id}[[:space:]]*$" \
      "${REPO_ROOT}/docs/PROVENANCE.yaml" ||
      fail "${record_id} provenance_id is missing: ${provenance_id}"
  fi
  case "${disposition}" in
    default|optional)
      case "${canonical_path}" in
        /*|*'..'*|*\\*) fail "${record_id} has an unsafe canonical path" ;;
      esac
      case "${disposition}:${canonical_path}" in
        default:skills/*/SKILL.md|optional:optional-skills/*/SKILL.md) ;;
        *) fail "${record_id} uses the wrong tree for ${disposition}" ;;
      esac
      skill_file="${REPO_ROOT}/${canonical_path}"
      [ -f "${skill_file}" ] || fail "${record_id} canonical body is missing: ${canonical_path}"
      declared_name="$(sed -n '2s/^name: *//p' "${skill_file}")"
      [ "${declared_name}" = "${name}" ] || fail "${record_id} name differs from ${canonical_path}"
      [ "${sha256}" != "-" ] || fail "${record_id} body is missing a sha256"
      actual_sha256="$(sha256_file "${skill_file}")"
      [ "${actual_sha256}" = "${sha256}" ] || fail "${record_id} sha256 differs from ${canonical_path}"
      ;;
    pointer) ;;
  esac
done <"${work_dir}/rows"

awk -F '\t' '$7 == "default" { print $3 }' "${work_dir}/rows" |
  LC_ALL=C sort >"${work_dir}/catalog-defaults"
awk 'NF && $1 !~ /^#/ { print $1 }' "${REPO_ROOT}/skills/manifest.txt" |
  LC_ALL=C sort >"${work_dir}/manifest-defaults"

cmp -s "${work_dir}/catalog-defaults" "${work_dir}/manifest-defaults" ||
  fail "default catalog entries drift from skills/manifest.txt"

awk -F '\t' '$7 == "default" || $7 == "optional" { print $8 }' "${work_dir}/rows" |
  LC_ALL=C sort >"${work_dir}/catalog-bodies"

{
  for body_root in "${REPO_ROOT}/skills" "${REPO_ROOT}/optional-skills"; do
    [ -d "${body_root}" ] || continue
    find "${body_root}" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print
  done
} |
  while IFS= read -r body_path; do
    case "${body_path}" in
      "${REPO_ROOT}"/*) printf '%s\n' "${body_path#"${REPO_ROOT}/"}" ;;
      *) fail "body path escaped repository root: ${body_path}" ;;
    esac
  done |
  LC_ALL=C sort >"${work_dir}/filesystem-bodies"

cmp -s "${work_dir}/catalog-bodies" "${work_dir}/filesystem-bodies" ||
  fail "catalog body entries drift from skills/ or optional-skills/"

printf 'skill catalog: PASS\n'

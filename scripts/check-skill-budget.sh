#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${SKILL_BUDGET_SKILLS_DIR:-${REPO_ROOT}/skills}"
LIMIT="${SKILL_BUDGET_LIMIT:-8000}"
WARN_LIMIT="${SKILL_BUDGET_WARN_LIMIT:-$((LIMIT * 80 / 100))}"

case "${LIMIT}" in
  ''|*[!0-9]*)
    printf 'FAIL: SKILL_BUDGET_LIMIT must be a non-negative integer\n' >&2
    exit 1
    ;;
esac
case "${WARN_LIMIT}" in
  ''|*[!0-9]*)
    printf 'FAIL: SKILL_BUDGET_WARN_LIMIT must be a non-negative integer\n' >&2
    exit 1
    ;;
esac

if [ "${WARN_LIMIT}" -ge "${LIMIT}" ]; then
  printf 'FAIL: SKILL_BUDGET_WARN_LIMIT must be below SKILL_BUDGET_LIMIT\n' >&2
  exit 1
fi

count=0
used=0
skill_list="$(mktemp)"
trap 'rm -f "${skill_list}"' EXIT
find "${SKILLS_DIR}" -type f -name SKILL.md -print | sort > "${skill_list}"

while IFS= read -r skill_file; do
  metadata_size="$(awk '
    NR == 1 && $0 == "---" { frontmatter = 1; next }
    frontmatter && $0 == "---" {
      if (name_count != 1 || description_count != 1) exit 2
      print length(name) + length(description)
      complete = 1
      exit
    }
    frontmatter && /^name:[[:space:]]*/ {
      name_count++
      sub(/^name:[[:space:]]*/, "")
      name = $0
    }
    frontmatter && /^description:[[:space:]]*/ {
      description_count++
      sub(/^description:[[:space:]]*/, "")
      description = $0
    }
    END { if (!complete) exit 2 }
  ' "${skill_file}")" || {
    printf 'FAIL: invalid or ambiguous name/description frontmatter in %s\n' "${skill_file}" >&2
    exit 1
  }
  count=$((count + 1))
  used=$((used + metadata_size))
done < "${skill_list}"

if [ "${used}" -gt "${LIMIT}" ]; then
  printf 'skill budget: FAIL count=%s used=%s limit=%s warning=%s\n' \
    "${count}" "${used}" "${LIMIT}" "${WARN_LIMIT}" >&2
  exit 1
fi

if [ "${used}" -ge "${WARN_LIMIT}" ]; then
  printf 'skill budget: WARN count=%s used=%s limit=%s warning=%s\n' \
    "${count}" "${used}" "${LIMIT}" "${WARN_LIMIT}" >&2
fi

printf 'skill budget: PASS count=%s used=%s limit=%s warning=%s\n' \
  "${count}" "${used}" "${LIMIT}" "${WARN_LIMIT}"

#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

check_skill() {
  local skill_name="$1"
  local skill_file="$2"
  local strict_prefix="${3:-false}"
  local declared_name description

  declared_name="$(sed -n '2s/^name: *//p' "${skill_file}")"
  [ "${declared_name}" = "${skill_name}" ] || {
    printf 'FAIL: %s declares name %s\n' "${skill_name}" "${declared_name}" >&2
    exit 1
  }
  description="$(sed -n '3s/^description: *//p' "${skill_file}")"
  [ -n "${description}" ] || {
    printf 'FAIL: %s has no single-line description\n' "${skill_name}" >&2
    exit 1
  }
  if [ "${strict_prefix}" = true ]; then
    [ "$(sed -n '1p;4p' "${skill_file}")" = "$(printf '%s\n%s' '---' '---')" ] || {
      printf 'FAIL: %s does not use the required four-line frontmatter prefix\n' "${skill_name}" >&2
      exit 1
    }
  fi
  case "${description}" in
    *:*)
      case "${description}" in
        \"*\"|\'*\') ;;
        *)
          printf 'FAIL: %s has an unquoted YAML description containing a colon\n' "${skill_name}" >&2
          exit 1
          ;;
      esac
      ;;
  esac
}

while IFS= read -r skill_name || [ -n "${skill_name}" ]; do
  case "${skill_name}" in ""|\#*) continue ;; esac
  skill_file="${REPO_ROOT}/skills/${skill_name}/SKILL.md"
  check_skill "${skill_name}" "${skill_file}"
done < "${REPO_ROOT}/skills/manifest.txt"

while IFS= read -r skill_file; do
  skill_name="$(basename "$(dirname "${skill_file}")")"
  check_skill "${skill_name}" "${skill_file}" true
done < <(find "${REPO_ROOT}/optional-skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print | sort)

printf 'skill frontmatter: PASS\n'

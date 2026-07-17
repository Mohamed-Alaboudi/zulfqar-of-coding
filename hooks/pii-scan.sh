#!/usr/bin/env bash
# pii-scan.sh - manual/pre-commit PII and secret scanner.
#
# WHAT THIS IS
#   A standalone text scanner for 14 PII/secret categories. It is NOT wired
#   into any hook and runs nowhere automatically. Invoke it yourself:
#
#     pii-scan.sh path/to/file.txt        # scan one file
#     git diff --cached | pii-scan.sh -    # scan staged diff via stdin
#     cat notes.md | pii-scan.sh           # stdin also works with no args
#     pii-scan.sh --selftest               # run the built-in detection test
#
#   As a manual pre-commit gate, add to .git/hooks/pre-commit (per-repo,
#   opt-in - this script never edits that file for you):
#     #!/usr/bin/env bash
#     git diff --cached | hooks/pii-scan.sh - || exit 1
#
#   For a HARDER, public-repo-oriented gate (bare project UUIDs, Slack/Google/
#   Anthropic/GitLab/npm/SendGrid keys, personal identifiers, exit 1 on ANY
#   hit), use scripts/scan-secrets.sh instead - it ports this battery and adds
#   those categories.
#
# EXIT CODES
#   0  clean, or only LOW/MEDIUM severity findings
#   1  at least one HIGH severity finding (live-looking API key or private
#      key header) - treat as a gate failure
#   2  usage error (bad args, unreadable file)
#
# WHAT IT PRINTS
#   One line per finding: severity, category, line number, redacted preview.
#   The scanner never prints a full match. Previews keep a short prefix/
#   suffix and replace the middle with asterisks, or for very short matches
#   collapse the whole thing to asterisks. This is a heuristic pattern
#   scanner, not a validator - false positives and false negatives both
#   happen. Treat findings as "go look here," not proof.
#
# CATEGORIES (14)
#   email, ssn (US), credit-card-like, generic-api-key, stripe-key,
#   openai-key, github-token, aws-access-key-id, aws-secret-access-key,
#   private-key-header, password-assignment, jwt, ipv4, phone (US-style)
#
# PROVENANCE
#   Behavior modeled after the "scan a file/diff for common secret and PII
#   shapes before commit" pattern popularized by ruvnet/ruflo's aidefence
#   pre-commit tooling. This file is an independent, from-scratch
#   reimplementation: no code, regex literals, or text were copied from that
#   or any other project. Category list, severities, and redaction scheme are
#   original choices. Ships in the Zulfqar of Coding toolkit.
#
# COMPANION
#   Complements hooks/git-guardrail.sh, which blocks staging/committing
#   .env-style files outright. This script instead looks INSIDE file
#   content (any file, any extension) for PII/secret shapes and is a
#   manual check, not an automatic block.
set -u

SCRIPT_NAME="$(basename "$0")"
HIGH_FOUND=0
FINDING_COUNT=0

usage() {
  cat <<'EOF'
usage: pii-scan.sh <file>       scan a file
       pii-scan.sh -            scan stdin
       pii-scan.sh              scan stdin (no args)
       pii-scan.sh --selftest   run built-in detection self-test
EOF
}

# --- redaction -----------------------------------------------------------
# Never echo the full matched secret. Keep up to 2 chars at each end for
# matches long enough for that to still be safe-ish for a human to spot
# which finding is which; shorter matches collapse entirely to asterisks.
redact() {
  local s="$1"
  local len=${#s}
  if (( len <= 6 )); then
    printf '%s' "$(printf '%*s' "$len" '' | tr ' ' '*')"
    return
  fi
  local head="${s:0:2}"
  local tail="${s: -2}"
  local mid_len=$(( len - 4 ))
  local mid
  mid="$(printf '%*s' "$mid_len" '' | tr ' ' '*')"
  printf '%s%s%s' "$head" "$mid" "$tail"
}

# --- finding emitter -------------------------------------------------------
# emit SEVERITY CATEGORY LINENO MATCHTEXT
emit() {
  local sev="$1" cat="$2" lineno="$3" match="$4"
  FINDING_COUNT=$((FINDING_COUNT + 1))
  [[ "$sev" == "HIGH" ]] && HIGH_FOUND=1
  local red
  red="$(redact "$match")"
  printf '[%s] %-22s line %-5s preview: %s\n' "$sev" "$cat" "$lineno" "$red"
}

# --- category checks --------------------------------------------------------
# Each function takes one line of text + its line number and calls emit()
# zero or more times. Kept as small independent passes rather than one
# mega-regex so categories stay easy to audit/extend individually.

check_email() {
  local line="$1" n="$2"
  local re='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  while [[ "$line" =~ $re ]]; do
    emit "MEDIUM" "email" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_ssn() {
  local line="$1" n="$2"
  # US SSN shape: NNN-NN-NNNN, excluding the reserved 000/666/9xx area and
  # 00 group / 0000 serial ranges that are never issued.
  # NOTE: bash [[ =~ ]] compiles POSIX ERE (via libc regcomp), which has no
  # \b word-boundary token, so \b never matches and silently kills the whole
  # pattern. Boundary is hand-rolled here with (^|[^0-9]) / ([^0-9]|$),
  # which shifts every capture group index up by one (group 1 is now the
  # leading boundary, not the area code) - the reads below account for that.
  local re='(^|[^0-9])(0[0-9]{2}|[1-8][0-9]{2}|9[0-8][0-9])-([0-9]{2})-([0-9]{4})([^0-9]|$)'
  while [[ "$line" =~ $re ]]; do
    local area="${BASH_REMATCH[2]}" grp="${BASH_REMATCH[3]}" ser="${BASH_REMATCH[4]}"
    local full="${area}-${grp}-${ser}"
    if [[ "$area" != "666" && "$grp" != "00" && "$ser" != "0000" ]]; then
      emit "HIGH" "us-ssn" "$n" "$full"
    fi
    line="${line/$full/}"
  done
}

check_credit_card() {
  local line="$1" n="$2"
  # 13-19 digits, optionally grouped by space/hyphen in 4s - a shape check,
  # not a Luhn validator (deliberately: keep this fast and dependency-free).
  # No \b: bash [[ =~ ]] is POSIX ERE (no word-boundary token), so \b never
  # matches and silently kills the pattern - see check_ssn for the full note.
  local re='[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{1,7}'
  while [[ "$line" =~ $re ]]; do
    local full="${BASH_REMATCH[0]}"
    local digits="${full//[^0-9]/}"
    local dlen=${#digits}
    if (( dlen >= 13 && dlen <= 19 )); then
      emit "HIGH" "credit-card-like" "$n" "$full"
    fi
    line="${line/$full/}"
  done
}

check_generic_api_key() {
  local line="$1" n="$2"
  # Widely-used "sk-" prefixed secret shape not already covered by a more
  # specific vendor check below (OpenAI/Stripe have their own checks; this
  # catches other sk-/pk-/api- style tokens with >=20 trailing chars).
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='(sk|pk)-[A-Za-z0-9_]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "HIGH" "generic-api-key" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_stripe_key() {
  local line="$1" n="$2"
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='(sk|pk|rk)_(live|test)_[A-Za-z0-9]{16,}'
  while [[ "$line" =~ $re ]]; do
    emit "HIGH" "stripe-key" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_openai_key() {
  local line="$1" n="$2"
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='sk-(proj-)?[A-Za-z0-9_-]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "HIGH" "openai-key" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_github_token() {
  local line="$1" n="$2"
  # Covers ghp_ (personal), gho_ (oauth), ghu_ (user-to-server),
  # ghs_ (server-to-server), ghr_ (refresh), github_pat_ (fine-grained).
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "HIGH" "github-token" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
  local pat_re='github_pat_[A-Za-z0-9_]{20,}'
  while [[ "$line" =~ $pat_re ]]; do
    emit "HIGH" "github-token" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_aws_access_key_id() {
  local line="$1" n="$2"
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='(AKIA|ASIA)[A-Z0-9]{16}'
  while [[ "$line" =~ $re ]]; do
    emit "HIGH" "aws-access-key-id" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_aws_secret_key() {
  local line="$1" n="$2"
  # AWS secret access keys are 40 base64-ish chars with no fixed prefix, so
  # this only fires when the line's own variable name says what it is -
  # otherwise the false-positive rate on any 40-char token is too high.
  local re='([Aa][Ww][Ss].?)?[Ss]ecret.?([Aa]ccess)?.?[Kk]ey["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?([A-Za-z0-9/+]{40})["'"'"']?'
  if [[ "$line" =~ $re ]]; then
    emit "HIGH" "aws-secret-access-key" "$n" "${BASH_REMATCH[3]}"
  fi
}

check_private_key_header() {
  local line="$1" n="$2"
  local re='-----BEGIN (RSA|EC|OPENSSH|DSA|PGP|ENCRYPTED)? ?PRIVATE KEY-----'
  if [[ "$line" =~ $re ]]; then
    emit "HIGH" "private-key-header" "$n" "${BASH_REMATCH[0]}"
  fi
}

check_password_assignment() {
  local line="$1" n="$2"
  # variable name containing password/passwd/pwd/secret, followed by an
  # assignment operator and a quoted or bare non-empty value. Skip common
  # placeholder values so .env.example-style files do not trip HIGH noise.
  local re='([Pp]assword|[Pp]asswd|[Pp]wd|[Ss]ecret)[[:space:]]*[:=][[:space:]]*["'"'"']?([^"'"'"'[:space:]]{4,})["'"'"']?'
  if [[ "$line" =~ $re ]]; then
    local val="${BASH_REMATCH[2]}"
    local lower
    lower="$(printf '%s' "$val" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      changeme|your_password_here|xxxxx*|placeholder|example|redacted|\<*\>|\$\{*|\$*)
        return ;;
    esac
    emit "MEDIUM" "password-assignment" "$n" "$val"
  fi
}

check_jwt() {
  local line="$1" n="$2"
  # header.payload.signature, each segment base64url. Anchor on the header
  # segment starting eyJ (base64 of {" ) to keep this specific to JWTs.
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]{10,}'
  while [[ "$line" =~ $re ]]; do
    emit "HIGH" "jwt" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_ipv4() {
  local line="$1" n="$2"
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  # Boundary hand-rolled with (^|[^0-9]) / ([^0-9]|$), which shifts every
  # capture group up by one - group 1 is the leading boundary, not octet 1.
  local re='(^|[^0-9])([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})([^0-9]|$)'
  while [[ "$line" =~ $re ]]; do
    local o1="${BASH_REMATCH[2]}" o2="${BASH_REMATCH[3]}" o3="${BASH_REMATCH[4]}" o4="${BASH_REMATCH[5]}"
    local full="${o1}.${o2}.${o3}.${o4}"
    if (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 )); then
      emit "LOW" "ipv4" "$n" "$full"
    fi
    line="${line/$full/}"
  done
}

check_phone() {
  local line="$1" n="$2"
  # US/NANP-style: optional +1, area code, exchange, line number, common
  # separators. Deliberately narrow to cut noise from version strings etc.
  # No \b: see check_ssn note (POSIX ERE has no word-boundary token).
  local re='(\+?1[-. ]?)?\(?[0-9]{3}\)?[-. ][0-9]{3}[-. ][0-9]{4}'
  while [[ "$line" =~ $re ]]; do
    emit "MEDIUM" "phone-us" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

# --- driver ------------------------------------------------------------

scan_stream() {
  local n=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    check_email "$line" "$n"
    check_ssn "$line" "$n"
    check_credit_card "$line" "$n"
    check_generic_api_key "$line" "$n"
    check_stripe_key "$line" "$n"
    check_openai_key "$line" "$n"
    check_github_token "$line" "$n"
    check_aws_access_key_id "$line" "$n"
    check_aws_secret_key "$line" "$n"
    check_private_key_header "$line" "$n"
    check_password_assignment "$line" "$n"
    check_jwt "$line" "$n"
    check_ipv4 "$line" "$n"
    check_phone "$line" "$n"
  done
}

run_scan() {
  local target="$1"
  FINDING_COUNT=0
  HIGH_FOUND=0
  if [[ "$target" == "-" ]]; then
    scan_stream
  else
    if [[ ! -r "$target" ]]; then
      printf '%s: cannot read file: %s\n' "$SCRIPT_NAME" "$target" >&2
      return 2
    fi
    scan_stream < "$target"
  fi
  if (( FINDING_COUNT == 0 )); then
    printf 'pii-scan: clean, no findings\n'
  else
    printf 'pii-scan: %d finding(s), %s\n' "$FINDING_COUNT" \
      "$([[ $HIGH_FOUND -eq 1 ]] && echo 'HIGH severity present - gate should fail' || echo 'no HIGH severity')"
  fi
  (( HIGH_FOUND == 1 )) && return 1
  return 0
}

# --- selftest ------------------------------------------------------------
# Fake, obviously-non-functional PII/secret samples only. Confirms:
#   1. every category fires at least one finding on its sample line
#   2. the raw secret text never appears in the script's own stdout
selftest() {
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/pii-scan-selftest.XXXXXX")"
  trap 'rm -f "$tmp"' RETURN

  # Every value below is synthetic: wrong checksum/length/charset patterns
  # or textbook-documentation examples, not a credential that works anywhere.
  cat > "$tmp" <<'SAMPLES'
Contact: jane.doe@sample-mail.net for details.
SSN on file: 219-09-9999
Card on file: 4111-1111-1111-1112
generic key: sk-abcdEFGH1234567890abcd
stripe: sk_test_A0000000000000000A99
openai: sk-proj-A000000000abcdEFGHijklMNOP
github: ghp_A000000000abcdEFGHijklMNOP
aws id: AKIA0000000000000A99
aws_secret_key = "A00000000abcdEFGHijklMNOPqrstUVWXYZ0000009"
-----BEGIN RSA PRIVATE KEY-----
password: hunter2synthetic
jwt: eyJhbGciOiJIUzI1NiJ9.eyJmYWtlIjp0cnVlfQ.A0000sigA0000sigA0000sig
server ip 10.20.30.41 responded
call me at 415-555-0182
SAMPLES

  local out
  out="$(run_scan "$tmp" 2>&1)"
  local status=$?

  local pass=1
  local expect_categories=(
    "email" "us-ssn" "credit-card-like" "generic-api-key" "stripe-key"
    "openai-key" "github-token" "aws-access-key-id" "aws-secret-access-key"
    "private-key-header" "password-assignment" "jwt" "ipv4" "phone-us"
  )
  echo "== selftest: category detection =="
  for cat in "${expect_categories[@]}"; do
    if printf '%s' "$out" | grep -q "$cat"; then
      printf '  [ok]   %s detected\n' "$cat"
    else
      printf '  [FAIL] %s NOT detected\n' "$cat"
      pass=0
    fi
  done

  echo "== selftest: redaction (raw secrets must not appear in output) =="
  local raw_secrets=(
    "jane.doe@sample-mail.net"
    "219-09-9999"
    "4111-1111-1111-1112"
    "sk-abcdEFGH1234567890abcd"
    "sk_test_A0000000000000000A99"
    "sk-proj-A000000000abcdEFGHijklMNOP"
    "ghp_A000000000abcdEFGHijklMNOP"
    "AKIA0000000000000A99"
    "A00000000abcdEFGHijklMNOPqrstUVWXYZ0000009"
    "hunter2synthetic"
    "eyJhbGciOiJIUzI1NiJ9.eyJmYWtlIjp0cnVlfQ.A0000sigA0000sigA0000sig"
  )
  for secret in "${raw_secrets[@]}"; do
    if printf '%s' "$out" | grep -qF -- "$secret"; then
      printf '  [FAIL] raw secret leaked in output: (category for %.10s...)\n' "$secret"
      pass=0
    else
      printf '  [ok]   redacted: %.10s...\n' "$secret"
    fi
  done

  echo "== selftest: exit code =="
  if (( status == 1 )); then
    printf '  [ok]   exit code 1 (HIGH severity present)\n'
  else
    printf '  [FAIL] expected exit code 1, got %d\n' "$status"
    pass=0
  fi

  echo "== selftest: false-positive control (clean file exits 0) =="
  local clean_tmp
  clean_tmp="$(mktemp "${TMPDIR:-/tmp}/pii-scan-selftest-clean.XXXXXX")"
  printf 'just a normal line of prose with no secrets in it.\n' > "$clean_tmp"
  run_scan "$clean_tmp" > /dev/null 2>&1
  local clean_status=$?
  rm -f "$clean_tmp"
  if (( clean_status == 0 )); then
    printf '  [ok]   clean file exits 0\n'
  else
    printf '  [FAIL] clean file exited %d, expected 0\n' "$clean_status"
    pass=0
  fi

  echo
  if (( pass == 1 )); then
    echo "SELFTEST RESULT: PASS"
    return 0
  else
    echo "SELFTEST RESULT: FAIL"
    return 1
  fi
}

# --- entry ---------------------------------------------------------------

main() {
  if [[ $# -eq 0 ]]; then
    run_scan "-"
    exit $?
  fi
  case "$1" in
    --selftest)
      selftest
      exit $?
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -)
      run_scan "-"
      exit $?
      ;;
    *)
      run_scan "$1"
      exit $?
      ;;
  esac
}

main "$@"

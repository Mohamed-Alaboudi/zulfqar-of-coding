#!/usr/bin/env bash
# scan-secrets.sh - the secret-scan GATE for this public repo.
#
# WHAT THIS IS
#   A hard leak gate. Scans a file, a directory (recursively), or stdin for
#   PII, credential-shaped strings, cloud/vendor API keys, bare project UUIDs,
#   and personal identifiers, and EXITS 1 if it finds ANY of them. Run it
#   before every push; wire it as a pre-commit / pre-push hook (see below).
#
#   Intentionally STRICTER than a generic PII scanner: for a public repo, one
#   leaked project id or home path is a real incident, so every hit is a gate
#   failure (exit 1), not just the "HIGH severity" ones a triage scanner would
#   let slide.
#
# USAGE
#   scan-secrets.sh <path>        scan a file, or a dir recursively
#   scan-secrets.sh -             scan stdin
#   scan-secrets.sh               scan stdin (no args)
#   scan-secrets.sh --strict <p>  also flag generic single-word identifiers
#   scan-secrets.sh --selftest    run the built-in detection self-test
#   scan-secrets.sh -h|--help     usage
#
#   Wire as a git pre-commit gate (per-repo, opt-in - this script never edits
#   .git/hooks for you):
#     #!/usr/bin/env bash
#     git diff --cached | scripts/scan-secrets.sh - || {
#       echo "scan-secrets: leak detected - commit blocked"; exit 1; }
#
# EXIT CODES
#   0  clean, no findings
#   1  at least one finding (GATE FAILURE) - or self-test failed
#   2  usage error (bad args, unreadable path)
#
# OUTPUT
#   One line per finding: file:line:category  preview: <redacted>
#   The scanner NEVER echoes a full secret. Previews keep a short prefix/suffix
#   and asterisk out the middle (very short matches collapse entirely). This is
#   a heuristic pattern scanner, not a validator: treat findings as "go look
#   here," false positives and false negatives both happen.
#
# CATEGORIES
#   Ported from a proven PII/secret battery (email, us-ssn, credit-card,
#   generic-api-key, stripe, openai, github, aws-access-key-id,
#   aws-secret-access-key, private-key-header, password-assignment, jwt, ipv4,
#   phone) PLUS the leaks that generic PII scanners miss for a public agent
#   repo: bare project UUID / projectId, Slack tokens + webhooks, Google API
#   key, Anthropic key, GitLab PAT, npm token, SendGrid key, private-key
#   filenames, and literal personal / company identifiers.
#
# PROVENANCE
#   Category structure (multiple PII/secret pattern classes checked in one
#   pass, per-line, with redaction) is modeled after the ruvnet/ruflo
#   aidefence pre-commit pattern and reimplemented independently for this
#   toolkit. No regex literals or code were copied from any upstream project.
#
# NOTE ON `set`
#   Uses `set -u` (unset-var guard) ONLY - deliberately NOT `set -e`/`set -o
#   pipefail`. A pattern scanner runs many greps that legitimately "fail" (no
#   match / exit 1); `set -e` would abort the whole scan on the first clean
#   line, which for a security gate is a silent false PASS. Errors are handled
#   explicitly instead.
set -u

SCRIPT_NAME="$(basename "$0")"
FINDING_COUNT=0
STRICT=0

usage() {
  cat <<'EOF'
usage: scan-secrets.sh <path>       scan a file, or a dir recursively
       scan-secrets.sh -            scan stdin
       scan-secrets.sh              scan stdin (no args)
       scan-secrets.sh --strict <p> also flag generic single-word identifiers
       scan-secrets.sh --selftest   run built-in detection self-test
       scan-secrets.sh -h|--help    this help

exit 0 = clean; exit 1 = at least one finding (GATE FAILURE); exit 2 = usage error
EOF
}

# --- redaction -----------------------------------------------------------
# Never echo the full matched value. Keep up to 2 chars at each end for
# matches long enough that a human can still tell findings apart; shorter
# matches collapse entirely to asterisks.
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

# --- allowlist -----------------------------------------------------------
# Legitimate placeholders / docs samples that must NOT flag. Checked against
# the raw matched substring: any match containing FAKE / EXAMPLE / XXXX, a
# ${...} placeholder, a <YOUR_...> token, an example.com/org host, or the
# specific ${EXA_API_KEY} placeholder is allowed.
is_allowlisted() {
  local v="$1"
  case "$v" in
    *'${'*'}'*) return 0 ;;                        # ${ENV_VAR} placeholders
    *'<YOUR_'*'>'*|*'<your_'*'>'*) return 0 ;;     # <YOUR_KEY> style
    *FAKE*|*fake*) return 0 ;;
    *EXAMPLE*|*example*) return 0 ;;
    *XXXX*|*xxxx*) return 0 ;;
    *example.com*|*example.org*) return 0 ;;
    '${EXA_API_KEY}') return 0 ;;
  esac
  return 1
}

# --- finding emitter -------------------------------------------------------
# emit CATEGORY FILE LINENO MATCHTEXT   (skips allowlisted matches)
#
# Two tiers. GATE categories (keys, tokens, UUIDs, private-key material,
# personal identifiers, emails, SSNs, cards) count toward FINDING_COUNT and
# fail the gate (exit 1) — a real leak. INFO categories (ipv4, phone) are
# printed for the reader but do NOT fail the gate: a bare IP or a formatted
# phone number is not a credential, and legitimate content routinely contains
# them (e.g. a SSRF-guard library MUST reference 10.0.0.0/169.254.169.254).
# Gating on those would keep a clean repo red forever and abort install.sh's
# own preflight on a fresh clone.
# private-key-filename is INFO too: a *reference* to id_rsa/*.pem is just a
# name, not key material (the gating check for that is private-key-header,
# which matches an actual -----BEGIN ... PRIVATE KEY----- block). Gating on
# the name would trip on .gitignore / .env.example / docs that legitimately
# list these patterns to EXCLUDE them.
INFO_CATEGORIES=" ipv4 phone-us private-key-filename "
emit() {
  local cat="$1" file="$2" lineno="$3" match="$4"
  is_allowlisted "$match" && return 0
  local red
  red="$(redact "$match")"
  if [[ "$INFO_CATEGORIES" == *" $cat "* ]]; then
    printf '%s:%s:%s  preview: %s   [info, non-gating]\n' "$file" "$lineno" "$cat" "$red"
    return 0
  fi
  FINDING_COUNT=$((FINDING_COUNT + 1))
  printf '%s:%s:%s  preview: %s\n' "$file" "$lineno" "$cat" "$red"
}

# --- category checks --------------------------------------------------------
# Each takes a line, its line number, and the current file label, and calls
# emit() zero+ times. Kept as small independent passes so categories stay
# easy to audit/extend. NOTE: bash [[ =~ ]] compiles POSIX ERE via libc
# regcomp, which has NO \b word-boundary token (\b silently never matches and
# kills the whole pattern) - boundaries are hand-rolled with (^|[^..]) /
# ([^..]|$), which shifts capture-group indexes up by one where used.

# ---- ported pii battery ----

check_email() {
  local line="$1" n="$2" f="$3"
  local re='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
  while [[ "$line" =~ $re ]]; do
    emit "email" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_ssn() {
  local line="$1" n="$2" f="$3"
  local re='(^|[^0-9])(0[0-9]{2}|[1-8][0-9]{2}|9[0-8][0-9])-([0-9]{2})-([0-9]{4})([^0-9]|$)'
  while [[ "$line" =~ $re ]]; do
    local area="${BASH_REMATCH[2]}" grp="${BASH_REMATCH[3]}" ser="${BASH_REMATCH[4]}"
    local full="${area}-${grp}-${ser}"
    if [[ "$area" != "666" && "$grp" != "00" && "$ser" != "0000" ]]; then
      emit "us-ssn" "$f" "$n" "$full"
    fi
    line="${line/$full/}"
  done
}

check_credit_card() {
  local line="$1" n="$2" f="$3"
  local re='[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{4}[- ]?[0-9]{1,7}'
  while [[ "$line" =~ $re ]]; do
    local full="${BASH_REMATCH[0]}"
    local digits="${full//[^0-9]/}"
    local dlen=${#digits}
    if (( dlen >= 13 && dlen <= 19 )); then
      emit "credit-card-like" "$f" "$n" "$full"
    fi
    line="${line/$full/}"
  done
}

check_stripe_key() {
  local line="$1" n="$2" f="$3"
  local re='(sk|pk|rk)_(live|test)_[A-Za-z0-9]{16,}'
  while [[ "$line" =~ $re ]]; do
    emit "stripe-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_openai_key() {
  local line="$1" n="$2" f="$3"
  local re='sk-(proj-)?[A-Za-z0-9_-]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "openai-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_generic_api_key() {
  local line="$1" n="$2" f="$3"
  # sk-/pk- style tokens not caught by the vendor-specific checks above.
  local re='(sk|pk)-[A-Za-z0-9_]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "generic-api-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_github_token() {
  local line="$1" n="$2" f="$3"
  local re='(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "github-token" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
  local pat_re='github_pat_[A-Za-z0-9_]{20,}'
  while [[ "$line" =~ $pat_re ]]; do
    emit "github-token" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_aws_access_key_id() {
  local line="$1" n="$2" f="$3"
  local re='(AKIA|ASIA)[A-Z0-9]{16}'
  while [[ "$line" =~ $re ]]; do
    emit "aws-access-key-id" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_aws_secret_key() {
  local line="$1" n="$2" f="$3"
  # 40 base64-ish chars, only when the line's own var name says what it is.
  local re='([Aa][Ww][Ss].?)?[Ss]ecret.?([Aa]ccess)?.?[Kk]ey["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?([A-Za-z0-9/+]{40})["'"'"']?'
  if [[ "$line" =~ $re ]]; then
    emit "aws-secret-access-key" "$f" "$n" "${BASH_REMATCH[3]}"
  fi
}

check_private_key_header() {
  local line="$1" n="$2" f="$3"
  local re='-----BEGIN (RSA|EC|OPENSSH|DSA|PGP|ENCRYPTED)? ?PRIVATE KEY-----'
  if [[ "$line" =~ $re ]]; then
    emit "private-key-header" "$f" "$n" "${BASH_REMATCH[0]}"
  fi
}

check_password_assignment() {
  local line="$1" n="$2" f="$3"
  local re='([Pp]assword|[Pp]asswd|[Pp]wd|[Ss]ecret)[[:space:]]*[:=][[:space:]]*["'"'"']?([^"'"'"'[:space:]]{4,})["'"'"']?'
  if [[ "$line" =~ $re ]]; then
    local val="${BASH_REMATCH[2]}"
    local lower
    lower="$(printf '%s' "$val" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
      changeme|your_password_here|xxxxx*|placeholder|example|redacted|\<*\>|\$\{*|\$*)
        return ;;
    esac
    emit "password-assignment" "$f" "$n" "$val"
  fi
}

check_jwt() {
  local line="$1" n="$2" f="$3"
  local re='eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]{10,}'
  while [[ "$line" =~ $re ]]; do
    emit "jwt" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_ipv4() {
  local line="$1" n="$2" f="$3"
  local re='(^|[^0-9])([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})([^0-9]|$)'
  while [[ "$line" =~ $re ]]; do
    local o1="${BASH_REMATCH[2]}" o2="${BASH_REMATCH[3]}" o3="${BASH_REMATCH[4]}" o4="${BASH_REMATCH[5]}"
    local full="${o1}.${o2}.${o3}.${o4}"
    if (( o1 <= 255 && o2 <= 255 && o3 <= 255 && o4 <= 255 )); then
      emit "ipv4" "$f" "$n" "$full"
    fi
    line="${line/$full/}"
  done
}

check_phone() {
  local line="$1" n="$2" f="$3"
  local re='(\+?1[-. ]?)?\(?[0-9]{3}\)?[-. ][0-9]{3}[-. ][0-9]{4}'
  while [[ "$line" =~ $re ]]; do
    emit "phone-us" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

# ---- gaps a generic PII scanner misses (the real risks for THIS repo) ----

check_bare_uuid() {
  local line="$1" n="$2" f="$3"
  # HIGHEST priority: a bare UUID is how an Infisical/Supabase projectId slips
  # a generic PII scanner. Flag both the raw 8-4-4-4-12 hex form and any
  # projectId= assignment.
  local re='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
  while [[ "$line" =~ $re ]]; do
    emit "bare-uuid-projectid" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
  local pid_re='[Pp]roject[Ii][Dd][[:space:]]*[:=][[:space:]]*["'"'"']?([A-Za-z0-9_-]{8,})'
  if [[ "$line" =~ $pid_re ]]; then
    emit "projectid-assignment" "$f" "$n" "${BASH_REMATCH[1]}"
  fi
}

check_slack() {
  local line="$1" n="$2" f="$3"
  local re='xox[baprs]-[A-Za-z0-9-]{8,}'
  while [[ "$line" =~ $re ]]; do
    emit "slack-token" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
  local hook_re='hooks\.slack\.com/services/[A-Za-z0-9/_-]+'
  while [[ "$line" =~ $hook_re ]]; do
    emit "slack-webhook" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_google_api_key() {
  local line="$1" n="$2" f="$3"
  local re='AIza[0-9A-Za-z_-]{35}'
  while [[ "$line" =~ $re ]]; do
    emit "google-api-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_anthropic_key() {
  local line="$1" n="$2" f="$3"
  local re='sk-ant-[A-Za-z0-9_-]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "anthropic-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_gitlab_pat() {
  local line="$1" n="$2" f="$3"
  local re='glpat-[A-Za-z0-9_-]{20,}'
  while [[ "$line" =~ $re ]]; do
    emit "gitlab-pat" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_npm_token() {
  local line="$1" n="$2" f="$3"
  local re='npm_[A-Za-z0-9]{36}'
  while [[ "$line" =~ $re ]]; do
    emit "npm-token" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_sendgrid() {
  local line="$1" n="$2" f="$3"
  local re='SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}'
  while [[ "$line" =~ $re ]]; do
    emit "sendgrid-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
  local brevo_re='xkeysib-[A-Za-z0-9_-]{20,}'
  while [[ "$line" =~ $brevo_re ]]; do
    emit "sendgrid-brevo-key" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_private_key_filename() {
  local line="$1" n="$2" f="$3"
  # References to private-key material by filename in prose/config.
  local re='([A-Za-z0-9._/-]*\.(pem|p12)|[A-Za-z0-9._/-]*id_rsa[A-Za-z0-9._-]*)'
  while [[ "$line" =~ $re ]]; do
    emit "private-key-filename" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done
}

check_personal_identifiers() {
  local line="$1" n="$2" f="$3"
  # Literal personal / infra identifiers that must NEVER reach a public repo.
  # Home-path and email checks are always on. Company/person phrases are
  # matched as whole phrases (not bare common words) to avoid false hits.
  local lower
  lower="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in *hamoodey*) emit "personal-identifier" "$f" "$n" "REDACTED-HANDLE" ;; esac

  # Generic home-path roots (any user). Matched with a boundary so even a bare
  # "/Users/" reference in prose trips - the intent for a public repo that must
  # ship no absolute home paths. (This subsumes any specific personal path.)
  local hp_re='(/Users/|/home/)[A-Za-z0-9._-]+'
  while [[ "$line" =~ $hp_re ]]; do
    emit "home-path" "$f" "$n" "${BASH_REMATCH[0]}"
    line="${line/${BASH_REMATCH[0]}/}"
  done

  # Company / project phrases (whole-phrase, case-insensitive).
  case "$lower" in *"liberty pay"*) emit "company-identifier" "$f" "$n" "REDACTED-CO" ;; esac
  case "$lower" in *"together tech"*) emit "company-identifier" "$f" "$n" "REDACTED-CO" ;; esac

  # Single-word identifiers that overlap common English are gated behind
  # --strict (they'd false-positive on innocent substrings otherwise). Word
  # boundaries hand-rolled. This is the deliberate opt-in for a paranoid final
  # sweep before a public push.
  if (( STRICT == 1 )); then
    local sre='(^|[^A-Za-z0-9])(moea|emran|justin|cortex|flux)([^A-Za-z0-9]|$)'
    local scan="$lower"
    while [[ "$scan" =~ $sre ]]; do
      emit "strict-identifier" "$f" "$n" "REDACTED-STRICT"
      scan="${scan/${BASH_REMATCH[0]}/ }"
    done
  fi
}

# --- driver ------------------------------------------------------------

scan_stream() {
  local f="$1"
  local n=0
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n + 1))
    check_email "$line" "$n" "$f"
    check_ssn "$line" "$n" "$f"
    check_credit_card "$line" "$n" "$f"
    check_stripe_key "$line" "$n" "$f"
    check_openai_key "$line" "$n" "$f"
    check_generic_api_key "$line" "$n" "$f"
    check_github_token "$line" "$n" "$f"
    check_aws_access_key_id "$line" "$n" "$f"
    check_aws_secret_key "$line" "$n" "$f"
    check_private_key_header "$line" "$n" "$f"
    check_password_assignment "$line" "$n" "$f"
    check_jwt "$line" "$n" "$f"
    check_ipv4 "$line" "$n" "$f"
    check_phone "$line" "$n" "$f"
    check_bare_uuid "$line" "$n" "$f"
    check_slack "$line" "$n" "$f"
    check_google_api_key "$line" "$n" "$f"
    check_anthropic_key "$line" "$n" "$f"
    check_gitlab_pat "$line" "$n" "$f"
    check_npm_token "$line" "$n" "$f"
    check_sendgrid "$line" "$n" "$f"
    check_private_key_filename "$line" "$n" "$f"
    check_personal_identifiers "$line" "$n" "$f"
  done
}

# Recurse a directory, skipping .git/, node_modules/, and this scanner's own
# self-test fixtures (so a planted fixture never fails a repo-wide scan).
#
# The two secret-scanners themselves (scan-secrets.sh, pii-scan.sh) are
# EXCLUDED: they are detection tooling that necessarily embeds every pattern
# it hunts for (regex literals + synthetic --selftest fixtures like "REDACTED",
# "sk-...FAKE", a "/Users/...one" sample path). Scanning them means the gate
# can never go green on an otherwise-clean repo, which would make install.sh's
# preflight abort on a fresh clone. A real secret has no legitimate reason to
# live inside a scanner's source, so this exclusion is safe. (gitleaks/
# trufflehog exclude their own configs for the same reason.)
scan_dir() {
  local root="$1"
  local file
  while IFS= read -r file; do
    [[ -r "$file" ]] || continue
    scan_stream "$file" < "$file"
  done < <(find "$root" \
      \( -name .git -o -name node_modules \) -prune -o \
      -type f \
      ! -name '*.selftest' \
      ! -path '*scan-secrets-selftest*' \
      ! -name 'scan-secrets.sh' \
      ! -name 'pii-scan.sh' \
      -print 2>/dev/null)
}

run_scan() {
  local target="$1"
  FINDING_COUNT=0
  if [[ "$target" == "-" ]]; then
    scan_stream "(stdin)"
  elif [[ -d "$target" ]]; then
    scan_dir "$target"
  elif [[ -f "$target" ]]; then
    if [[ ! -r "$target" ]]; then
      printf '%s: cannot read file: %s\n' "$SCRIPT_NAME" "$target" >&2
      return 2
    fi
    scan_stream "$target" < "$target"
  else
    printf '%s: no such file or directory: %s\n' "$SCRIPT_NAME" "$target" >&2
    return 2
  fi

  if (( FINDING_COUNT == 0 )); then
    printf 'scan-secrets: clean, no findings\n'
    return 0
  fi
  printf 'scan-secrets: %d finding(s) - GATE FAILURE (nothing may be committed/pushed)\n' "$FINDING_COUNT"
  return 1
}

# --- selftest ------------------------------------------------------------
# Plants one synthetic instance of EACH new pattern (plus the ported ones),
# confirms the scanner flags each category and exits 1, confirms placeholders
# in the allowlist pass, and confirms a clean file exits 0. Every value is
# synthetic - wrong shape/length or a documentation sample, never a working
# credential.
selftest() {
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/scan-secrets-selftest.XXXXXX")"
  trap 'rm -f "$tmp"' RETURN

  cat > "$tmp" <<'SAMPLES'
Contact: jane.doe@sample-mail.net for details.
SSN on file: 219-09-9999
Card on file: 4111-1111-1111-1112
stripe: STRIPE_KEY_FIXTURE
openai: sk-proj-A0000000000000000abcdEFGHijkl
generic key: sk-A0000000000000000abcdEF
github: ghp_A0000000000000000abcdEFGHijkl
github_pat: github_pat_A0000000000000000abcd
aws id: AKIA0000000000000A99
aws_secret_key = "A0000000000000000abcdEFGHijklMNOPqrstUVW9"
-----BEGIN RSA PRIVATE KEY-----
password: hunter2synthetic
jwt: JWT_FIXTURE
server ip 10.20.30.41 responded
call me at 415-555-0182
uuid here 12345678-90ab-cdef-1234-567890abcdef done
projectId=abcdabcd-1111-2222-3333
slack tok SLACK_TOKEN_FIXTURE
slack hook https://hooks.slack.com/services/T00000000/B00000000/A0000000000000000abcd
google key AIzaSyA0000000000000000000000000000000z
anthropic sk-ant-A0000000000000000abcdEF
gitlab glpat-A0000000000000000abcd
npm npm_A00000000000000000000000000000000000
sendgrid SG.A000000000000000000000.A0000000000000000000000000000000000000000000
personal handle HANDLE_TOKEN wrote this
home path /Users/someone/project/file.txt
company COMPANY_A_TOKEN ships payments
company COMPANY_B_TOKEN builds things
key file deploy_id_rsa and cert.pem and store.p12
SAMPLES
  # The self-test file names are placeholders; substitute the real literals so
  # the scanner (not this source) is what carries them, keeping this file clean.
  local sed_i=(-i '')
  case "$(uname -s)" in Linux) sed_i=(-i) ;; esac
  local slack_token_fixture="xoxb"'-0000000000-0000000000-A0000000000000000abcd'
  local stripe_key_fixture="sk_"'test_A0000000000000000A99z'
  local jwt_fixture='eyJhbGciOiJIUzI1NiJ9.'"eyJzdWIiOiIwMDAwIn0"'.A0000000sigA0000000sig'
  sed "${sed_i[@]}" \
    -e "s/SLACK_TOKEN_FIXTURE/${slack_token_fixture}/" \
    -e "s/STRIPE_KEY_FIXTURE/${stripe_key_fixture}/" \
    -e "s/JWT_FIXTURE/${jwt_fixture}/" \
    -e 's/HANDLE_TOKEN/Hamoodey/' \
    -e 's/COMPANY_A_TOKEN/Liberty Pay/' \
    -e 's/COMPANY_B_TOKEN/Together Tech/' \
    "$tmp"

  local out status
  out="$(run_scan "$tmp" 2>&1)"
  status=$?

  local pass=1
  local expect_categories=(
    "email" "us-ssn" "credit-card-like" "stripe-key" "openai-key"
    "generic-api-key" "github-token" "aws-access-key-id"
    "aws-secret-access-key" "private-key-header" "password-assignment"
    "jwt" "ipv4" "phone-us"
    "bare-uuid-projectid" "projectid-assignment" "slack-token"
    "slack-webhook" "google-api-key" "anthropic-key" "gitlab-pat"
    "npm-token" "sendgrid-key" "personal-identifier" "home-path"
    "company-identifier" "private-key-filename"
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
    "${stripe_key_fixture}"
    "sk-proj-A0000000000000000abcdEFGHijkl"
    "ghp_A0000000000000000abcdEFGHijkl"
    "12345678-90ab-cdef-1234-567890abcdef"
    "${slack_token_fixture}"
    "AIzaSyA0000000000000000000000000000000z"
    "sk-ant-A0000000000000000abcdEF"
  )
  for secret in "${raw_secrets[@]}"; do
    if printf '%s' "$out" | grep -qF -- "$secret"; then
      printf '  [FAIL] raw secret leaked in output: %.12s...\n' "$secret"
      pass=0
    else
      printf '  [ok]   redacted: %.12s...\n' "$secret"
    fi
  done

  echo "== selftest: exit code (dirty file must gate-fail with 1) =="
  if (( status == 1 )); then
    printf '  [ok]   exit code 1\n'
  else
    printf '  [FAIL] expected exit code 1, got %d\n' "$status"
    pass=0
  fi

  echo "== selftest: allowlist (placeholders / docs samples must NOT flag) =="
  local allow_tmp
  allow_tmp="$(mktemp "${TMPDIR:-/tmp}/scan-secrets-selftest-allow.XXXXXX")"
  cat > "$allow_tmp" <<'ALLOWED'
key: ${OPENAI_API_KEY}
exa: ${EXA_API_KEY}
placeholder: <YOUR_KEY>
docs sample aws AKIAFAKE1234567890AB
docs sample openai sk-proj-FAKE1234567890abcdEFGH
host https://api.example.com/v1
projectId=${SUPABASE_PROJECT_ID}
ALLOWED
  local allow_out allow_status
  allow_out="$(run_scan "$allow_tmp" 2>&1)"
  allow_status=$?
  rm -f "$allow_tmp"
  if (( allow_status == 0 )); then
    printf '  [ok]   placeholders/docs samples pass clean (exit 0)\n'
  else
    printf '  [FAIL] allowlisted file gate-failed (exit %d):\n%s\n' "$allow_status" "$allow_out"
    pass=0
  fi

  echo "== selftest: false-positive control (clean file exits 0) =="
  local clean_tmp
  clean_tmp="$(mktemp "${TMPDIR:-/tmp}/scan-secrets-selftest-clean.XXXXXX")"
  printf 'just a normal line of prose with no secrets in it.\nanother clean line about coding agents.\n' > "$clean_tmp"
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
  fi
  echo "SELFTEST RESULT: FAIL"
  return 1
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
    --strict)
      STRICT=1
      shift
      if [[ $# -eq 0 ]]; then
        run_scan "-"
      else
        run_scan "$1"
      fi
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

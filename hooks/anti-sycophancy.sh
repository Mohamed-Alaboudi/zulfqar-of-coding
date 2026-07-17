#!/usr/bin/env bash
# anti-sycophancy.sh
# UserPromptSubmit hook: reimplementation of the 0xcjl/anti-sycophancy pattern
# (see THIRD-PARTY-NOTICES.md). Scope is narrow on purpose: only fire when the
# prompt is phrased as SEEKING CONFIRMATION of an assertion (loaded/leading
# phrasing), and only then inject a short reframing note telling the model to
# judge the claim on its merits instead of the framing. Silent on every other
# turn. Fail-open always: any error (no jq, empty stdin, bad JSON) -> emit
# nothing, exit 0.
#
# Portable pattern from the Zulfqar of Coding toolkit.

# Confirmation-seeking patterns to scan for (case-insensitive, extended regex).
# Keep this list readable; add/remove one phrase per line inside the group.
PATTERNS=(
  "right\?"
  "isn'?t it"
  "don'?t you think"
  "yeah\?"
  "correct\?"
  "am i right"
  "wouldn'?t you (say|agree)"
  "that'?s better,? right"
  "this is the best,? (right|isn'?t it|option|choice|approach|way|one)"
  "i'?m sure .* right"
  "would you agree"
  "you'?d agree"
  "surely,? (right|you|it|that|i'?m)"
  "obviously (true|right|correct)"
)

# Join into one alternation for a single grep -E pass.
regex="$(IFS='|'; echo "${PATTERNS[*]}")"

input="$(cat 2>/dev/null)" || exit 0
[ -z "$input" ] && exit 0

prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)" || exit 0
[ -z "$prompt" ] && exit 0

printf '%s' "$prompt" | grep -qiE "$regex" 2>/dev/null || exit 0

note="[Epistemic-honesty guard] The user's message is phrased as seeking confirmation. "
note+="Evaluate the underlying claim on its merits from facts/logic/research, not on the "
note+="confirmation-seeking framing. Hear the point fully and steelman it first. If the "
note+="user is RIGHT, say so plainly and move on (do not manufacture disagreement). If "
note+="wrong or unknown, say that with the reason."

jq -cn --arg c "$note" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}' 2>/dev/null || exit 0
exit 0

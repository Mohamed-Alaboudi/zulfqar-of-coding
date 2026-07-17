#!/usr/bin/env bash
# inject-core-rules.sh
# SessionStart hook: deterministically inject a project's non-negotiable core
# rules into the model's context at the start of every session.
#
# WHY THIS EXISTS
#   A CLAUDE.md / AGENTS.md instruction file is SOFT: models reliably follow
#   only ~150-200 instructions, and a rule buried in a long file gets diluted
#   away. A SessionStart hook that returns additionalContext injects the rules
#   that must NEVER fail directly into the working context, where they cannot
#   be diluted. Keep this TINY - only the handful of rules you cannot afford to
#   have the model forget.
#
# HOW TO USE
#   Edit the CORE_RULES below to your project's real must-never-fail rules.
#   The example rules shipped here are generic and safe to adapt. Fail-open:
#   any error -> emit nothing, session proceeds normally.
#
# Portable pattern from the Zulfqar of Coding toolkit. See the README beside
# this file for how to reimplement for Codex / Gemini CLI.
set -euo pipefail

input="$(cat)"
# The model id is available if you want to branch rules per-model; unused in
# this generic example but left wired so adopters can switch on it.
model="$(printf '%s' "$input" | jq -r '.model // empty' 2>/dev/null || true)"
: "${model:=}"

# ---- EDIT THIS: your project's must-never-fail rules ----
ctx="NON-NEGOTIABLE CORE RULES (hook-injected, deterministic): "
ctx+="(1) Never print, log, or commit secrets, keys, tokens, or .env files. "
ctx+="(2) Use \${ENV_VAR} or <YOUR_KEY> placeholders for anything credential-shaped - never a literal value. "
ctx+="(3) Do not force-push to a protected branch (main/master); branch first. "
ctx+="(4) Epistemic honesty: understand an approach fully and steelman it before critiquing; reason from facts and logic; separate verified / assumed / unknown in plain prose; if the user is right, say so plainly and move on. "
ctx+="(5) Build lean: climb the ladder (does it need to exist -> already here -> stdlib -> one line -> minimum that works); deletion over addition, shortest working diff."

jq -cn --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}' 2>/dev/null || exit 0
exit 0

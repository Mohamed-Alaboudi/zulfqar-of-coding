#!/usr/bin/env python3
"""Audit structured skill invocations from explicit skill and transcript paths."""

import argparse
import collections
import json
import re
import sys
import time
from pathlib import Path


COMMAND_PATTERN = re.compile(
    r"<command-name>/?([a-zA-Z0-9:_-]+)</command-name>"
)


def installed_skills(skills_dir):
    if not skills_dir.is_dir():
        raise ValueError(f"skill directory does not exist: {skills_dir}")
    return {
        child.name
        for child in skills_dir.iterdir()
        if child.is_dir() and (child / "SKILL.md").is_file()
    }


def transcript_paths(transcripts_dir, days):
    if not transcripts_dir.is_dir():
        raise ValueError(
            f"transcript directory does not exist: {transcripts_dir}"
        )
    cutoff = time.time() - days * 86400 if days is not None else None
    for path in sorted(transcripts_dir.rglob("*.jsonl")):
        if cutoff is not None and path.stat().st_mtime < cutoff:
            continue
        yield path


def content_items(record):
    message = record.get("message")
    if isinstance(message, dict):
        content = message.get("content")
        role = message.get("role") or record.get("role") or record.get("type")
    else:
        content = record.get("content")
        role = record.get("role") or record.get("type")
    if isinstance(content, str):
        return role, [{"type": "text", "text": content}]
    if isinstance(content, list):
        return role, [item for item in content if isinstance(item, dict)]
    return role, []


def scan(transcripts_dir, days):
    tool_counts = collections.Counter()
    typed_counts = collections.Counter()
    files_scanned = 0
    malformed_lines = 0

    for path in transcript_paths(transcripts_dir, days):
        files_scanned += 1
        with path.open(encoding="utf-8", errors="replace") as handle:
            for raw in handle:
                try:
                    record = json.loads(raw)
                except (json.JSONDecodeError, ValueError):
                    malformed_lines += 1
                    continue
                if not isinstance(record, dict):
                    continue
                role, items = content_items(record)
                for item in items:
                    if (
                        item.get("type") == "tool_use"
                        and item.get("name") == "Skill"
                    ):
                        tool_input = item.get("input") or {}
                        raw_name = str(tool_input.get("skill", ""))
                        name = raw_name.split(":")[-1]
                        if name:
                            tool_counts[name] += 1
                    if role == "user" and item.get("type") == "text":
                        text = item.get("text") or ""
                        for raw_name in COMMAND_PATTERN.findall(text):
                            typed_counts[raw_name.split(":")[-1]] += 1
    return tool_counts, typed_counts, files_scanned, malformed_lines


def build_audit(skills, tool_counts, typed_counts, files_scanned, malformed):
    counts = {
        skill: tool_counts.get(skill, 0) + typed_counts.get(skill, 0)
        for skill in sorted(skills)
    }
    observed = tool_counts + typed_counts
    ghosts = {
        skill: count
        for skill, count in sorted(observed.items())
        if skill not in skills
    }
    return {
        "files_scanned": files_scanned,
        "malformed_lines": malformed,
        "installed": len(skills),
        "counts": counts,
        "tool_counts": {
            skill: tool_counts.get(skill, 0) for skill in sorted(skills)
        },
        "typed_counts": {
            skill: typed_counts.get(skill, 0) for skill in sorted(skills)
        },
        "never_fired": [
            skill for skill, count in counts.items() if count == 0
        ],
        "ghost_invocations": ghosts,
    }


def format_text(audit):
    lines = [
        "=== SKILL USAGE AUDIT ===",
        f"transcripts scanned: {audit['files_scanned']}   "
        f"installed skills: {audit['installed']}   "
        f"malformed lines: {audit['malformed_lines']}",
        "",
        "--- OBSERVED ---",
    ]
    observed = [
        (count, skill)
        for skill, count in audit["counts"].items()
        if count > 0
    ]
    for count, skill in sorted(observed, reverse=True):
        lines.append(f"{count:5d}  {skill}")
    if not observed:
        lines.append("       none")

    lines.extend(["", "--- NEVER FIRED ---"])
    lines.extend(f"       {skill}" for skill in audit["never_fired"])
    if not audit["never_fired"]:
        lines.append("       none")

    if audit["ghost_invocations"]:
        lines.extend(["", "--- GHOST INVOCATIONS ---"])
        for skill, count in audit["ghost_invocations"].items():
            lines.append(f"{count:5d}  {skill}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--skills-dir", required=True, type=Path)
    parser.add_argument("--transcripts-dir", required=True, type=Path)
    parser.add_argument("--days", type=int)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if args.days is not None and args.days < 1:
        parser.error("--days must be at least 1")

    try:
        skills = installed_skills(args.skills_dir)
        tool, typed, files, malformed = scan(
            args.transcripts_dir, args.days
        )
        audit = build_audit(skills, tool, typed, files, malformed)
        content = (
            json.dumps(audit, indent=2)
            if args.json
            else format_text(audit)
        )
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(content + "\n", encoding="utf-8")
        else:
            print(content)
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

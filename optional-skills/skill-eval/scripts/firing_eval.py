#!/usr/bin/env python3
"""Build and score skill-routing evaluation packets from explicit case paths."""

import argparse
import json
import sys
from pathlib import Path


def parse_case(path):
    """Parse the small YAML subset used by the bundled routing cases."""
    skill = None
    section = None
    prompts = {"should_fire": [], "must_not_fire": []}

    with path.open(encoding="utf-8") as handle:
        for line_number, raw in enumerate(handle, start=1):
            stripped = raw.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if stripped.startswith("- "):
                if section not in prompts:
                    raise ValueError(f"{path}:{line_number}: list item has no section")
                item = stripped[2:].strip()
                if item[:1] in {"'", '"'} and item[-1:] == item[:1]:
                    item = item[1:-1]
                if not item:
                    raise ValueError(f"{path}:{line_number}: empty prompt")
                prompts[section].append(item)
                continue
            key, separator, value = stripped.partition(":")
            if not separator:
                raise ValueError(f"{path}:{line_number}: unsupported case syntax")
            key = key.strip()
            value = value.strip()
            if key == "skill":
                skill = value
                section = None
            elif key in prompts:
                section = key
            else:
                raise ValueError(f"{path}:{line_number}: unsupported key {key!r}")

    if not skill:
        raise ValueError(f"{path}: missing skill")
    if not prompts["should_fire"]:
        raise ValueError(f"{path}: missing should_fire prompts")
    if not prompts["must_not_fire"]:
        raise ValueError(f"{path}: missing must_not_fire prompts")
    return {"skill": skill, **prompts}


def load_cases(cases_dir):
    if not cases_dir.is_dir():
        raise ValueError(f"case directory does not exist: {cases_dir}")
    paths = sorted(cases_dir.glob("*.yaml"))
    if not paths:
        raise ValueError(f"no case files in {cases_dir}")
    cases = [parse_case(path) for path in paths]
    names = [case["skill"] for case in cases]
    duplicates = sorted({name for name in names if names.count(name) > 1})
    if duplicates:
        raise ValueError(f"duplicate skill cases: {', '.join(duplicates)}")
    return cases


def build_packets(cases):
    packets = []
    for case in cases:
        for expectation in ("should_fire", "must_not_fire"):
            for prompt in case[expectation]:
                packets.append(
                    {
                        "skill": case["skill"],
                        "expect": expectation,
                        "prompt": prompt,
                    }
                )
    return packets


def load_results(path):
    with path.open(encoding="utf-8") as handle:
        results = json.load(handle)
    if not isinstance(results, list):
        raise ValueError("results must be a JSON array")
    required = {"skill", "expect", "prompt", "fired"}
    for index, result in enumerate(results):
        if not isinstance(result, dict) or not required.issubset(result):
            raise ValueError(f"result {index} must contain {sorted(required)}")
        if result["expect"] not in {"should_fire", "must_not_fire"}:
            raise ValueError(f"result {index} has an invalid expectation")
    return results


def score(results, cases):
    known = {case["skill"] for case in cases}
    rows = {
        skill: {
            "skill": skill,
            "tp": 0,
            "fn": 0,
            "fp": 0,
            "tn": 0,
            "misses": [],
            "overfires": [],
        }
        for skill in known
    }

    for result in results:
        skill = result["skill"]
        if skill not in rows:
            raise ValueError(f"result references unknown skill {skill!r}")
        fired = result["fired"] or "none"
        row = rows[skill]
        if result["expect"] == "should_fire":
            if fired == skill:
                row["tp"] += 1
            else:
                row["fn"] += 1
                row["misses"].append(
                    {"prompt": result["prompt"], "fired": fired}
                )
        elif fired == skill:
            row["fp"] += 1
            row["overfires"].append({"prompt": result["prompt"]})
        else:
            row["tn"] += 1

    scored = []
    for skill in sorted(rows):
        row = rows[skill]
        positive_count = row["tp"] + row["fn"]
        recall = row["tp"] / positive_count if positive_count else None
        selected_count = row["tp"] + row["fp"]
        precision = row["tp"] / selected_count if selected_count else None
        if recall is None:
            verdict = "NO RESULTS"
        elif recall == 0:
            verdict = "DEAD"
        elif row["fp"] and recall < 0.6:
            verdict = "BROKEN"
        elif row["fp"]:
            verdict = "OVER-FIRES"
        elif recall < 0.6:
            verdict = "WEAK"
        elif recall < 0.9:
            verdict = "OK"
        else:
            verdict = "GOOD"
        scored.append(
            {
                **row,
                "recall": recall,
                "precision": precision,
                "verdict": verdict,
            }
        )
    return scored


def format_listing(cases):
    should_count = sum(len(case["should_fire"]) for case in cases)
    must_not_count = sum(len(case["must_not_fire"]) for case in cases)
    lines = [
        f"{len(cases)} skills | {should_count} should-fire | "
        f"{must_not_count} must-not-fire | {should_count + must_not_count} dispatches"
    ]
    for case in cases:
        lines.append(
            f"  {case['skill']:28} should={len(case['should_fire']):2d} "
            f"must_not={len(case['must_not_fire']):2d}"
        )
    return "\n".join(lines)


def format_scores(rows):
    lines = [f"{'skill':28} {'recall':>7} {'prec':>7}  verdict", "-" * 62]
    for row in rows:
        recall = (
            f"{row['recall']:.0%}" if row["recall"] is not None else "-"
        )
        precision = (
            f"{row['precision']:.0%}" if row["precision"] is not None else "-"
        )
        lines.append(
            f"{row['skill']:28} {recall:>7} {precision:>7}  {row['verdict']}"
        )
    return "\n".join(lines)


def emit(content, output):
    if output:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(content + "\n", encoding="utf-8")
    else:
        print(content)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cases-dir", required=True, type=Path)
    operation = parser.add_mutually_exclusive_group(required=True)
    operation.add_argument("--list", action="store_true")
    operation.add_argument("--packets", action="store_true")
    operation.add_argument("--score", type=Path, metavar="RESULTS_JSON")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    try:
        cases = load_cases(args.cases_dir)
        if args.list:
            emit(format_listing(cases), args.output)
        elif args.packets:
            emit(json.dumps(build_packets(cases), indent=2), args.output)
        else:
            rows = score(load_results(args.score), cases)
            content = (
                json.dumps(rows, indent=2)
                if args.output
                else format_scores(rows)
            )
            emit(content, args.output)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

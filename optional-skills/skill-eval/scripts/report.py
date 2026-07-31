#!/usr/bin/env python3
"""Render skill-routing results as a compact Markdown report."""

import argparse
import collections
import json
import sys
from pathlib import Path


def verdict(recall, false_positives):
    if recall == 0:
        return "DEAD"
    if false_positives and recall < 0.6:
        return "BROKEN"
    if false_positives:
        return "OVER-FIRES"
    if recall < 0.6:
        return "WEAK"
    if recall < 0.9:
        return "OK"
    return "GOOD"


def build_report(results, title):
    aggregate = collections.defaultdict(
        lambda: {"tp": 0, "fn": 0, "fp": 0, "tn": 0, "misses": [], "overfires": []}
    )
    for result in results:
        skill = result["skill"]
        fired = result.get("fired") or "none"
        row = aggregate[skill]
        if result["expect"] == "should_fire":
            if fired == skill:
                row["tp"] += 1
            else:
                row["fn"] += 1
                row["misses"].append((result["prompt"], fired))
        elif fired == skill:
            row["fp"] += 1
            row["overfires"].append(result["prompt"])
        else:
            row["tn"] += 1

    rows = []
    for skill, row in aggregate.items():
        positive_count = row["tp"] + row["fn"]
        recall = row["tp"] / positive_count if positive_count else 0.0
        selected_count = row["tp"] + row["fp"]
        precision = row["tp"] / selected_count if selected_count else 0.0
        rows.append(
            (skill, recall, precision, verdict(recall, row["fp"]), row)
        )
    rows.sort(key=lambda row: row[0])

    total_tp = sum(row["tp"] for row in aggregate.values())
    total_fn = sum(row["fn"] for row in aggregate.values())
    total_fp = sum(row["fp"] for row in aggregate.values())
    total_tn = sum(row["tn"] for row in aggregate.values())
    recall_denominator = total_tp + total_fn
    precision_denominator = total_tp + total_fp
    total_recall = total_tp / recall_denominator if recall_denominator else 0.0
    total_precision = total_tp / precision_denominator if precision_denominator else 0.0

    output = [
        f"# {title}",
        "",
        "| Skill | Recall | Precision | Verdict |",
        "|---|---:|---:|---|",
    ]
    for skill, recall, precision, row_verdict, _row in rows:
        output.append(
            f"| `{skill}` | {recall:.0%} | {precision:.0%} | {row_verdict} |"
        )
    output.extend(
        [
            "",
            "## Summary",
            "",
            f"- Skills evaluated: {len(rows)}",
            f"- Cases: {len(results)} "
            f"({recall_denominator} should-fire / {total_fp + total_tn} must-not-fire)",
            f"- Recall: {total_recall:.0%} ({total_tp}/{recall_denominator})",
            f"- Precision: {total_precision:.0%} "
            f"({total_tp}/{precision_denominator})",
        ]
    )

    problem_rows = [row for row in rows if row[3] != "GOOD"]
    if problem_rows:
        output.extend(["", "## Findings", ""])
        for skill, _recall, _precision, row_verdict, row in problem_rows:
            output.append(f"### {skill}: {row_verdict}")
            output.append("")
            for prompt, fired in row["misses"]:
                output.append(f"- Missed `{prompt}`; selected `{fired}`.")
            for prompt in row["overfires"]:
                output.append(f"- Over-fired on `{prompt}`.")
            if not row["misses"] and not row["overfires"]:
                output.append("- No evaluated positive result.")
            output.append("")
    return "\n".join(output).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("results", type=Path)
    parser.add_argument("--title", default="Skill routing evaluation")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    try:
        with args.results.open(encoding="utf-8") as handle:
            results = json.load(handle)
        if not isinstance(results, list):
            raise ValueError("results must be a JSON array")
        report = build_report(results, args.title)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(report, encoding="utf-8")
        else:
            print(report, end="")
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

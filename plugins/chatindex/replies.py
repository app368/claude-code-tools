#!/usr/bin/env python3
"""Dumps the human's turns from a Claude Code session log.

Useful when closing out a session: the list shows every topic that came up, so
none goes missing. Memory loses topics — that is the observation this came from.

The log is found from the current directory: Claude Code stores it under
~/.claude/projects/<project-path-with-dashes>/<session-id>.jsonl

Usage:
    ./replies.py                  latest session of the current project
    ./replies.py --list           which sessions exist
    ./replies.py --session ID     a specific session
    ./replies.py --full           full text instead of the opening fragment
    ./replies.py --width 400      length of the shown fragment
    ./replies.py --project PATH   another project
"""

import argparse
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path

# Marks of service records: written by the interface, not by the human
SERVICE_MARKERS = (
    "[Request interrupted by user]",
    "<command-name>",
    "<command-message>",
    "<local-command-caveat>",
    "<local-command-stdout>",
    "Caveat: The messages below were generated",
    "This session is being continued from a previous conversation",
    "Base directory for this skill:",
)

# Housekeeping turns: they authorize something already decided and don't belong
# in a session index. Edit this list to match your own habits and language.
ORG_WORDS = (
    "commit",
    "merge",
    "push",
    "rebase",
    "squash",
)


def project_slug(path: Path) -> str:
    """Log directory name: slashes and spaces in the project path become dashes."""
    return re.sub(r"[/ ]", "-", str(path))


def find_project_dir(project: Path) -> Path:
    base = Path.home() / ".claude" / "projects"
    candidate = base / project_slug(project)
    if candidate.is_dir():
        return candidate
    sys.exit(
        f"No log directory for this project: {candidate}\n"
        f"Run this from the project directory, or pass --project."
    )


def sessions(project_dir: Path):
    """Session files, newest first."""
    files = sorted(project_dir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not files:
        sys.exit(f"No session logs in {project_dir}.")
    return files


def is_service(text: str) -> bool:
    return any(marker in text for marker in SERVICE_MARKERS)


def is_org(text: str) -> bool:
    low = text.lower()
    return any(word in low for word in ORG_WORDS)


def read_replies(path: Path):
    """The human's turns: no tool results, no service records."""
    out = []
    with path.open() as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if row.get("type") != "user" or not row.get("timestamp"):
                continue

            content = (row.get("message") or {}).get("content")
            text, from_tool = "", False
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    if block.get("type") == "tool_result":
                        from_tool = True
                    elif block.get("type") == "text":
                        text += block.get("text", "")
            elif isinstance(content, str):
                text = content

            if from_tool or not text.strip():
                continue

            stamp = dt.datetime.fromisoformat(row["timestamp"].replace("Z", "+00:00"))
            out.append((stamp.astimezone(), " ".join(text.split())))
    out.sort()
    return out


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--project", default=os.getcwd(), help="project directory")
    parser.add_argument("--session", help="session id")
    parser.add_argument("--list", action="store_true", help="list sessions")
    parser.add_argument("--full", action="store_true", help="full text of each turn")
    parser.add_argument("--width", type=int, default=230, help="fragment length")
    args = parser.parse_args()

    project_dir = find_project_dir(Path(args.project).resolve())
    files = sessions(project_dir)

    if args.list:
        for path in files:
            when = dt.datetime.fromtimestamp(path.stat().st_mtime)
            size = path.stat().st_size / 1_000_000
            print(f"{path.stem}  {when:%d.%m.%Y %H:%M}  {size:5.1f} MB")
        return

    if args.session:
        chosen = project_dir / f"{args.session}.jsonl"
        if not chosen.exists():
            sys.exit(f"No such session: {chosen}")
    else:
        chosen = files[0]

    rows = read_replies(chosen)
    service = [t for _, t in rows if is_service(t)]
    real = [(s, t) for s, t in rows if not is_service(t)]
    org = [t for _, t in real if is_org(t)]

    print(f"Session: {chosen.stem}")
    if real:
        print(f"Span: {real[0][0]:%d.%m.%Y %H:%M} — {real[-1][0]:%d.%m.%Y %H:%M}")
    print(f"Turns: {len(real)}   service records dropped: {len(service)}   "
          f"marked housekeeping: {len(org)}")
    print()

    for number, (stamp, text) in enumerate(real, 1):
        mark = " [hk]" if is_org(text) else ""
        body = text if args.full else text[:args.width]
        print(f"[{number:03d}] {stamp:%d.%m %H:%M}{mark} | {body}")


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        # Output was cut short — piped into head, for instance.
        # Not an error, but Python would print a traceback otherwise
        os.dup2(os.open(os.devnull, os.O_WRONLY), sys.stdout.fileno())
        sys.exit(0)
    except KeyboardInterrupt:
        sys.exit(1)

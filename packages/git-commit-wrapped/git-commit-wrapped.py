#!/usr/bin/env python3
import re
import subprocess
import sys
import tempfile


MAX_TITLE_LEN = 50
WRAP_WIDTH = 72

HELP = """usage:
  git commit-wrapped [--amend] [--dry-run] "area: title" "commit body..."

For agents:
  1. Stage only the files for the completed task.
  2. Run this command instead of git commit -m, printf, heredocs, or manual wrapping.
  3. Pass the body as plain text. Do not split lines manually.
  4. The title is lowercased automatically.
  5. If the title is too long, shorten it and run the command again.

Examples:
  git commit-wrapped "docs: require pre-tag review" \\
    "Document the review requirement before release tags. The script wraps this body automatically."

  git commit-wrapped --amend "matching: fix candidate ordering" \\
    "Preserve deterministic ordering when two candidates have equal rank."
"""


def normalize_title(title):
    return re.sub(r"\s+", " ", title.strip()).lower()


def is_bullet(line):
    return re.match(r"^(\s*)([-*+]|\d+[.)])\s+(.+)$", line)


def wrap_words(text, width, initial_prefix="", subsequent_prefix=""):
    words = text.split()
    if not words:
        return []

    lines = []
    current = initial_prefix
    current_has_word = False

    for word in words:
        prefix = "" if current_has_word else current
        candidate = f"{current} {word}" if current_has_word else f"{prefix}{word}"

        if current_has_word and len(candidate) > width:
            lines.append(current)
            current = subsequent_prefix
            current_has_word = False

        if not current_has_word:
            current = f"{current}{word}"
            current_has_word = True
        else:
            current = f"{current} {word}"

    if current_has_word:
        lines.append(current)

    return lines


def wrap_paragraph(paragraph):
    raw_lines = paragraph.splitlines()
    non_empty = [line for line in raw_lines if line.strip()]
    if not non_empty:
        return []

    if len(non_empty) > 1:
        wrapped = []
        for line in raw_lines:
            if not line.strip():
                wrapped.append("")
                continue
            wrapped.extend(wrap_line(line))
        return wrapped

    return wrap_line(non_empty[0])


def wrap_line(line):
    stripped = line.strip()
    bullet = is_bullet(stripped)
    if bullet:
        marker = bullet.group(2)
        content = bullet.group(3)
        prefix = f"{marker} "
        return wrap_words(content, WRAP_WIDTH, prefix, "  ")

    return wrap_words(stripped, WRAP_WIDTH)


def build_message(title, paragraphs):
    body_lines = []
    for paragraph in paragraphs:
        wrapped = wrap_paragraph(paragraph)
        if not wrapped:
            continue
        if body_lines:
            body_lines.append("")
        body_lines.extend(wrapped)

    if body_lines:
        return title + "\n\n" + "\n".join(body_lines) + "\n"
    return title + "\n"


def parse_args(argv):
    amend = False
    dry_run = False
    positional = []

    for arg in argv:
        if arg in ("--help", "-h"):
            print(HELP, end="")
            raise SystemExit(0)
        if arg == "--amend":
            amend = True
            continue
        if arg == "--dry-run":
            dry_run = True
            continue
        if arg.startswith("--"):
            print(f"error: unknown option: {arg}", file=sys.stderr)
            print('usage: git commit-wrapped [--amend] [--dry-run] "area: title" "commit body..."', file=sys.stderr)
            raise SystemExit(2)
        positional.append(arg)

    if not positional:
        print("error: missing commit title", file=sys.stderr)
        print('usage: git commit-wrapped [--amend] [--dry-run] "area: title" "commit body..."', file=sys.stderr)
        raise SystemExit(2)

    return amend, dry_run, positional[0], positional[1:]


def validate_title(title):
    if len(title) <= MAX_TITLE_LEN:
        return

    print(
        f"error: commit title is {len(title)} characters after normalization; max is {MAX_TITLE_LEN}\n",
        file=sys.stderr,
    )
    print("Use: area: short title", file=sys.stderr)
    print("Example: persistence: fix stale lease recovery", file=sys.stderr)
    raise SystemExit(1)


def main(argv):
    amend, dry_run, raw_title, paragraphs = parse_args(argv)
    title = normalize_title(raw_title)
    validate_title(title)
    message = build_message(title, paragraphs)

    if dry_run:
        print(message, end="")
        return 0

    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=True) as tmp:
        tmp.write(message)
        tmp.flush()

        command = ["git", "commit"]
        if amend:
            command.append("--amend")
        command.extend(["-F", tmp.name])
        return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

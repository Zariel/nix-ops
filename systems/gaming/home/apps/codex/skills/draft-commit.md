---
name: draft-commit
description: Draft a commit message from repository changes when the user asks for help writing one. Use the repository's active version-control system and established conventions; do not create or amend commits unless explicitly requested.
---

# Draft a commit message

Draft a message for the changes or revisions the user identifies. Keep unrelated
work out of the message, and do not mutate version-control state unless the user
also asks to apply it.

## Gather context

- Read repository guidance and determine the active version-control system. Use
  `jj` when the repository contains `.jj`; otherwise use its native tooling.
- Inspect the exact change being described. Respect distinctions such as staged
  Git changes, the current jj change, or an explicitly selected revision.
- Sample nearby commit messages and documented conventions when needed to learn
  the expected structure, prefixes, scopes, capitalization, and metadata.

## Write the message

- Match established repository style. When none is apparent, use a concise,
  imperative subject that describes the primary intent.
- Add a body only when it provides useful context: why the change exists,
  behavior or compatibility effects, important constraints, or known risks.
- Prefer intent and impact over a file-by-file inventory or implementation
  details that are already clear from the diff.
- Make only claims supported by the change or user-provided context. Include
  issue references, trailers, and validation details only when their exact
  values are known.

## Output

Return only the complete commit message as plain text, without commentary or a
code fence. Do not manually hard-wrap prose; follow repository guidance for
formatting and applying the message.

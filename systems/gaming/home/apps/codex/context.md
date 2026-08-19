# Version Control

- If a repository contains `.jj`, use `jj` instead of `git` for version-control operations.

## When creating commit messages:
- Always provide the message through stdin, never as an escaped multiline
  command-line argument.
- Pipe the complete message through `format-commit-message`.
- Do not manually hard-wrap prose; the formatter does this.

# Solution-space discipline

Optimize for choosing the right problem and ownership model before optimizing
an implementation.

For cheaply reversible implementation decisions, proceed directly.

Before making a decision that is expensive to reverse, first identify the
actual requirement and hard constraints, independently of the current code.

Then explore materially different solution families before selecting one.
In particular consider whether the requirement can be satisfied by:

- removing the mechanism entirely
- delegating responsibility to an existing primitive
- solving the problem at a different layer
- changing the interface so the problem disappears
- deriving state instead of storing or reconciling it
- using a standard mechanism instead of custom machinery

Do not generate alternatives merely for completeness. Explore when the
decision has meaningful cost of reversal or significant uncertainty.

For especially consequential architectural decisions, prefer independent
solution proposals before selecting an approach rather than asking one
proposal to critique itself.

After implementation begins, reopen the architectural decision when new
information materially changes an assumption or complexity grows beyond what
the chosen model predicted.

At that point, do not merely simplify the implementation. Ask whether the
chosen solution family is still correct.

# Design Hygiene

- Don't do more than is necessary
- Use concise naming for function and test names, when needed add comments to add extra context for other reviewers
- Code should be self evident of what it is doing
- Keep the smallest reasonable API surface. Default to package-private types, helpers, and state models unless there is a clear caller outside the package in the current change.
- Return concrete types from constructors. Accept interfaces at call sites where substitution is useful, but do not return interfaces just to hide implementation details.
- Be suspicious of single-use pass-through helpers. If a helper only forwards to one concrete constructor or API and adds no meaningful abstraction, inline it.
- Prefer names that describe the role of a value precisely, especially when distinguishing desired state, actual state, configuration, and runtime state.
- When code performs side effects outside process memory, add a short comment for any non-obvious verification, locking, or ordering constraint.
- Treat naming and visibility review comments as design feedback, not cosmetic feedback. They usually indicate that the code is exposing too much or describing itself imprecisely.
- Keep internal reconciliation or transformation models local to the package unless they are intentionally part of the package API.
- For tests, prefer each test owning one behavior or one direction of conversion. Avoid overlapping round-trip coverage when direct one-way tests are clearer.
- Before finishing a change, do a quick pass over exports, constructor return types, single-use abstractions, naming accuracy, non-obvious invariants, and overlapping tests.

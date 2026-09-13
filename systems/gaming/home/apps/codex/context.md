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

## Repeated failures and responsibility

Repeated code suggests possible reuse. Repeated bugs suggest misplaced responsibility.

Treat repeated failure modes as a design signal. When a test exposes a bug,
identify the violated invariant or incorrect assumption in semantic terms,
rather than describing it only in terms of the affected feature. Before
considering the fix complete, search for other code that implements the same
responsibility, state transition, lifecycle, or assumption.

- If the same failure class has occurred in more than one implementation,
  perform a repository-wide audit and reassess the abstraction boundary before
  continuing with isolated fixes. Independent tests exposing the same failure
  class are stronger evidence for a missing abstraction than similar-looking code.
- If multiple implementations independently enforce the same retry, convergence,
  persistence, ownership, transaction, or error-handling semantics, consider
  moving those semantics behind a shared abstraction.
- Prefer abstractions that make the invariant difficult or impossible for callers
  to violate. Do not merely extract similar control flow into a generic helper
  while leaving the important policy distributed among callers.
- Use repeated failures to identify the abstraction. Do not abstract solely
  because code has similar syntax; similar implementations may legitimately
  have different contracts.
- When introducing the abstraction, add focused tests for its shared contract.
  Retain feature-level tests where they verify integration or reproduce an
  important regression through public behavior.

# Design Hygiene

- Don't do more than is necessary.
- Prefer concise, precise function and test names. A name should distinguish
  the concept within its scope rather than encode its full behavior; use local
  context, subtest names, or comments for supporting detail.
- Code should make what it does self-evident. Comments should explain intent,
  constraints, invariants, or surprising decisions that are true of the current
  code. Do not use comments to explain how the code differs from a previous
  implementation, why an earlier approach was wrong, or to preserve review
  history.
- Keep the smallest reasonable API surface. Default to package-private types,
  helpers, and state models unless there is a clear caller outside the package
  in the current change.
- Return concrete types from constructors. Accept interfaces at call sites
  where substitution is useful, but do not return interfaces just to hide
  implementation details.
- Be suspicious of single-use pass-through helpers. If a helper only forwards
  to one concrete constructor or API and adds no meaningful abstraction,
  inline it.
- Prefer names that describe the role of a value precisely, especially when
  distinguishing desired state, observed state, configuration, and runtime state.
- When code performs side effects outside process memory, add a short comment
  for any non-obvious verification, locking, ordering, idempotency, or
  ownership constraint.
- Treat naming and visibility review comments as design feedback, not cosmetic
  feedback. They usually indicate that the code is exposing too much or
  describing itself imprecisely.
- Keep internal reconciliation or transformation models local to the package
  unless they are intentionally part of the package API.
- Before finishing a change, do a quick pass over exports, constructor return
  types, single-use abstractions, naming accuracy, and non-obvious invariants.
- Use blank lines to separate logical phases within functions and tests, such
  as setup, validation, execution, and independent assertions. Keep closely
  related statements and their error checks together. Prefer spacing over
  extracting helpers solely to shorten a function; extract a helper only when
  it names a coherent operation or removes meaningful repetition.

# Testing

Tests should verify behavior and contracts rather than implementation details. Design tests to falsify specific beliefs about the solution, including beliefs embedded in the test oracle, rather than only confirming examples that agree with the implementation.

For non-trivial behavior, first consider whether the contract is sufficiently understood to encode directly in tests. For system-level, stateful or operator-facing changes, prefer exercising the complete workflow through the real public interface in a representative throwaway environment before reducing the observed behavior to automated tests. Verify resulting state through an independent observation path where practical rather than relying only on the component's own success signal.

* Test the narrowest stable boundary through which the behavior is meaningfully observable.
* A test should have one coherent reason to fail. It may cover multiple representative cases when they exercise the same behavior, invariant, boundary or regression.
* Before writing a non-trivial test, identify at least one plausible incorrect behavior or implementation that the test is intended to distinguish from the correct one. Choose inputs and observations for which those alternatives produce different results.
* Regression tests should reproduce the failure condition and assert the desired outcome. Where practical, confirm that the test would fail without the fix and for the intended reason.
* Treat every expected result as a claim about the contract, not as established truth. Before changing implementation code to satisfy a failing test, validate the oracle against the requirement, an authoritative specification, an independently derived example or observed external behavior. If the expected behavior is uncertain, resolve the requirement rather than encoding the assumption and changing production code to match it.
* Do not duplicate implementation formulas, branching logic or internal algorithms in expected values unless that exact algorithm is itself part of the contract.
* Avoid coupling tests to helper functions, internal state, mock call ordering or exact mechanisms unless those details are contractual.
* Exact values are appropriate only when the exact value is a requirement.
* For rendering and transformation code, prefer direct one-way tests with explicit expected output.
* Do not generate expected values by calling the helper under test or by reproducing the same algorithm through shared implementation helpers.
* Do not rely solely on round-trip tests when direct one-way expectations would expose symmetric defects more clearly.
* When validating externally visible effects, prefer an independent observation path where practical. For example, verify service state through the operating system, persisted configuration through the filesystem or network state through the kernel rather than asking the component under test to report whether its own operation succeeded.
* For stateful workflows, consider what happens after the immediate operation. Repeat the operation, exercise a dependent operation, restart or reload relevant components and verify persistence, convergence and idempotence where those properties are part of the contract.
* A successful return value, CLI exit status or API response is not sufficient evidence that the intended system state was reached unless that signal itself is the contract.

Before adding or accepting a test, ask:

* Could a substantially different but correct implementation still pass this test? If not, the test may be over-coupled.
* Could a plausible incorrect implementation also pass this test? If so, the test may not discriminate the behavior it claims to verify.

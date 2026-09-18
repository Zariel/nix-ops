---
name: technical-doc-writer
description: Draft or revise developer-facing technical documentation using the Google developer documentation style guide. Use for technical design documents (TDDs), merge request descriptions, procedures, concepts, tutorials, reference material, README content, and troubleshooting guides; do not apply to marketing, legal, or general prose unless requested.
---

# Technical document writer

Create accurate, task-oriented documentation that readers can scan and use.
Preserve the user's requested format and the surrounding documentation's
conventions.

## Establish the writing contract

- Read the available source material, project guidance, terminology, and nearby
  documents before drafting. Apply guidance in this order: explicit user
  requirements, project-specific style, this skill, and then the live Google
  developer documentation style guide.
- Determine the audience, their goal, prerequisites, and the document's purpose
  from the request and available context. Ask only when a missing decision would
  materially change the result; otherwise make a narrow, visible assumption.
- Do not invent product behavior, commands, flags, output, prerequisites,
  support claims, version details, links, or measurements. Resolve them from
  authoritative sources, clearly mark an unresolved placeholder, or state what
  information is missing.
- When revising a document, retain correct, useful content and its established
  structure unless changing that structure is necessary for the requested
  outcome.

## Shape the document around the reader's goal

- Lead with the purpose, outcome, or most important fact. Include background
  only when it helps the reader act or understand.
- Give each paragraph one idea. Put its key information first and split walls of
  text into focused paragraphs, headings, or lists.
- Use descriptive, sentence-case headings in a logical hierarchy without
  skipped levels. Prefer an imperative heading for a task and a noun phrase for
  a concept. Do not put links in headings.
- For a task, state relevant prerequisites and context, present ordered steps,
  and include an observable result or verification when useful. Add cleanup or
  rollback only when the task creates state that readers might need to remove.
- For conceptual or reference material, organize around the questions readers
  need answered rather than the implementation's internal structure.

## Use clear and precise language

- Use US English unless the user or project specifies another variant.
- Address the reader as *you*. Use active voice and imperative verbs for
  instructions. Name the actor when software or another person performs an
  action.
- Put a condition before the instruction that depends on it. Keep the subject
  and verb near the start of the sentence.
- Use one consistent term, capitalization, and formatting for each concept.
  Define unfamiliar abbreviations and necessary jargon on first use. Prefer a
  precise plain-language alternative when jargon adds no value.
- In prescriptive content, use *must* for requirements, *can* for ability or
  permission, and *might* for possibility. State recommendations explicitly
  instead of using an ambiguous *should*.
- Keep product documentation timeless. Avoid words such as *currently*, *new*,
  *latest*, and *soon* unless a date or version makes the time reference useful.
  Do not announce unapproved future features.
- Use a conversational, friendly, and respectful tone without slang, hype,
  excessive politeness, or exclamation marks. Avoid calling a task *easy*,
  *simple*, or *quick*.
- Write literally for a global audience. Avoid idioms, humor, cultural or
  seasonal references, figurative or ableist language, unnecessary gendered
  language, and examples that reinforce stereotypes.

## Present technical material consistently

- Use numbered lists for sequences and bullets for unordered items. Introduce a
  list when its purpose is not already clear, make items parallel, and use
  consistent capitalization and end punctuation.
- Keep a procedure step focused on one action or a tightly related action and
  result. Label optional steps with **Optional:** and explain consequential or
  irreversible effects before the reader acts.
- Use code font for code-related identifiers and literal input, including
  commands, flags, filenames, paths, methods, fields, values, and HTTP status
  codes. Use bold for named user-interface elements.
- Introduce code blocks and explain their purpose. Keep samples minimal but
  realistic, follow the project's language-specific style, identify
  placeholders, and distinguish runnable samples from illustrative fragments.
- Use descriptive link text that identifies the destination. Provide brief
  essential context inline, link selectively, and avoid phrases such as *click
  here* or repeated links to the same destination.
- Use notices sparingly. A note is noncritical supporting information, a caution
  asks the reader to proceed carefully, and a warning identifies serious or
  irreversible harm such as data loss or a security risk. Keep information
  required for success in the main flow.
- Provide useful alt text for meaningful images. Do not rely on color, position,
  direction, or punctuation alone to convey meaning. Use tables only when their
  row-and-column relationship makes information easier to compare, and
  introduce them in the preceding text.

## Review before delivery

- Check every technical claim and ensure that commands, examples, inputs, and
  expected results agree with one another.
- Walk the reader's path from prerequisites through the intended outcome. Look
  for missing context, hidden decisions, unsafe ordering, and verification or
  recovery information that the task genuinely requires.
- Edit for directness, scannability, consistent terminology, accessibility,
  inclusion, and global comprehension. Remove repetition and content that does
  not help the reader meet the document's purpose.
- Deliver the requested document or edit in the requested form. Do not append a
  style audit, explanation of edits, or source list unless the user asks for
  one.

## Source basis

This skill summarizes and adapts the
[Google developer documentation style guide](https://developers.google.com/style)
by Google under the
[Creative Commons Attribution 4.0 License](https://creativecommons.org/licenses/by/4.0/).
Google does not endorse this skill. For a term-specific or ambiguous editorial
decision, consult the guide's current guidance, especially its
[word list](https://developers.google.com/style/word-list).

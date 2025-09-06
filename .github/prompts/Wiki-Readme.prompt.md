## PROMPT: Update repository documentation to match a selected code change

Goal

- Bring all repository documentation (inline docstrings/comments, module
  docs, README, CHANGELOG, API reference, and examples) into parity with the
  selected code changes without altering runtime behavior.

Scope & Tasks (apply to all affected files and public APIs)

1. Code-level docstrings/comments

   - Add or update idiomatic, language-appropriate docstrings for every
     exported/public symbol (JSDoc for JS/TS, Google/Numpy or reST for Python,
     Javadoc for Java, XML-doc for C#).
   - Each docblock must include: one-line summary, detailed description,
     parameter names and types, return type/value, raised exceptions/errors,
     side-effects, complexity notes (where relevant), and one minimal
     runnable example.

2. Module and package docs

   - Update module/file headers and package-level documentation to reflect new
     behavior, configuration options, and usage patterns.

3. README

   - Update the top-level README or the package README with: short description,
     install and quickstart, a minimal usage snippet, common configuration
     examples, and links to full API docs.

4. CHANGELOG

   - Add or append an "Unreleased" entry summarizing the documentation change,
     migration notes (if any), and a reference to the PR or commit.

5. Docs generation metadata

   - Ensure docs-site metadata (Sphinx/mkdocs/Typedoc/Jsdoc) and anchors are
     updated so generated API reference stays accurate.

6. Examples and runnable tests

   - Add or update minimal runnable examples under `docs/examples` (or the
     repo's examples folder) and include commands to run them and expected
     output. Verify examples are runnable where feasible.

7. Style and quality

   - Maintain consistent documentation style: present-tense summaries, clear
     grammar, concise language, and line-width consistent with repository
     conventions.

8. Ambiguities

   - Where behavior or design decisions are ambiguous, add TODO/FIXME
     comments explaining the decision needed and, if available, link to an
     issue or PR.

Output required from you

- Provide the exact updated documentation blocks (either a unified diff or
  full replacement text) for every file you changed.
- Provide a short manifest (JSON or YAML) that lists changed files and a one-
  line reason for each change.
- Suggest a concise commit message and a one-paragraph PR description.
- Do not change runtime code or alter behavior; only add or improve
  documentation and examples.

Constraints

- Preserve copyright and attributions.
- Keep examples minimal and runnable.
- If multiple languages are present, produce language-appropriate docstrings
  for each affected file and an optional consolidated human-readable summary.

Notes

- Prefer minimal, verifiable edits. If you cannot verify an example runs in
  this environment, state that clearly and provide the commands to run it
  locally.
- When in doubt about formatting, follow the repository's existing style.

-- End of prompt

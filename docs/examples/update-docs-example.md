# Example: Updating Documentation to Match Code Changes

This minimal example demonstrates the outputs the `Wiki-Readme.prompt.md` expects when you update repository documentation to match code changes.

Steps (run locally):

1. Create a branch from `develop` and make documentation edits (no runtime changes).

2. Produce the required outputs:

- Exact diffs or full replacement text for each file changed (use `git diff` or `git show`).
- A manifest (YAML) listing changed files and a one-line reason for each.
- A concise commit message and a one-paragraph PR description.

Example commands:

```bash
# Start from develop
git checkout develop
git pull origin develop
git checkout -b feature/docs-update

# Edit files (example: we've edited docs/releases/CHANGELOG.md and .github/prompts/Wiki-Readme.prompt.md)
# Commit changes
git add docs/releases/CHANGELOG.md .github/prompts/Wiki-Readme.prompt.md docs/examples/update-docs-example.md
git commit -m "docs: update prompt and add example for docs workflow"

# Show the unified diff for review
git --no-pager show --name-only --pretty="" HEAD
git --no-pager diff HEAD~1 HEAD
```

Expected manifest (YAML):

```yaml
- path: .github/prompts/Wiki-Readme.prompt.md
  reason: converted C-style block to Markdown for Copilot Chat compatibility
- path: docs/releases/CHANGELOG.md
  reason: added Unreleased changelog entry describing documentation updates
- path: docs/examples/update-docs-example.md
  reason: example file showing how to produce required outputs
```

Expected PR description:

"Converted the repository prompt `.github/prompts/Wiki-Readme.prompt.md` to Markdown for VS Code Copilot Chat compatibility and added a minimal example and an Unreleased changelog entry; no runtime behavior changed."

Notes:

- This example cannot be fully verified in this environment; run the commands locally to validate.

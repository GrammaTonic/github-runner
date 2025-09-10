---
mode: agent
---

name: Check CI/CD Workflow on GitHub Actions
description: Check the latest CI/CD Workflow status and ensure they pass.

# success_criteria:

- CI/CD workflows must pass.

# Ensure:

- gh api commands are created with --paginate and --slurp without --jq.

# Workflows:

- CI/CD Pipeline .github/workflows/ci-cd.yml

# Steps:

- Check the status of CI/CD Pipeline .github/workflows/ci-cd.yml
- Ensure all jobs within CI/CD Pipeline .github/workflows/ci-cd.yml have completed successfully.
- Fix any issues with failed jobs or workflows.
- Commit any changes made to fix issues.
- Push changes to the remote repository.
- Monitor the status of the new workflow runs after pushing changes with gh run watch
- Repeat the process until all workflows pass.

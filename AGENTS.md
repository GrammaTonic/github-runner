# AGENTS.md

## Overview

This document describes the agent architecture, available agent types, invocation methods, customization guidelines, and integration points for the GitHub Runner repository. It is intended for developers and contributors who need to understand, extend, or troubleshoot agent workflows in this project.

---

## Agent Types

### 1. GitHub Copilot (Default Agent)
- **Role:** Primary AI coding assistant for VS Code, responsible for code generation, review, documentation, and workflow guidance.
- **Invocation:** Automatically invoked for coding, documentation, and DevOps tasks.
- **Customization:** Controlled via `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md` files.

### 2. Explore Agent (Subagent)
- **Role:** Fast, read-only codebase exploration and Q&A. Used for searching files, code snippets, and answering structural questions.
- **Invocation:** Invoked via subagent workflows for codebase exploration. Specify thoroughness (quick, medium, thorough).
- **Customization:** No direct customization; integrates with Copilot via subagent interface.

### 3. Search Subagent
- **Role:** Specialized for searching codebase by patterns, keywords, or answering targeted questions.
- **Invocation:** Used for deep or broad codebase searches, invoked by Copilot or other agents.
- **Customization:** Controlled by search parameters and query details.

### 4. Skills
- **Role:** Domain-specific knowledge modules (e.g., summarizing GitHub issues, suggesting fixes, forming search queries).
- **Invocation:** Invoked automatically when relevant to user requests.
- **Customization:** Defined in skill files (e.g., `SKILL.md`), referenced in instructions.

---

## Agent Invocation & Integration

- **Automatic Invocation:** Copilot and skills are invoked based on user requests and context.
- **Subagent Invocation:** Use `runSubagent` tool with agent name (e.g., Explore) for complex tasks.
- **Skill Integration:** Skills are triggered by matching user requests to domain-specific instructions.
- **Instruction Files:** `.github/instructions/*.instructions.md` define agent behaviors, best practices, and workflow rules.

---

## Customization & Extension

- **Instructions:** Update `.github/copilot-instructions.md` and relevant `.instructions.md` files to modify agent behavior.
- **Skills:** Add or update skill files for new domain knowledge or workflow enhancements.
- **Subagents:** Extend subagent workflows for new exploration or search strategies.
- **Documentation:** Maintain AGENTS.md and related docs for clarity and maintainability.

---

## Example Usage

- **Copilot:** Code generation, review, documentation, DevOps guidance.
- **Explore Agent:** "Find all Dockerfiles" or "Show API endpoints".
- **Search Subagent:** "Search for runner registration logic".
- **Skills:** "Summarize GitHub issue", "Suggest fix for error".

---

## Maintenance & Troubleshooting

- Review agent instructions and skill files for updates or issues.
- Validate agent invocation via logs and documentation.
- Update AGENTS.md as new agent types or workflows are added.

---

## References

- [Copilot Instructions](../.github/copilot-instructions.md)
- [Agent Instructions](../.github/instructions/)
- [Skills Documentation](../.github/instructions/)

---

_Last updated: March 13, 2026_

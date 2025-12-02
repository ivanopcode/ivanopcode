# REPO.md

This file provides context and guidelines for coding agents when working in the `ivanopcode/ivanopcode` repository.

## Project Context
This repository contains the source for the GitHub profile of Ivan Oparin (`ivanopcode`). It is a special repository where the root `README.md` renders directly on the user's GitHub profile page.

- **Primary Artifact:** `README.md` (The public-facing profile).
- **Key Content:** Professional introduction, career highlights, technical skills, project showcases, and blog posts.
- **Goal:** Maintain a professional, up-to-date central hub for the user's digital identity.

## Project Structure
- **Root `README.md`:** Drives the primary narrative.
- **Assets:** Store images or diagrams in an `assets/` folder (if created) and use relative paths.
- **Organization:** 
  - Add new sections under clear `##` ATX headings.
  - Maintain chronological order in "Highlights" and "Developer notes".
  - Keep file sizes lean to ensure fast profile rendering.

## Coding Style & Formatting
- **Markdown:** Use standard ATX headers (`#`, `##`).
- **Lists:** Use `-` for bullet points.
- **Line Wrapping:** Wrap lines around ~100 characters for better readability in diffs.
- **Links:** Prefer inline links `[label](url)` over bare URLs. Verify all external links when touching a section.
- **Code:** Add language hints to code fences (e.g., ```swift).
- **Tone:** Professional and concise. Avoid emojis in technical notes or guideline files unless the section is intentionally informal.

## Development & Verification
There is no automated build pipeline or test suite; edits are plain Markdown.

### Commands
- **Lint (Optional):** `markdownlint README.md AGENTS.md`
- **Sanity Check:** `git status` and `git diff --stat` before pushing.

### Testing Guidelines
- **Preview:** Render the Markdown in your editor (e.g., VS Code `Cmd+Shift+V`) or GitHub’s web preview to confirm heading hierarchy and layout.
- **Links:** Manually verify that touched links are active and relative paths to assets resolve correctly.

## Version Control & Commit Conventions

We follow the **Standard Imperative Git Style**. This ensures the project history reads like a distinct changelog
and matches the built-in conventions of Git tools.

### The Imperative Mood

The subject line (first line) must be phrased as a command. To verify the format, the message must grammatically
complete the sentence:

> "If applied, this commit will **[Your Subject Line]**"

| Example | Status |
|---------|--------|
| `Refactor topology manager to support dual-layer rivers` | ✅ Good |
| `Refactored topology manager` | ❌ Bad (Past tense) |
| `Refactoring topology manager` | ❌ Bad (Continuous/Progressive) |

### Message Structure

To ensure readability in both CLI (`git log --oneline`) and GUI clients, strict separation between the summary
and details is required.

- **Subject (Line 1):** Concise summary, under 50 characters ideal (max 72). No trailing period.
- **Blank Line (Line 2):** Mandatory. Separates header from body.
- **Body (Line 3+):** Detailed explanation. Focus on **why** the change was made, not just *how* (the code shows
  *how*). Wrap text at approx. 72 characters.

### Commit Style

Commit style mirrors history: short (≤72 chars), imperative, single-focus messages (e.g., "Add tests for river
scoring").

- **Grouping:** Group related edits per commit; do not bundle unrelated content updates.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About this project

This is a documentation site for "Jylhis Docs" built on [Mintlify](https://mintlify.com). All pages are MDX files (Markdown + JSX) with YAML frontmatter. The central configuration is `docs.json`.

## Commands

```bash
# Install the Mintlify CLI (one-time)
npm i -g mint

# Run local preview server (hot-reload at http://localhost:3000)
mint dev

# Check for broken links
mint broken-links

# Update the CLI
npm mint update
```

Deployment is automatic via the Mintlify GitHub app when pushing to `main`.

## Architecture

**`docs.json`** is the single source of truth for site configuration: theme, colors, navigation structure (tabs, groups, pages), logo, API settings, and contextual options. Changes to navigation always go here.

**Content organization:**
- `essentials/` — core Mintlify feature documentation (settings, navigation, markdown, code, images, snippets)
- `api-reference/` — API docs driven by `openapi.json` (OpenAPI 3.1.0)
- `ai-tools/` — guides for AI tool integrations (Claude Code, Cursor, Windsurf)
- `snippets/` — reusable MDX snippets referenced across pages with the `<Snippet>` component

**MDX frontmatter pattern** used on every page:
```yaml
---
title: "Page Title"
description: "Brief description"
icon: "optional-lucide-icon-name"
---
```

**`.mintignore`** excludes `README.md`, `CONTRIBUTING.md`, `drafts/`, and `*.draft.mdx` from the build — content in these files is not published.

## Style guidelines (from AGENTS.md and CONTRIBUTING.md)

- Use active voice and second person ("you")
- Keep sentences concise — one idea per sentence
- Use sentence case for headings
- Bold for UI elements: Click **Settings**
- Code formatting for file names, commands, paths, and inline code references
- Lead with the goal when writing instructions
- Use consistent terminology — don't alternate synonyms for the same concept

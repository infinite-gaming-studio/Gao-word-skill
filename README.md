<div align="center">

# Gao's Word Skill

> Unpack, edit, repack — Word documents, precisely transformed at the XML level.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/Agent-Skill-7c3aed)]()
[![skills.sh](https://img.shields.io/badge/skills.sh-Compatible-blue)](https://skills.sh)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)]()

**A Word document modification skill.** Built on Anthropic's official `docx` skill's **unpack → edit OOXML → pack** pipeline. Modifies `.docx` at the XML level for full formatting fidelity — change colors, replace text, insert images, remove sections. Output always lands in `./gao-word-output/` — never touches the original.

</div>

---

## Quick Start

```
1. Share your .docx file: "这是我要修改的文档 /path/to/file.docx"
2. Tell me what you want: "把标题改成 #275317，替换 A → B，插入图片，删除目录"
3. Confirm the planned changes → review the result
4. Get your .docx in ./gao-word-output/
```

---

## Installation

### One-line (any runtime, auto-detect)

```bash
npx skills add infinite-gaming-studio/Gao-word-skill
```

The [skills CLI](https://github.com/vercel-labs/skills) auto-detects your runtime (Claude Code, Codex, Cursor, OpenCode, Gemini CLI, etc.) and installs to the correct directory.

### Manual by runtime

| Runtime | Command |
|---------|---------|
| **OpenCode** | `git clone https://github.com/infinite-gaming-studio/Gao-word-skill.git && ln -s "$(pwd)/Gao-word-skill" ~/.opencode/skills/Gao-word-skill` |
| **Claude Code** | `npx skills add infinite-gaming-studio/Gao-word-skill -g` or manually: `git clone ... && ln -s "$(pwd)/Gao-word-skill" ~/.claude/skills/Gao-word-skill` |
| **Codex CLI** | `npx skills add infinite-gaming-studio/Gao-word-skill -a codex` |
| **Cursor** | `npx skills add infinite-gaming-studio/Gao-word-skill -a cursor` |

After installation, restart your AI assistant — the skill auto-loads when triggered.

### Prerequisites

This skill **requires** [Anthropic's official `docx` skill](https://github.com/anthropics/skills) to read and write Word documents. If not already installed, you'll be guided to install it on first use:

```bash
npx skills add anthropics/skills
```

The `docx` skill provides native OOXML manipulation — no markdown conversion, no format loss.

### Reference-only mode

If your runtime doesn't support Agent Skills auto-loading, paste the contents of `SKILL.md` into your conversation. The skill works as plain Markdown + YAML frontmatter.

---

## Project Structure

```
Gao-word-skill/
├── SKILL.md              # Core skill — AI agents read this on activation
├── README.md             # This file
├── scripts/              # Utility scripts
│   └── update.sh         # Update script (curl-pipe compatible)
├── LICENSE               # MIT License
```

---

## What You Can Do

| Capability | Example |
|-----------|---------|
| **Heading/title colors** | Change all H2 headings to `#275317` |
| **Text replacement** | Replace "题型分组练" → "基础考点特训" |
| **Image insertion** | Add images before/after specific headings |
| **Remove sections** | Strip table of contents, footnotes, blank pages |
| **Restructure** | Reorder sections, merge paragraphs |
| **Batch edits** | All of the above in one pass |

---

## Design Philosophy

### Unpack → Edit OOXML → Pack

```
.docx  ──[unpack.py]──▶  XML  ──[Edit tool]──▶  XML  ──[pack.py]──▶  .docx
```

The docx skill unpacks the `.docx` into editable XML files, you modify `document.xml` directly (colors, text, images, structure), then repack back to `.docx`. Full OOXML fidelity — every paragraph, run, and style property is preserved and precisely editable.

### Never Overwrite Originals

All output lands in `./gao-word-output/`. Your source `.docx` is never modified.

### Iterate Until Satisfied

Phase 3 has no edit limit. You revise, preview, and confirm before Phase 4 generates the final file.

---

## Updating

**Note**: `npx skills update` cannot resolve `Gao-word-skill` back to the GitHub source. Use one of the reliable methods below.

### Method 1: curl pipe (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/infinite-gaming-studio/Gao-word-skill/main/scripts/update.sh | bash
```

### Method 2: one-liner

```bash
npx skills remove Gao-word-skill -g -y && npx skills add infinite-gaming-studio/Gao-word-skill -g
```

### Method 3: git pull (if cloned manually)

```bash
cd Gao-word-skill && git pull
```

After updating, restart your AI assistant to load the latest SKILL.md.

---

## Troubleshooting

If the update fails:
- Check your internet connection
- Try Method 2 (one-liner) directly
- If uninstalled but not reinstalled, run: `npx skills add infinite-gaming-studio/Gao-word-skill -g`

---

## Uninstalling

| Runtime | Command |
|---------|---------|
| **npx (any runtime)** | `npx skills remove Gao-word-skill` |
| **Manual** | Delete the skill directory from your runtime's skills folder (e.g. `rm -rf ~/.opencode/skills/Gao-word-skill`) |

---

## Development

```bash
git clone https://github.com/infinite-gaming-studio/Gao-word-skill.git
cd Gao-word-skill

# Install to OpenCode for testing
ln -s "$(pwd)" ~/.opencode/skills/Gao-word-skill
```

---

## License

MIT

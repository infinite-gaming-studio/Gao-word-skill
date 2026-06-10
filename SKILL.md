---
name: Gao-word-skill
description: Use when the user wants to modify a Word document (.docx) — edit content, change formatting (title/heading colors with hex values), replace text, insert images, remove sections (like table of contents), or restructure the document. Triggered by sharing a .docx file path with modification requests, or mentioning "修改word文档", "处理docx", "word文档编辑", "docx转markdown再转word". The workflow: load Anthropic's docx skill → convert to markdown → edit per user's instructions → convert back to .docx → output to ~/gao-word-output/.
---

# Gao Word Skill

## Overview

A three-phase workflow for modifying Word documents: convert `.docx` to markdown, apply user's edits freely on the text, then convert back to `.docx` with styling intact. Outputs to `~/gao-word-output/`.

## Phase 1: Convert DOCX → Markdown

### Step 1.1: Check Prerequisites

Attempt to load Anthropic's official `docx` skill:

```
skill("docx")
```

If the skill loads successfully → proceed to Step 1.2.

If the skill is **not found**, guide the user to install it:

> 需要先安装 Anthropic 官方的文档处理技能才能处理 Word 文件。请运行以下命令安装：
>
> ```bash
> npx skills add anthropics/skills
> ```
>
> 或者单独安装 docx 技能：
>
> ```bash
> npx skills add anthropics/docx
> ```
>
> 安装完成后，请重新发送你的 Word 文件。

**Fallback**: If the user cannot or doesn't want to install the Anthropic skill, you may fall back to using `pandoc` for basic conversion:

```bash
pandoc --track-changes=all "input.docx" -t markdown -o "/tmp/docx-convert.md"
```

However, warn the user that pandoc may lose some complex formatting (nested tables, text boxes, etc.).

### Step 1.2: Convert the Document

With the `docx` skill loaded, read the user's `.docx` file. The skill will handle converting it to markdown text in the conversation context.

Save the raw markdown to a temp working file:

```bash
mkdir -p ~/gao-word-output
```

Write the markdown content to `~/gao-word-output/{filename}_原始.md` (the "original" conversion).

### Step 1.3: Present Summary

After conversion, show the user what was extracted:

1. **Document structure**: headings found, paragraph count, tables, images
2. **Confirm**: "这份文档已转换为 Markdown。请告诉我你需要做哪些修改？"

## Phase 2: Edit the Markdown

Apply the user's requested changes directly on the markdown text.

### 2.1: Common Edit Categories

| Edit Type | How to Apply |
|-----------|-------------|
| **Heading/title color** | Annotate with HTML comments: `<!-- color:#275317 -->标题文字` |
| **Text replacement** | Direct markdown text substitution |
| **Image insertion** | Use `![alt](path/to/image.png)` syntax |
| **Remove TOC / section** | Delete the relevant markdown lines |
| **Reorder sections** | Move markdown heading blocks |
| **Add/modify text** | Direct markdown editing |

### 2.2: Color Annotation Convention

When user specifies color changes, use this convention in the intermediate markdown, so Phase 3 knows how to apply the formatting:

```markdown
<!-- color:#275317 -->## 基础考点特训
```

If the user only wants to change heading colors without modifying text:
- Wrap each heading with a `<!-- color:#XXXXXX -->` annotation on the same line
- The converter in Phase 3 will parse these annotations and apply the color to the corresponding OOXML run properties

### 2.3: Image Insertion

If the user provides an image file:
1. Note the image's absolute path
2. Insert it in markdown: `![描述](image-path)`
3. Phase 3 will embed the image in the final `.docx`

If the user provides a URL, download it first:

```bash
curl -sL "URL" -o ~/gao-word-output/temp-image.png
```

### 2.4: Iterative Editing

After each round of edits:
1. Show the modified markdown to the user
2. Ask: "修改后看起来对吗？还需要调整什么？"
3. Repeat until the user is satisfied

🔴 **CHECKPOINT**: Has the user explicitly confirmed they are satisfied? Do not proceed to Phase 3 without confirmation.

## Phase 3: Convert Markdown → DOCX

### Step 3.1: Prepare the Final Markdown

Before conversion, ensure all color annotations and image references are properly formatted. Clean up any working notes from the markdown.

### Step 3.2: Convert Using the docx Skill

Use the Anthropic `docx` skill to create a new `.docx` document from the edited markdown.

The docx skill should be instructed to:
- Parse `<!-- color:#XXXXXX -->` annotations and apply them as heading run colors
- Embed referenced images inline
- Preserve the heading hierarchy (H1 → Title, H2 → Heading 2, etc.)
- Apply a clean default styling

**Important**: Tell the docx skill explicitly about the color annotations so it applies them in the OOXML output:

```
Create a .docx file from this markdown. Parse `<!-- color:#XXXXXX -->Title` annotations — extract the hex color and apply it as the text color (w:color) for that heading's run properties. The annotation itself should NOT appear in the output document.
```

### Step 3.3: Save Output

The final `.docx` file goes to:

```
~/gao-word-output/{original-filename}-修改版.docx
```

If the user makes multiple rounds, append a version number:

```
~/gao-word-output/{original-filename}-修改版-v2.docx
```

### Step 3.4: Confirm Output

Tell the user the exact path:

> 文件已保存到：`~/gao-word-output/{name}-修改版.docx`

## Quick Reference

| Phase | Key Action | Verification |
|-------|-----------|-------------|
| **1. Convert** | Load docx skill, convert to markdown, save `_原始.md` | Can you see the full document structure in markdown? |
| **2. Edit** | Apply user's changes iteratively | Has the user confirmed they're satisfied? |
| **3. Output** | Convert back to .docx, save to `~/gao-word-output/` | Does the output file open correctly? |

## Error Handling

| Problem | Action |
|---------|--------|
| docx skill not found | Guide to install `npx skills add anthropics/skills` |
| Large file (>50 pages) | Warn user, process in sections |
| Complex formatting lost | Note what couldn't be preserved (text boxes, embedded charts), suggest manual adjustment |
| Image file not found | Ask user to provide correct path |
| pandoc not installed | Guide: `brew install pandoc` (macOS) / `apt install pandoc` (Linux) |
| User provides .doc (not .docx) | Ask them to save as .docx format first |

## Example Workflow

**User**: "这是我的试卷文档 /path/to/exam.docx，请把：
1. 标题颜色改成 #275317
2. '题型分组练' 改为 '基础考点特训'，'创新拓展练' 改为 '思维进阶跃升'，'新题速递' 改为 '前沿名校模考'，颜色都改成 #275317
3. 在每个新标题前插入仙人掌图标 cactus.png
4. 去掉目录"

**AI follows the skill**:

1. Load `docx` skill → convert exam.docx → show structure
2. Edit markdown:
   - Add `<!-- color:#275317 -->` before each heading
   - Replace text strings
   - Insert `![仙人掌](cactus.png)` before the three headings
   - Delete the TOC section lines
3. Show edited markdown → user confirms
4. Convert to .docx → save to `~/gao-word-output/exam-修改版.docx`
5. Tell user: "文件已保存到 ~/gao-word-output/exam-修改版.docx"

## Anti-Patterns

| ❌ Don't | ✅ Do Instead |
|----------|-------------|
| Skip checking for docx skill | Always check prerequisites first |
| Apply edits without showing the user | Show edits and get confirmation before Phase 3 |
| Assume color format | Always use `#RRGGBB` hex format |
| Overwrite the original file | Save to `~/gao-word-output/` directory |
| Proceed to output without user OK | 🔴 CHECKPOINT: require explicit confirmation |
| Forget to create output directory | `mkdir -p ~/gao-word-output` at the start |
| Apply formatting to non-heading text without user request | Only apply colors where user explicitly requests |

## Principles

- **Convert first, edit later** — always start with a clean markdown conversion
- **Show every change** — the user sees intermediate results before final output
- **Never overwrite originals** — output always goes to `~/gao-word-output/`
- **Iterate until satisfied** — no limit on editing rounds in Phase 2
- **Color annotations are the bridge** — the `<!-- color:#XXX -->` convention carries formatting intent through the markdown intermediary
- **Fail gracefully** — if a tool is missing, guide the user to install it; never block

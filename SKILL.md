---
name: Gao-word-skill
description: Use when the user wants to modify a Word document (.docx) — edit content, change formatting (title/heading colors with hex values), replace text, insert images, remove sections (like table of contents), or restructure the document. Triggered by sharing a .docx file path with modification requests, or mentioning "修改word文档", "处理docx", "word文档编辑", "word修改". Requires Anthropic's official docx skill — guides user to install it if missing. Outputs to ./gao-word-output/.
---

# Gao Word Skill

## Overview

A direct Word document modification workflow. Loads Anthropic's official `docx` skill to read, modify, and regenerate `.docx` files — no intermediate format, no markdown roundtrip. Output goes to `./gao-word-output/`, original is never touched.

## Required Dependency

This skill **requires** [Anthropic's official `docx` skill](https://github.com/anthropics/skills) to read and write Word documents. It must be installed before any document processing can occur.

---

## Phase 1: Prerequisites & Setup

### Step 1.1: Load the docx Skill

The first action is always to load the Anthropic `docx` skill:

```
skill("docx")
```

### Step 1.2: If Not Found → Install

If the `docx` skill does not exist, **stop** and guide the user:

> 这个技能依赖 Anthropic 官方的文档处理能力，需要先安装 `docx` 技能。请运行：
>
> ```bash
> npx skills add anthropics/skills
> ```
>
> 安装完成后，请重新发送你的 Word 文件。

Do **NOT** proceed without it. Do not offer pandoc fallbacks — the docx skill provides the only reliable path for reading AND writing with full formatting fidelity.

### Step 1.3: Create Output Directory

```bash
mkdir -p ./gao-word-output
```

---

## Phase 2: Read & Understand

### Step 2.1: Read the Document

With the `docx` skill loaded, read the user's `.docx` file. The skill will extract and present the document content.

### Step 2.2: Present a Summary

Show the user a structural summary:

```
文档结构概览：
- 标题层级：H1 × 2, H2 × 12, H3 × 36
- 段落数：~200
- 表格：3 个
- 图片：8 张
- 目录：有

请确认你要做的修改：
1. ...
2. ...
```

### Step 2.3: Confirm Modifications

If the user hasn't already specified all changes, ask what they want. If they gave a multi-part request with the file, paraphrase it back for confirmation:

> 确认以下修改：
> 1. 所有标题颜色 → #275317
> 2. "题型分组练" → "基础考点特训"
> ...

🔴 **CHECKPOINT**: User confirms the intended modifications before any changes are applied.

---

## Phase 3: Apply Modifications

Use the `docx` skill's native capabilities to modify the document directly. The docx skill can manipulate OOXML to edit content, formatting, colors, images, and structure.

### 3.1: Common Modification Patterns

| Request | How to Apply (via docx skill) |
|---------|-------------------------------|
| **Heading/title color** | Modify the heading paragraph's run properties — set `w:color` to the hex value |
| **Text replacement** | Search for text strings in the OOXML body and replace them |
| **Image insertion** | Add an image run before/after the target paragraph |
| **Remove TOC** | Delete the SDT (structured document tag) block containing the TOC field |
| **Remove sections** | Delete the relevant paragraphs/body elements |
| **Reorder sections** | Reorder the body elements |
| **Change font/size** | Modify run properties (`w:rPr`) on the target text |

### 3.2: Color Application

When the user specifies hex colors (e.g. `#275317`):

1. Find the target text (headings, specific text runs)
2. Modify the OOXML run properties to set `w:color` with `w:val="275317"`
3. If the user says "所有标题", apply to all heading paragraphs

### 3.3: Image Insertion

When the user provides an image file path:

1. Verify the file exists
2. Use the docx skill to embed the image inline before/after the target content
3. If the user provides a URL, download first:
   ```bash
   curl -sL "URL" -o ./gao-word-output/temp-image.png
   ```

### 3.4: Iterate

After applying modifications:
1. Present a preview/summary of what changed
2. Ask: "修改已完成。还需要调整什么吗？"
3. Repeat until the user is satisfied

🔴 **CHECKPOINT**: Has the user explicitly confirmed satisfaction? Do not proceed to Phase 4 without it.

---

## Phase 4: Save Output

### Step 4.1: Generate the Modified .docx

Use the `docx` skill to write the modified document to disk.

### Step 4.2: Output Path

```
./gao-word-output/{original-filename}-修改版.docx
```

For multiple rounds, append version number:

```
./gao-word-output/{original-filename}-修改版-v2.docx
```

### Step 4.3: Confirm

> 文件已保存到：`./gao-word-output/exam-修改版.docx`

---

## Quick Reference

| Phase | Key Action | Check |
|-------|-----------|-------|
| **1. Setup** | Load docx skill, create output dir | Is docx skill available? |
| **2. Read** | Read document, present structure, confirm changes | Did user confirm the plan? |
| **3. Modify** | Apply edits via docx skill, iterate | Did user say they're satisfied? |
| **4. Save** | Write .docx to ./gao-word-output/ | Output file opens correctly? |

---

## Error Handling

| Problem | Action |
|---------|--------|
| **docx skill not found** | Stop. Guide: `npx skills add anthropics/skills` |
| **Large file (>50 pages)** | Warn user, process in stages |
| **Complex formatting (text boxes, charts)** | Note what can't be modified, suggest manual adjustment |
| **Image file not found** | Ask user to provide correct path |
| **User provides .doc (legacy format)** | Ask them to open in Word and save as .docx first |
| **Output dir not writable** | Use /tmp/ fallback, warn user |

---

## Example Workflow

**User**: "这是我的试卷 /path/to/exam.docx，请把：
1. 标题颜色改成 #275317
2. '题型分组练' → '基础考点特训'，'创新拓展练' → '思维进阶跃升'，'新题速递' → '前沿名校模考'，颜色 #275317
3. 在每个新标题前插入仙人掌插图 cactus.png
4. 去掉目录"

**AI follows the skill**:

1. Load `docx` skill → check available
2. Create `./gao-word-output/`
3. Read exam.docx → present structure summary → confirm 4 modifications
4. Apply changes via docx skill:
   - Search for all heading paragraphs → set `w:color="275317"`
   - Search body text for "题型分组练" → replace with "基础考点特训" + set color
   - Same for the other two terms
   - Insert image runs before each of the three target headings
   - Find and delete the TOC SDT block
5. Show change summary → user confirms "没问题"
6. Save → `./gao-word-output/exam-修改版.docx`
7. "文件已保存到 ./gao-word-output/exam-修改版.docx"

---

## Anti-Patterns

| ❌ Don't | ✅ Do Instead |
|----------|-------------|
| Skip checking for docx skill | Always verify prerequisites first |
| Convert to markdown as an intermediate step | Use docx skill directly |
| Overwrite the original file | Always output to `./gao-word-output/` |
| Apply changes without user confirmation | Paraphrase and confirm before modifying |
| Proceed to save without user satisfaction | 🔴 CHECKPOINT: require explicit "ok" |
| Offer pandoc/markdown fallback for formatting edits | docx skill is the only reliable path |

---

## Principles

- **Direct manipulation** — use the docx skill natively; no markdown roundtrip
- **docx skill is mandatory** — stop and guide if not installed; no workarounds
- **Never overwrite originals** — output always goes to `./gao-word-output/`
- **Confirm before acting** — paraphrase all changes, get explicit approval
- **Iterate until satisfied** — unlimited revision rounds in Phase 3
- **Fail gracefully** — missing dependencies → clear install instructions, never block silently

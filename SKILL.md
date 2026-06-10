---
name: Gao-word-skill
description: Use when the user wants to modify a Word document (.docx) — edit content, change formatting (title/heading colors with hex values), replace text, insert images, remove sections (like table of contents), or restructure the document. Triggered by sharing a .docx file path with modification requests, or mentioning "修改word文档", "处理docx", "word文档编辑", "word修改". Requires Anthropic's official docx skill — guides user to install it if missing. Outputs to ./gao-word-output/.
---

# Gao Word Skill

## Overview

A direct Word document modification workflow built on top of [Anthropic's official `docx` skill](https://github.com/anthropics/skills). It uses the docx skill's **unpack → edit OOXML → pack** pipeline to make precise, formatting-safe modifications to `.docx` files. Output goes to `./gao-word-output/` in the current project, original is never touched.

## Required Dependency

This skill **requires** Anthropic's official `docx` skill (part of the [anthropics/skills](https://github.com/anthropics/skills) collection). It must be installed and loaded before any document processing.

**Anthropic Document Skills (GitHub):** https://github.com/anthropics/skills

| Skill | Purpose | Repo Path |
|-------|---------|-----------|
| `docx` | Word document read/write | `anthropics/skills` → `skills/docx/` |
| `pdf`  | PDF read/write | `anthropics/skills` → `skills/pdf/` |
| `pptx` | PowerPoint read/write | `anthropics/skills` → `skills/pptx/` |
| `xlsx` | Excel read/write | `anthropics/skills` → `skills/xlsx/` |

---

## Phase 0: Load Prerequisites

### Step 0.1: Load the docx Skill

```
skill("docx")
```

### Step 0.2: If Not Found → Stop & Guide

> 这个技能依赖 Anthropic 官方的文档处理能力，需要先安装 `docx` 技能。请运行：
>
> ```bash
> npx skills add anthropics/skills
> ```
>
> 该技能来自 GitHub: https://github.com/anthropics/skills
>
> 安装完成后，请重新发送你的 Word 文件。

Do **NOT** proceed without the docx skill loaded. Its `unpack.py` / `pack.py` scripts and OOXML patterns are the foundation of this workflow.

### Step 0.3: Locate the docx Skill's Scripts

Find the installed docx skill path:

```bash
find ~/.opencode/skills ~/.claude/skills ~/.codex/skills ~/.agents/skills -maxdepth 2 -name "SKILL.md" -path "*/docx/*" 2>/dev/null | head -1 | sed 's|/SKILL.md||'
```

Store this as `$DOCX_SKILL_HOME`. All `unpack.py` / `pack.py` calls below use paths relative to this directory.

### Step 0.4: Create Output Directory

```bash
mkdir -p ./gao-word-output
```

---

## Phase 1: Read & Understand

### Step 1.1: Extract Text Content

Use pandoc to get a quick read of the document:

```bash
pandoc --track-changes=all "input.docx" -t markdown -o /tmp/docx-read.md
cat /tmp/docx-read.md
```

This gives a structural overview without unpacking.

### Step 1.2: Present a Summary

```
文档结构概览：
- 标题层级：H1 × N, H2 × N, H3 × N
- 段落数：~N
- 表格：N 个
- 目录：有/无

确认以下修改：
1. ...
2. ...
```

🔴 **CHECKPOINT**: Paraphrase and confirm ALL modifications before touching the file.

---

## Phase 2: Unpack

### Step 2.1: Unpack the .docx

```bash
python $DOCX_SKILL_HOME/scripts/office/unpack.py "input.docx" ./gao-word-output/unpacked/
```

This extracts all XML files to `./gao-word-output/unpacked/`. The main content is in `./gao-word-output/unpacked/word/document.xml`.

---

## Phase 3: Edit the OOXML

Edit `./gao-word-output/unpacked/word/document.xml` using the Edit tool. All modifications are XML-level — precise, no formatting loss.

### 3.1: Change Heading/Text Color

Find the target heading paragraph. Inside its `<w:rPr>` (run properties), add `<w:color w:val="COLOR"/>`:

```xml
<!-- BEFORE -->
<w:r>
  <w:rPr><w:b/><w:sz w:val="32"/></w:rPr>
  <w:t>题型分组练</w:t>
</w:r>

<!-- AFTER: add w:color to w:rPr -->
<w:r>
  <w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="275317"/></w:rPr>
  <w:t>基础考点特训</w:t>
</w:r>
```

**Hex color format**: OOXML uses `RRGGBB` (no `#`). `#275317` → `w:val="275317"`, `#BF4E14` → `w:val="BF4E14"`.

If `<w:rPr>` already has a `<w:color>`, replace its `w:val`. If `<w:rPr>` doesn't exist, wrap the run content with one.

### 3.2: Search & Replace Text

Find `<w:t>OLD TEXT</w:t>` and replace with `<w:t>NEW TEXT</w:t>`. Text may be split across multiple `<w:t>` elements within a run — check both `<w:r>` and `<w:del>/<w:ins>` blocks.

**Example**: Replace "题型分组练" → "基础考点特训" in all occurrences:

Search the XML for `题型分组练` (use Grep to find occurrences first). For each occurrence, replace the `<w:t>` content using Edit.

### 3.3: Remove Table of Contents

A TOC is wrapped in a `<w:sdt>` (Structured Document Tag) block. Search for `<w:sdt>` that contains `<w:sdtPr><w:docPartObj>` (TOC marker) — delete the entire `<w:sdt>...</w:sdt>` block.

```xml
<!-- DELETE everything from <w:sdt> through </w:sdt> -->
<w:sdt>
  <w:sdtPr>
    <w:docPartObj>
      <w:docPartGallery w:val="Table of Contents"/>
    </w:docPartObj>
  </w:sdtPr>
  <w:sdtContent>
    <!-- TOC content paragraphs -->
  </w:sdtContent>
</w:sdt>
```

### 3.4: Insert Images

To insert an image before a specific heading:

**Step A**: Copy the image file into the unpacked media directory:

```bash
cp /path/to/cactus.png ./gao-word-output/unpacked/word/media/
```

**Step B**: Add relationship in `./gao-word-output/unpacked/word/_rels/document.xml.rels`. Find the next available `rId` number and add:

```xml
<Relationship Id="rIdN" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/cactus.png"/>
```

**Step C**: Add content type in `./gao-word-output/unpacked/[Content_Types].xml` if needed:

```xml
<Default Extension="png" ContentType="image/png"/>
```

**Step D**: Insert the drawing XML before the target heading paragraph in `document.xml`:

```xml
<w:p>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="914400" cy="914400"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="1" name="图片 1"/>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr>
                <pic:cNvPr id="0" name="cactus.png"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="rIdN"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm><a:off x="0" y="0"/><a:ext cx="914400" cy="914400"/></a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
```

Replace `rIdN` with the actual relationship ID, and adjust `wp:extent` dimensions as needed (914400 EMU = 1 inch).

---

## Phase 4: Pack & Output

### Step 4.1: Pack Back to .docx

```bash
python $DOCX_SKILL_HOME/scripts/office/pack.py ./gao-word-output/unpacked/ ./gao-word-output/{filename}-修改版.docx --original "input.docx"
```

This validates the XML (auto-repairs whitespace/durableId issues), condenses, and creates the final `.docx`.

### Step 4.2: Validate

```bash
python $DOCX_SKILL_HOME/scripts/office/validate.py ./gao-word-output/{filename}-修改版.docx
```

If validation fails, unpack the output, fix the XML, and repack.

### Step 4.3: Confirm

> 文件已保存到：`./gao-word-output/{filename}-修改版.docx`

### Step 4.4: Clean Up (Optional)

```bash
rm -rf ./gao-word-output/unpacked/
```

---

## Quick Reference: OOXML Patterns

| Task | XML Target | How |
|------|-----------|-----|
| **Color** | `<w:color w:val="RRGGBB"/>` | Add/change inside `<w:rPr>` of target run |
| **Bold** | `<w:b/>` in `<w:rPr>` | Add for bold, remove for unbold |
| **Font size** | `<w:sz w:val="XX"/>` (half-points) | `28` = 14pt, `32` = 16pt, `36` = 18pt |
| **Text replace** | `<w:t>TEXT</w:t>` | Find `<w:t>` with old text, replace content |
| **Delete paragraph** | Entire `<w:p>...</w:p>` | Remove the paragraph block |
| **Remove TOC** | `<w:sdt>` with `<w:docPartObj>` | Delete the full `<w:sdt>` block |
| **Insert image** | `<w:drawing>` block | See §3.4 above — requires media, rels, and XML |
| **Font face** | `<w:rFonts w:ascii="FontName"/>` in `<w:rPr>` | Set font family |

---

## Quick Reference: Workflow

| Phase | Command | What It Does |
|-------|---------|-------------|
| **0. Setup** | `skill("docx")` → find install path → `mkdir -p ./gao-word-output` | Prerequisites |
| **1. Read** | `pandoc input.docx -t markdown` | Quick content preview |
| **2. Unpack** | `unpack.py input.docx unpacked/` | Extract OOXML to editable files |
| **3. Edit** | Edit tool on `unpacked/word/document.xml` | Modify XML directly |
| **4. Pack** | `pack.py unpacked/ output.docx --original input.docx` | Compile back to .docx |
| **5. Validate** | `validate.py output.docx` | Check for XML errors |

---

## Error Handling

| Problem | Action |
|---------|--------|
| **docx skill not found** | Stop. Guide: `npx skills add anthropics/skills` |
| **pandoc not installed** | Guide: `brew install pandoc` (macOS) / `apt install pandoc` (Linux). Or skip to unpack + read XML directly |
| **Unpack fails** | Check file is valid .docx. If .doc file: `python scripts/office/soffice.py --headless --convert-to docx file.doc` |
| **Pack fails with XML errors** | Read pack.py output for line numbers, fix the indicated XML, re-pack |
| **Validation fails** | Unpack the output, inspect and fix the XML, re-pack |
| **Image not found** | Ask user for correct file path |
| **Color doesn't apply** | Verify `<w:color>` is inside `<w:rPr>` of the correct `<w:r>` |

---

## Example Workflow

**User**: "这是我的试卷 /path/to/exam.docx，请把：
1. 标题颜色改成 #275317
2. '题型分组练' → '基础考点特训'，'创新拓展练' → '思维进阶跃升'，'新题速递' → '前沿名校模考'，颜色 #275317
3. 在三个新标题前插入仙人掌图片 cactus.png
4. 去掉目录"

**AI execution**:

1. `skill("docx")` → loaded. Find docx path. `mkdir -p ./gao-word-output`
2. `pandoc exam.docx -t markdown` → read structure, show summary, user confirms
3. `python {docx}/scripts/office/unpack.py exam.docx ./gao-word-output/unpacked/`
4. **Edit XML** (`unpacked/word/document.xml`):
   - Use Grep to find all heading paragraphs → add `<w:color w:val="275317"/>` to their `<w:rPr>`
   - Grep for "题型分组练" → replace `<w:t>题型分组练</w:t>` → `<w:t>基础考点特训</w:t>`
   - Grep for "创新拓展练" → replace → `<w:t>思维进阶跃升</w:t>`
   - Grep for "新题速递" → replace → `<w:t>前沿名校模考</w:t>`
   - For each of the three headings, insert `<w:drawing>` block before the heading paragraph
   - Copy `cactus.png` → `unpacked/word/media/`, add relationship + content type
   - Find `<w:sdt>` with `<w:docPartObj>` → delete the whole block
5. `python {docx}/scripts/office/pack.py ./gao-word-output/unpacked/ ./gao-word-output/exam-修改版.docx --original exam.docx`
6. `python {docx}/scripts/office/validate.py ./gao-word-output/exam-修改版.docx`
7. "文件已保存到 `./gao-word-output/exam-修改版.docx`"

---

## Anti-Patterns

| ❌ Don't | ✅ Do Instead |
|----------|-------------|
| Skip loading the docx skill | Always `skill("docx")` first |
| Try to "guess" OOXML structure | Reference the docx skill's XML patterns |
| Edit .docx directly as binary/zip | Always unpack → edit XML → pack |
| Use markdown as intermediate format | Edit OOXML directly for full fidelity |
| Write Python scripts to edit XML | Use the Edit tool for string replacements |
| Forget to add relationships for images | Always update `_rels/document.xml.rels` + `[Content_Types].xml` |
| Overwrite the original file | Output to `./gao-word-output/` always |

---

## Principles

- **Load docx skill first** — all tools and patterns come from it
- **Unpack → edit XML → pack** — the docx skill's proven pipeline
- **OOXML is the source of truth** — all modifications happen at the XML level
- **Color convention**: `#RRGGBB` from user → `<w:color w:val="RRGGBB"/>` in OOXML
- **Use the Edit tool, not scripts** — per the docx skill's own guidance
- **Validate output** — always run `validate.py` after packing
- **Never overwrite originals** — output to `./gao-word-output/`
- **Fail gracefully** — missing deps → clear install instructions

---
name: markdown-to-pdf
description: Convert Markdown files into typeset PDFs with md2pdf, pandoc, and typst resolved from PATH. Use for Markdown-to-PDF export or batches; not for non-Markdown sources, other output formats, or editing existing PDFs.
---

# Markdown to PDF

Render with caller-installed tools, preserve the source, and inspect the rendered pages before
claiming success.

## Check the tools

Resolve every required executable from `PATH`:

```bash
command -v md2pdf
command -v pandoc
command -v typst
```

Stop if any command is missing. Do not recreate a wrapper from embedded source or assume an install
location or tool version. Point the user to the official installation instructions or their
platform's package manager. Install software only after explicit approval.

## Prepare the conversion

1. Inspect every input path and confirm it is Markdown.
2. Choose the output path requested by the user, or use the same basename with a `.pdf` extension.
3. If an output already exists, preview the overwrite and wait for explicit approval.
4. Flag unsupported constructs before conversion. Mermaid and similar diagram blocks, raw HTML, and
   machine-specific fonts may not render as intended without extra tooling.

## Render

Use the wrapper's supported interface rather than assuming flags:

```bash
md2pdf --help
md2pdf input.md
md2pdf -o output.pdf input.md
```

Use batch mode only when the user requested all matched inputs. Quote paths and avoid broad globs
whose expansion has not been inspected. Pass custom typography or Pandoc options only when the user
asks for them or the document requires them.

## Verify the artifact

An exit code alone is insufficient.

1. Confirm the expected output exists, is non-empty, and is recognized as a PDF by an available
   file-inspection tool.
2. Use an available PDF renderer or viewer to render pages to images.
3. Visually inspect at least the first page and every page containing a table, code block, formula,
   image, or other layout-sensitive element. For long uniform documents, also inspect a middle and
   final page.
4. Confirm page count, clipping, font fallback, links, headings, tables, code, and formulas are
   acceptable. Re-render after any correction.

If no renderer or viewer is available, ask the user to inspect the PDF and withhold a visual-quality
claim until they confirm it. Report the output path, tools used, and which pages were inspected.

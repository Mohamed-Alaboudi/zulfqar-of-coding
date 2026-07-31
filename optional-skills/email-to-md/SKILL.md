---
name: email-to-md
description: For email-writing requests, save the draft as Markdown and return its path, except for existing-file edits or an explicit request for inline text.
---

# Email to Markdown

For any request to write, draft, compose, or reply to an email, make the deliverable a Markdown file rather than an inline chat paste. This standing order does not apply when the user explicitly asks for inline text or asks to edit an email that already exists in a file.

Write plain, flush-left text with a subject line and blank lines between paragraphs. Do not use code fences, blockquotes, or leading indentation. Use a safe, uncommitted scratch location associated with the current work when one exists; otherwise use the active session's scratch location. Return the file path and a concise command or instruction for opening it. Do not also paste the complete draft unless asked.

Default to a short, direct style. Avoid em dashes. Confirm any organization-specific sign-off details when they are not supplied.

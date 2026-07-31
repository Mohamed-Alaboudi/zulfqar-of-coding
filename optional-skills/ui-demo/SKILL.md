---
name: ui-demo
description: "Discover, rehearse, and record a polished browser UI walkthrough with visible cursor movement and human pacing. Use only when explicitly invoked as $ui-demo."
---

# UI Demo

Record a trustworthy UI walkthrough in three phases: discover, rehearse, then record.

This skill authorizes recording only. Starting a local service, creating an external deployment, or changing remote state requires separate explicit user authority. Never deploy as a fallback when the target application is not reachable.

## Inputs

Resolve before scripting:

- the explicit base URL;
- the exact user story and page sequence;
- test credentials or pre-authenticated browser state supplied through approved secret handling;
- the output directory and filename;
- viewport and any accessibility preferences.

Do not embed credentials in the script or print them. If the URL is unavailable, stop and ask whether to use an existing environment or separately authorize a local start or external deployment.

## Phase 1: Discover

Visit every page in the requested flow and inspect visible interactive elements. Record:

- field tag, type, label, name, placeholder, and role;
- exact button and link text;
- select option values and display text;
- required fields and validation behavior;
- dynamic fields, custom comboboxes, rich-text behavior, and modal controls;
- table headers associated with editable cells.

Use the browser's accessible tree and stable user-facing locators before CSS position selectors. Produce a compact field map. Do not script features that were not observed.

## Phase 2: Rehearse

Run the complete flow without video recording. Every planned locator must resolve and every transition must reach its expected state.

```javascript
async function requireVisible(locator, label) {
  if (!await locator.isVisible().catch(() => false)) {
    throw new Error(`Rehearsal failed: ${label} is not visible`);
  }
  return locator;
}
```

On failure:

1. capture the current URL, accessible snapshot, and screenshot;
2. fix the locator or flow assumption;
3. restart from a known state;
4. repeat until the full rehearsal passes.

Do not continue after a failed or skipped step.

## Phase 3: Record

Create a fresh browser context with video recording enabled. Tell a short story:

1. orient the viewer;
2. perform the main action;
3. show the resulting state;
4. include a secondary variation only when requested.

Use deliberate motion and readable pacing:

- move the cursor to a target before clicking;
- type visibly for user-facing input;
- smooth-scroll when revealing content;
- pause after navigation, modal opens, submissions, and the final result;
- keep subtitles brief and re-inject overlays after navigation.

```javascript
async function moveAndClick(page, locator, label) {
  await requireVisible(locator, label);
  await locator.scrollIntoViewIfNeeded();
  const box = await locator.boundingBox();
  if (!box) throw new Error(`Cannot locate bounds for ${label}`);
  await page.mouse.move(
    box.x + box.width / 2,
    box.y + box.height / 2,
    { steps: 10 }
  );
  await page.waitForTimeout(400);
  await locator.click();
  await page.waitForTimeout(800);
}

async function typeSlowly(page, locator, text, label) {
  await moveAndClick(page, locator, label);
  await locator.fill("");
  await locator.pressSequentially(text, { delay: 35 });
}
```

Add a high-contrast cursor overlay with `pointer-events: none` and a subtitle bar with an appropriate live-region policy for the recording context. Re-inject both after each full navigation.

## Verify the artifact

- Close the browser context cleanly so the video finalizes.
- Copy or save the recording to the explicit output path.
- Confirm the file exists and has nonzero size.
- Inspect the recorded video from start to finish.
- Verify that no secret, personal data, unrelated tab, debug overlay, or failed interaction appears.
- Report the exact artifact path and any requested format conversion.

Do not present a recording as complete based only on the automation script's success message.

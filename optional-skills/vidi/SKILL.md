---
name: vidi
description: Analyze what is said and shown in a video by synchronizing transcript evidence with sampled frames. Use for video files, public video URLs, slides, dashboards, UI, code, or demos; not for video editing or pure-audio analysis.
---

# Video analysis

Treat a video as synchronized visual and audio evidence. Use hybrid frame sampling so a long static
slide is not mistaken for an empty interval.

## Establish access and privacy

- Accept a user-provided local video or a public URL that the caller is authorized to access.
- Resolve needed tools from `PATH`; never assume an install location or fixed version. At minimum,
  use `ffprobe` and `ffmpeg`. Use `yt-dlp` or `scenedetect` only when already available.
- Use only caller-managed authentication. Never read browser profiles, token stores, or other
  application sessions. If a URL requires access, ask the user to supply an accessible local file or
  authenticate the chosen tool themselves.
- Never upload local or access-controlled media to an external transcription or analysis service
  without previewing what data will leave the machine and receiving explicit approval.

Keep task artifacts under `tmp/vidi/<safe-topic>/`. Sanitize URL-derived names before using them as
paths. Save a requested durable report under
`docs/research/YYYY-MM-DD-<safe-topic>-video-analysis.md`.

## Acquire the media and transcript

Use a local video directly. For a public URL, download only the requested video and available
captions with `yt-dlp`, writing them under the task's `tmp/vidi/` directory. Do not use browser-cookie
import or undocumented provider APIs.

Prefer, in order:

1. a transcript supplied by the user;
2. captions included with the media or publicly exposed by the source;
3. a local transcription executable already available on `PATH`; or
4. an explicitly approved configured transcription service.

Cache the untouched transcript or caption payload beside the task artifacts before reformatting it.
If no transcript can be obtained, analyze the visuals and clearly limit claims about what was said.

## Probe and classify

Inspect duration, dimensions, and frame rate:

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate \
  -show_entries format=duration \
  -of default=noprint_wrappers=1 "VIDEO"
```

Inspect an early frame and classify the content as mostly talking head, static slides, screen share,
code, dashboard, or fast UI. Choose a shorter sampling interval when small or fast-changing details
matter.

## Sample with two signals

Use both:

1. scene boundaries from `scenedetect`, when it is available on `PATH`, to find hard and soft cuts;
2. a fixed time grid to guarantee coverage during static scenes.

For example, extract one readable-width frame every 18 seconds for an ordinary talk:

```bash
ffmpeg -hide_banner -loglevel error -i "VIDEO" \
  -vf "fps=1/18,scale=1280:-1" -q:v 2 \
  "tmp/vidi/<safe-topic>/frames/frame_%06d.jpg"
```

Tighten the interval for dense slides, code, dashboards, or fast UI. Record the chosen interval and
its rationale. Do not claim coverage of events shorter than that interval.

Collapse adjacent near-duplicate frames with an existing visual-comparison tool when available, or
review a contact sheet and retain distinct frames manually. Do not create or install a bespoke
deduplication script as part of this workflow.

## Synchronize and report

Inspect each retained frame and align its timestamp with the transcript. Record:

| time | on-screen evidence | what is said | uncertainty |
|------|--------------------|--------------|-------------|

Capture important visible labels, code, table values, and state changes. Re-extract a narrow
high-resolution interval when text is unreadable or a transition matters.

State the blind spots: sampled frames can miss brief events, still images do not prove motion or
causality, captions may be inaccurate, and small text may require a closer pass. Report source,
sampling interval, transcript source, inspected frame count, and artifact paths.

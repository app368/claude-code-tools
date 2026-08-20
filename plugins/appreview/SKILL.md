---
name: appreview
description: Prepares recorded app previews for App Store Connect — checks frame size, duration and audio, stretches a screen recording to the exact required size and adds a silent track. Use whenever a preview video is recorded for a store page, or when Connect refuses to accept one.
---

# AppReview

## When to use it

The moment a preview video is recorded for an App Store page — before anyone tries to
upload it. The check takes a second; a rejection costs a full round trip of upload,
refusal, re-record.

The second trigger: **Connect refused the video**. The reason is almost always one of
three, and all three are visible in a single check.

## What it is

A small AVFoundation program with two jobs:

```
./fit check clip.mov                             inspect and report what is wrong
./fit fit rec.mov out.mov 1920 1080 [seconds]    convert to the required shape
```

Build it from `templates/` with `./build.sh`. The binary is deliberately not shipped —
it is machine-specific, the source is not.

## The three reasons Connect refuses

**Frame size is not exact.** App Store accepts previews only at specific pixel
dimensions — exactly, with no "close enough". You cannot draw a selection box with
pixel precision by hand: a recording comes out at something like 2552×1432. The tool
stretches the frame to the required size; the distortion is a fraction of a percent
and invisible.

**No audio track.** A screen recording made without a microphone has no audio track at
all, and Connect answers "unsupported or corrupted audio". A silent track is fine, a
missing one is not. The tool lays in silence at 44.1 kHz, two channels.

**Duration out of range.** Fifteen to thirty seconds. Trim the tail with the sixth
argument to `fit`.

## Frame sizes

**macOS — 1920×1080**, landscape, 16:9. Verified on a shipped app.

**iOS and iPadOS sizes differ** and depend on device generation. Do not quote them from
memory — a wrong number costs another upload round. Look them up in Apple's "App preview
specifications" and pass them as numbers.

Common to every platform: 15–30 seconds, up to 30 fps, H.264 or ProRes 422 HQ, up to
500 MB, up to three previews per storefront language.

## How to record the clip

The sequence that works:

1. Play the animation in a **borderless window of the exact frame size** — then the
   window edges are the frame edges and there is no selection to aim. A title bar
   breaks the aspect ratio; it must not be there.
2. Record with `⌘⇧5`, selecting along the window edges. On a Retina display the
   recording comes out at twice the selection — that is good, downscaling costs
   nothing.
3. Start recording a couple of seconds before the animation and stop a couple of
   seconds after, or the clip easily falls short of fifteen seconds.
4. **Second five is the poster frame.** Apple takes it from there by default, so
   something meaningful should be on screen at that moment.
5. Run `fit`, read the report, upload.

## What not to do

**Do not keep raw recordings next to finished clips.** They are indistinguishable by
name, and the wrong file goes to Connect. Put recordings in a separate folder.

**Do not trust `ps` or `mdls` to describe a video file.** The first knows nothing about
video; the second sometimes returns nothing at all. Use `check`.

**Do not resize with the built-in `avconvert`.** It preserves aspect ratio and will not
invent the missing pixels: 2552×1432 becomes 1920×1076 when 1080 is required.

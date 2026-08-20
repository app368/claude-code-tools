# AppReview

Prepares recorded app previews for App Store Connect.

## The problem

App Store Connect refuses preview videos for reasons it barely explains. The frame must
be an exact pixel size — and a hand-drawn screen selection never is. A recording made
without a microphone has no audio track, and Connect calls that "unsupported or
corrupted audio". The clip must last between fifteen and thirty seconds.

Each refusal costs a round trip: upload, wait, read a terse error, re-record, guess
again.

## The fix

A small AVFoundation tool that inspects a clip and reports, in plain words, what would
stop it from being accepted — and converts a raw screen recording into a file that
Connect takes: exact frame size, silent stereo track, trimmed tail.

```
./fit check clip.mov
./fit fit rec.mov out.mov 1920 1080
```

The skill also carries the recording procedure that actually works: a borderless window
of the exact frame size, `⌘⇧5` along its edges, a couple of seconds of margin at both
ends, and something meaningful on screen at second five — the poster frame.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install appreview@claude-code-tools
```

## Build

```
cd templates && ./build.sh
```

The binary is not shipped: it is machine-specific, the source is not.

## License

MIT

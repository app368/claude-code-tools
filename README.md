# Claude Code Tools

A small marketplace of plugins for [Claude Code](https://code.claude.com), grown out of
day-to-day work on a macOS app rather than designed in the abstract. Each one removes a
specific blind spot.

## Plugins

### [ViewShot](plugins/viewshot)

Renders a single AppKit view to PNG without launching the app, so Claude can check
layout with its own eyes instead of asking you for a screenshot on every margin.

### [ChatIndex](plugins/chatindex)

Closes out a working session: dumps your own turns from the session log so no topic is
lost from the summary, and keeps apart the four things a wrap-up actually produces —
the index, the decisions, the description of what was built, and the rules for next time.

### [AppReview](plugins/appreview)

Prepares recorded app previews for App Store Connect — exact frame size, silent audio
track, duration within range — and says in plain words what is wrong, instead of leaving
you to decode a terse refusal after every upload.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install viewshot@claude-code-tools
/plugin install chatindex@claude-code-tools
/plugin install appreview@claude-code-tools
```

To try it from a local clone instead:

```
/plugin marketplace add ./claude-code-tools
```

## License

MIT

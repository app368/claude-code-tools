# Claude Code Tools

A small marketplace of plugins for [Claude Code](https://code.claude.com), grown out of
day-to-day work on a macOS app rather than designed in the abstract. Each one removes a
specific blind spot.

## Plugins

### [ViewShot](plugins/viewshot)

Renders a single AppKit view to PNG without launching the app, so Claude can check
layout with its own eyes instead of asking you for a screenshot on every margin.

## Install

```
/plugin marketplace add app368/claude-code-tools
/plugin install viewshot@claude-code-tools
```

To try it from a local clone instead:

```
/plugin marketplace add ./claude-code-tools
```

## License

MIT

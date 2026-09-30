# Agent guidance for video-hq

Video HQ is a native macOS SwiftUI/AppKit video-production app. The Swift
package, launchers and configuration live at this repo's root.

## Working here

- Use test-first development for non-trivial changes. Write or update a test
  first, then implement the change. Extract a clean test seam if needed.
- When behaviour changes, update affected tests and rerun them, including
  changes to UI copy, layout, persistence, startup and configuration.
- Test before committing. Run `swift test`, then exercise the affected app or
  script. Check exit codes. Unit tests alone do not prove playback or hardware
  behaviour.
- Keep real recordings, credentials, generated projects, build output and logs
  out of git. Keep optional API keys in this clone's `.env`.
- Avoid eyebrows and kickers in UI designs.
- Write plainly and personally, with no em dashes.
- Start PR descriptions with `## Why`, explaining what prompted the change.

## Development

```bash
swift test
bash tests/install_test.sh
bash setup_mac.sh --no-open
bash tests/setup_mac_test.sh
```

`setup_mac.sh` builds, stages, signs and registers `~/Applications/Video HQ.app`.
`install.sh` also symlinks `video-hq` into `~/.local/bin`. Reinstall after moving
the clone or changing setup environment variables. Keep the existing bundle
identifier so installed preferences continue to work.

Prompter support comes from https://github.com/mikecann/prompter-kit.
Transcription uses https://github.com/mikecann/transcribe as an external
executable, found on PATH or configured with `VIDEO_HQ_TRANSCRIBE_EXECUTABLE`.
Rough cuts use https://github.com/mikecann/automate-filmora and a locally signed-in
Codex CLI. Those are optional integrations, not sibling directories in this repo.

Keep ordinary CI tests offline: use fixture transcripts and mocked HTTP
transports, with no API calls, model downloads, signed-in Codex session or display
hardware. `tests/setup_mac_test.sh` checks a real staged application and Spotlight,
so run it locally after setup rather than in CI. Elgato Prompter placement and
Filmora export need the actual display/editor for acceptance checks.

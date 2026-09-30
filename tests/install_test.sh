#!/usr/bin/env bash
# Exercise installation in a disposable clone without signing, indexing or opening apps.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
FIXTURE="$WORK/clone with spaces & symbols"
MOCK_BIN="$WORK/mock-bin"
mkdir -p "$FIXTURE" "$MOCK_BIN" "$WORK/build"
cp "$ROOT/install.sh" "$ROOT/setup_mac.sh" "$ROOT/video-hq" "$FIXTURE/"
export VIDEO_HQ_APP_DIR="$WORK/Video HQ.app"
export VIDEO_HQ_PROJECTS_ROOT="$WORK/projects & recordings"
export VIDEO_HQ_FILMORA_AUTOMATION_ROOT="$WORK/filmora"
export VIDEO_HQ_ROUGH_CUT_PYTHON="$WORK/python"
export VIDEO_HQ_TRANSCRIBE_EXECUTABLE="$WORK/transcribe"
export VIDEO_HQ_CODESIGN_IDENTITY="-"
export VIDEO_HQ_TEST_BUILD="$WORK/build"
export VIDEO_HQ_TEST_LOG="$WORK/commands.log"
# Registering apps and indexing are OS integration checks, covered by setup_mac_test.sh.
sed -i '' \
  -e "s|^LSREGISTER=.*|LSREGISTER=\"$MOCK_BIN/lsregister\"|" \
  -e "s|/usr/bin/mdimport|\"$MOCK_BIN/mdimport\"|" \
  "$FIXTURE/setup_mac.sh"
cat > "$MOCK_BIN/swift" <<'MOCK'
#!/usr/bin/env bash
printf 'swift %s\n' "$*" >> "$VIDEO_HQ_TEST_LOG"
case "$*" in
  *--show-bin-path*) echo "$VIDEO_HQ_TEST_BUILD" ;;
  *) printf '#!/bin/bash\nexit 0\n' > "$VIDEO_HQ_TEST_BUILD/video-hq"
     chmod +x "$VIDEO_HQ_TEST_BUILD/video-hq" ;;
esac
MOCK
cat > "$MOCK_BIN/pgrep" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat > "$MOCK_BIN/mdls" <<'MOCK'
#!/usr/bin/env bash
echo '(arm64)'
MOCK
cat > "$MOCK_BIN/mdfind" <<'MOCK'
#!/usr/bin/env bash
echo "$VIDEO_HQ_APP_DIR"
MOCK
cat > "$MOCK_BIN/open" <<'MOCK'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >> "$VIDEO_HQ_TEST_LOG"
MOCK
for command_name in codesign lsregister mdimport ffmpeg; do
  cp "$MOCK_BIN/open" "$MOCK_BIN/$command_name"
done
chmod +x "$MOCK_BIN/"*
export PATH="$MOCK_BIN:$PATH"
fail() { echo "FAIL: $*" >&2; exit 1; }
# No transcribe checkout is present. Optional tools must not prevent installation.
bash "$FIXTURE/install.sh" "$WORK/user-bin" --no-open > "$WORK/install.log" 2>&1 \
  || { cat "$WORK/install.log"; fail "installer failed"; }
[[ "$(readlink "$WORK/user-bin/video-hq")" == "$FIXTURE/video-hq" ]] || fail "incorrect symlink"
PLIST="$VIDEO_HQ_APP_DIR/Contents/Info.plist"
plutil -lint "$PLIST" >/dev/null || fail "invalid app plist"
[[ "$(plutil -extract VideoHQRepoRoot raw "$PLIST")" == "$FIXTURE" ]] || fail "repo root is not this clone: expected [$FIXTURE], got [$(plutil -extract VideoHQRepoRoot raw "$PLIST")]"
[[ "$(plutil -extract VideoHQDotenvPath raw "$PLIST")" == "$FIXTURE/.env" ]] || fail "wrong dotenv path"
[[ "$(plutil -extract VideoHQProjectsRoot raw "$PLIST")" == "$VIDEO_HQ_PROJECTS_ROOT" ]] || fail "wrong projects path"
[[ "$(plutil -extract VideoHQTranscribeExecutable raw "$PLIST")" == "$VIDEO_HQ_TRANSCRIBE_EXECUTABLE" ]] || fail "wrong transcriber path"
[[ -x "$VIDEO_HQ_APP_DIR/Contents/MacOS/video-hq" ]] || fail "app binary was not staged"
# --no-open must skip the app launch while still signing and registering it.
if grep -F -x "open $VIDEO_HQ_APP_DIR" "$VIDEO_HQ_TEST_LOG" >/dev/null; then
  fail "--no-open launched the app"
fi
# A repeated install without --no-open also exercises the default launch path.
bash "$FIXTURE/install.sh" "$WORK/user-bin" > "$WORK/reinstall.log" 2>&1 \
  || { cat "$WORK/reinstall.log"; fail "repeat installer failed"; }
# Build through the installed symlink, then open an existing bundle through it.
"$WORK/user-bin/video-hq" build > "$WORK/build.log" 2>&1 \
  || { cat "$WORK/build.log"; fail "symlink build failed"; }
"$WORK/user-bin/video-hq" open
grep -F -x "open $VIDEO_HQ_APP_DIR" "$VIDEO_HQ_TEST_LOG" >/dev/null || fail "launcher did not open app"
if "$WORK/user-bin/video-hq" invalid >/dev/null 2>&1; then
  fail "invalid launcher argument was accepted"
fi
if bash "$FIXTURE/install.sh" --invalid >/dev/null 2>&1; then
  fail "invalid installer argument was accepted"
fi
echo "PASS: standalone installer, configuration and symlink launcher"

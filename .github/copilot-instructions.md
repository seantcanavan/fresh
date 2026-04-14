# Copilot Instructions

## Project Overview

`fresh` is a Go live-reload CLI tool (module: `github.com/seantcanavan/fresh/v2`). It watches a project directory for file changes and automatically rebuilds and restarts the target application. Build errors are written to a log file in `./tmp/` that web framework middleware can read and render.

## Commands

```bash
just build       # go build -o fresh .
just test        # go test ./...
just start       # go run .
just format      # go fmt ./... (alias: just fmt)
just clean       # removes ./tmp, fresh, main binaries

# Run a single test
go test ./runner/... -run TestIsWatchedFile
```

## Architecture

```
main.go                     # Parses -c flag, sets RUNNER_CONFIG_PATH, calls runner.Start()
runner/
  start.go                  # Start() — top-level init + event loop orchestration
  settings.go               # Config loading (defaults → env vars → runner.conf)
  watcher.go                # Walks root dir, sets up fsnotify watchers per directory
  build.go                  # Runs `go build -o ./tmp/runner-build <build_target>`
  runner.go                 # Executes the built binary; kills it via stopChannel
  logger.go                 # Colored per-subsystem logging (main/watcher/runner/build/app)
  utils.go                  # Path filtering: isWatchedFile, shouldRebuild, isIgnoredFolder
  limit_unix.go             # Raises RLIMIT_NOFILE to 10000 on non-Windows
  limit_windows.go          # No-op on Windows
  runnerutils/utils.go      # Public API for web framework middleware: HasErrors(), RenderError()
```

### Data flow

1. `Start()` initializes settings, log funcs, folders, env vars, then calls `watch()` and `start()`
2. `watch()` walks the root dir (skipping hidden dirs and `ignored` folders) and registers an `fsnotify` watcher on each directory
3. File events matching `valid_ext` are pushed onto `startChannel` (buffered, 1000)
4. The `start()` goroutine receives from `startChannel`, waits `build_delay` ms to batch events, then decides whether to rebuild (`shouldRebuild`) or just restart
5. On success: sends to `stopChannel` to kill the running process, then calls `run()` to start the new binary
6. On build failure: writes error text to `./tmp/runner-build-errors.log`

## Key Conventions

### Settings priority
Settings are resolved in this order (later wins):
1. Hardcoded defaults in `settings.go`
2. Environment variables with `RUNNER_` prefix (e.g., `RUNNER_BUILD_DELAY`)
3. `runner.conf` file (default path `./runner.conf`, overridable via `-c` flag or `RUNNER_CONFIG_PATH` env var)

All settings are also re-exported as `RUNNER_*` env vars so the spawned child process can read them.

### File-watching behaviour
- `valid_ext` — extensions that trigger an event (default: `.go .tpl .tmpl .html`)
- `no_rebuild_ext` — extensions that restart without a rebuild (default: `.tpl .tmpl .html`)
- `ignored` — comma-separated directory names to skip entirely (default: `assets, tmp`)
- Hidden directories (names starting with `.`) are always skipped

### runnerutils integration
`runner/runnerutils` is a separate sub-package meant to be imported by the **watched application** (not by fresh itself). It reads `RUNNER_WD`, `RUNNER_TMP_PATH`, and `RUNNER_BUILD_LOG` env vars (set by fresh) to locate the build errors log and expose it via HTTP middleware.

### Testing
Tests use table-driven style with a `[]struct{ input, expected }` slice and a loop calling `t.Errorf`. Tests live alongside the package they test (`runner/utils_test.go`).

# flash-screen

`flash-screen` is a small macOS command-line utility that briefly flashes every
attached display with a full-screen color overlay. It is implemented as a
single Swift/AppKit source file and builds to a standalone executable.

## Requirements

- macOS
- Xcode Command Line Tools, including `swiftc`

## Build

Build the binary with:

```sh
make
```

The executable is written to `./flash-screen`. Remove it with:

```sh
make clean
```

## Usage

Run the binary directly to use the defaults:

```sh
./flash-screen
```

Configuration is supplied through environment variables:

| Variable | Description | Default |
| --- | --- | --- |
| `FLASH_SCREEN_DURATION` | Fade duration for each flash, in seconds | `0.5` |
| `FLASH_SCREEN_COUNT` | Number of flashes | `2` |
| `FLASH_SCREEN_GAP` | Delay between flashes, in seconds | `0.08` |
| `FLASH_SCREEN_COLOR` | `white`, `black`, or `#RRGGBB`/`#RRGGBBAA` | `black` |

For example:

```sh
FLASH_SCREEN_COLOR=white \
FLASH_SCREEN_COUNT=3 \
FLASH_SCREEN_DURATION=0.25 \
FLASH_SCREEN_GAP=0.1 \
./flash-screen
```

Durations and gaps must be zero or greater. The flash count must be at least
one. Invalid configuration values are reported on standard error and exit with
status 2.

## How It Works

At startup, the binary reads and validates its configuration, then creates one
borderless AppKit window for each attached display. The windows are placed at
screen-saver level, made mouse-transparent, and animated from opaque to
transparent for each flash. The application exits after the final animation.

The main implementation is in [`flash-screen.swift`](flash-screen.swift), and
the [`Makefile`](Makefile) provides the build and cleanup targets.

## Releases

Merge a pull request into `main` with exactly one of these labels to create the
next version tag:

- `major-release`
- `minor-release`
- `patch-release`

The tag workflow creates a SemVer tag such as `v1.2.3`. That tag starts the
release workflow, which builds the universal macOS binary and creates a draft
pre-release on GitHub. Publish the draft when it is ready for users and binary
managers such as [`bin`](https://github.com/marcosnils/bin).

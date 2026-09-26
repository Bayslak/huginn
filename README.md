<p align="center">
  <img src="assets/huginn_logo-README.png" alt="Huginn" width="200">
</p>

# Huginn

A blazing-fast file finder for Windows, written from scratch in [Odin](https://odin-lang.org/).

Instead of walking through folders like the built-in Windows search, Huginn reads the NTFS Master File Table directly. It indexes millions of files in a few seconds and searches them instantly as you type.

Named after one of Odin's ravens, the one who flies across the nine worlds and reports back what he finds.

## Why it's fast

The built-in search is slow because it traverses directories at runtime, making one filesystem call per folder across hundreds of thousands of folders. Huginn skips the tree entirely.

On NTFS, every file and folder has one record in the Master File Table, a single flat structure holding each file's name, ID, and parent ID. Huginn reads the whole MFT in a handful of bulk operations, builds an index in RAM, and reconstructs full paths on demand by walking the parent chain. Every search after that runs in memory, so it's instant.

One big question in, one big answer out, instead of millions of small questions to the disk.

## Features

- **Instant search** across your entire drive, even with millions of files
- **Multi-volume**: indexes and searches all NTFS drives at once (C:, D:, and so on)
- **Fast indexing**: the full index builds in a few seconds by reading the MFT directly
- **Click to locate**: click any result to open its folder in Explorer. Files are revealed, never executed
- **Clean interface**: file name, path, and volume at a glance, with live indexing progress on startup

## Usage

1. Download `huginn.exe` from the [releases page](../../releases)
2. Double-click and allow the admin prompt
3. Wait a few seconds while it indexes your drives
4. Type to search, click a result to open its location

Huginn needs administrator privileges because reading the raw file table requires low-level disk access. Windows shows a UAC prompt on launch. This is expected and required.

## How it works

The project moves through a few distinct layers, each a self-contained piece:

- **Raw volume access**: opens the raw NTFS volume (`\\.\C:`) with `CreateFileW`, handling share modes and elevation
- **MFT enumeration**: sends the `FSCTL_ENUM_USN_DATA` control code via `DeviceIoControl`, then parses the packed `USN_RECORD` structures out of the returned byte buffer
- **In-memory index**: stores every record in a map keyed by file reference number, and rebuilds full paths by walking parent references up to the volume root
- **Search**: a linear substring scan over the index. On a couple million names it takes a few milliseconds, so no fancy indexing is needed
- **Interface**: an immediate-mode GUI built with raylib, with background indexing on a worker thread so the window stays responsive

## Building

Requires the [Odin compiler](https://odin-lang.org/docs/install/).

```
odin build . -out:huginn.exe -resource:huginn.rc -subsystem:windows -o:speed
```

The `-resource:huginn.rc` flag embeds the manifest (for admin elevation) and the icon into the executable. Fonts are bundled directly into the binary with `#load`, so the result is a single self-contained `.exe` with no external files.

For development, drop `-subsystem:windows` to keep the console open for debug output.

## Built with

- [Odin](https://odin-lang.org/) for everything
- Raw Win32 (`core:sys/windows`) for MFT access
- [raylib](https://www.raylib.com/) (via `vendor:raylib`) for the interface

No external dependencies. Everything ships in one executable.

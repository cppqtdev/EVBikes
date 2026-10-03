# 10 — Resources and files

How to get bytes you shipped in flash, and how to give Qt a filesystem it did
not know it had.

## Qul::BinaryResource — a blob you shipped

```cpp
#include <qul/binaryresource.h>

class Qul::BinaryResource
```

> "Interface for accessing BinaryFiles."

```cpp
BinaryResource();                      // null
BinaryResource(const char *uri);       // the resource at this path
const uchar *data() const;             // start address
size_t size() const;                   // bytes
size_t alignment() const;              // alignment of the start address
```

### Step by step

**1. Declare the file in your `.qmlproject`:**

```qml
Project {
    BinaryFiles {
        files: [ "data/lookup_table.bin", "data/boot_tune.raw" ]
    }
}
```

**2. Open it in C++:**

```cpp
#include <qul/binaryresource.h>

Qul::BinaryResource table("data/lookup_table.bin");

const uint8_t *bytes = table.data();
size_t         n     = table.size();
```

### What this is actually for

The data is **already in flash**, mapped, addressable. `data()` is a pointer
to it. There is no read, no copy, no buffer to allocate — you are reading the
binary itself.

So it is perfect for anything large and constant: calibration tables, lookup
curves, font blobs you handle yourself, audio samples, a licence text.

Check `alignment()` before casting the pointer to a struct or a `uint32_t *`.
Flash does not care; your CPU does.

### Versus a C array

You could write `static const uint8_t kTable[] = { ... }` in a header. For a
few hundred bytes, do that — it is simpler.

`BinaryResource` wins when the data is big, when it is produced by a tool
rather than hand-written, or when you want to swap it without recompiling the
C++. A 200 KB table as a C array is a miserable compile.

## Qul::ResourceStorageSectionInfo — resource versioning

```cpp
struct Qul::ResourceStorageSectionInfo

int applicationMajorVersion;
int applicationMinorVersion;
int resourceMajorVersion;
int resourceMinorVersion;
```

Metadata about a resource storage section: which application build it was made
for, and what version the resource data itself is.

The point of the two pairs is **over-the-air updates**. If resources live in
their own flash section, you can ship new art without reflashing the
application — but only if the versions are compatible. These fields are how
that check is made.

If you are not doing OTA resource updates, you will never touch this.

## Filesystem and File — a real filesystem

These two live in `Qul::PlatformInterface`, but they are reached through
`Qul::Application`, so they belong in this chapter.

```cpp
// Qul::PlatformInterface::Filesystem
// "provides an abstract API to implement custom file systems"

// Qul::PlatformInterface::File
// "provides an abstract API to implement access to files"

Qul::Application::addFilesystem(Qul::PlatformInterface::Filesystem *filesystem);
```

Implement these when your images, fonts or data live somewhere Qt cannot see by
itself: an SD card, external QSPI flash with a FAT volume, a network share.
Once registered, ordinary QML `source:` paths can refer to files there.

Most projects never need it. Everything compiled into the binary is reachable
through `qrc:` without a filesystem at all.

## ImageDecoder — a format Qt does not know

```cpp
// Qul::PlatformInterface::ImageDecoder
// "provides an abstract API to implement custom image decoders"

Qul::Application::addImageDecoder(Qul::PlatformInterface::ImageDecoder *imagedecoder);
```

Register one when you need to decode a format the build-time pipeline does not
handle, or when images arrive at runtime already compressed — a JPEG from a
camera, a PNG pulled over the link.

Note the division of labour: images you ship are decoded **at build time** by
`qulrcc` and stored ready to draw. An `ImageDecoder` is only for pixels that
show up while the program is running.

## The decision

| Where the bytes are | Use |
|---|---|
| Compiled into the binary, used by QML | `qrc:` path, nothing to write |
| Compiled into the binary, used by C++ | `BinaryResource` + `BinaryFiles` |
| On an SD card or external flash | implement `Filesystem` and `File` |
| Arriving at runtime, compressed | implement `ImageDecoder` |
| Updated separately from the firmware | resource sections, `ResourceStorageSectionInfo` |

## Traps

**You forget `BinaryFiles` in the `.qmlproject`.** The `BinaryResource` is
null. Check `size()` before using `data()`.

**You cast `data()` to a struct pointer without checking `alignment()`.**
Works until it does not.

**You expect `BinaryResource` to be writable.** It points into flash. It is
read-only, and on most parts a write will fault.

**You implement a `Filesystem` for files you could have compiled in.** Shipped
data belongs in the binary: no mount, no failure mode, no startup cost.

## Check it yourself

Every `BinaryResource` path should appear in a `BinaryFiles` block:

```bash
grep -rhoE 'BinaryResource\("[^"]+"' --include='*.cpp' . | cut -d'"' -f2 | sort -u
grep -A10 "BinaryFiles" */*.qmlproject
```

Anything in the first list and missing from the second is a null resource at
runtime.

## Sources

- [Qul::BinaryResource](https://doc.qt.io/QtForMCUs/qul-binaryresource.html)
- [Qul::ResourceStorageSectionInfo](https://doc.qt.io/QtForMCUs/qul-resourcestoragesectioninfo.html)
- [Qul::PlatformInterface::Filesystem](https://doc.qt.io/QtForMCUs/qul-platforminterface-filesystem.html)
- [Qul::PlatformInterface::ImageDecoder](https://doc.qt.io/QtForMCUs/qul-platforminterface-imagedecoder.html)
- [Managing resources](https://doc.qt.io/QtForMCUs/qtul-resources.html)

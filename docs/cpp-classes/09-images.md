# 09 — Images from C++

Five classes, two jobs: **hand pixels to QML**, or **draw an item yourself**.

```
Qul::Image            pixel buffer you own
Qul::SharedImage      what QML properties actually hold
Qul::ImageWriteGuard  RAII around editing an Image
Qul::ImageProvider    serve images by URL from C++
Qul::PaintedItemDelegate   draw an item with your own code
```

## Qul::Image — a buffer you own

```cpp
#include <qul/image.h>

struct Qul::Image
```

> "An image representation that allows direct access to the pixel data."

```cpp
Image();
Image(int width, int height, Qul::PixelFormat pixelFormat);
Image(uint8_t *bits, int width, int height, Qul::PixelFormat pixelFormat,
      int bytesPerLine = -1, CleanupFunction cleanupFunction = nullptr);

uint8_t *bits();
int width() const;
int height() const;
int bytesPerLine() const;
int bitsPerPixel() const;
Qul::PixelFormat pixelFormat() const;

void reallocate(int width, int height, Qul::PixelFormat pixelFormat);
void beginWrite();
void endWrite();

operator Qul::SharedImage() const;

static const uintptr_t requiredAlignment;
static const uintptr_t requiredPixelWidthAlignment;
```

Two ways to make one:

**Let it allocate** — `Image(w, h, format)`. Simple, but it allocates.

**Wrap memory you already have** — the `uint8_t *bits` constructor. This is the
one you usually want on an MCU: a camera DMA buffer, a decode target in a
specific RAM section, a static array you placed deliberately.

```cpp
alignas(32) static uint8_t g_cameraBuffer[320 * 240 * 2];

Qul::Image cameraImage(g_cameraBuffer, 320, 240, Qul::PixelFormat_RGB16);
```

### The pixel formats, by their real names

Worth printing, because the names are not the ones you would guess — there is
no `PixelFormat_RGB565`; the 16-bit one is called `RGB16`.

```
Qul::PixelFormat_ARGB32_Premultiplied        4 bytes
Qul::PixelFormat_ARGB32                      4 bytes
Qul::PixelFormat_RGB32                       4 bytes
Qul::PixelFormat_RGB16                       2 bytes
Qul::PixelFormat_ARGB4444_Premultiplied      2 bytes
Qul::PixelFormat_ARGB4444                    2 bytes
Qul::PixelFormat_RGB332                      1 byte
Qul::PixelFormat_Alpha8                      1 byte
Qul::PixelFormat_Alpha1                      1 bit
Qul::PixelFormat_RLE_ARGB32
Qul::PixelFormat_RLE_ARGB32_Premultiplied
Qul::PixelFormat_RLE_RGB32
Qul::PixelFormat_RLE_RGB888
Qul::PixelFormat_Custom
Qul::PixelFormat_Invalid
```

The byte counts are the thing to keep in your head: a buffer costs
`width x height x bytes`, and that is memory you will not get back. Choosing
`Alpha8` over `ARGB32` for a mask is a straight four-times saving.

Mind those two static members. Buffers have alignment requirements, and
ignoring them gets you a corrupted image or a fault, depending on the chip.

## Qul::SharedImage — what the property holds

```cpp
#include <qul/image.h>      // same header

struct Qul::SharedImage
```

> "Used to pass memory buffers with image data to QUL elements for drawing."
> "Properties like `Image.source` have the type `Property<SharedImage>`."

```cpp
Qul::Image *image() const;
operator bool() const;
Qul::PlatformInterface::Texture texture(int textureIndex = 0) const;  // since 2.2
int textureCount() const;                                             // since 2.2
bool maybeTexture(Qul::PlatformInterface::Texture &texture,
                  int textureIndex = 0) const;                        // since 2.12
```

The relationship is simple:

> "Image implicitly converts to SharedImage."

So you work with `Qul::Image`, and hand it over wherever a `SharedImage` is
wanted. You rarely construct a `SharedImage` yourself.

## Qul::ImageWriteGuard — edit safely

```cpp
#include <qul/image.h>

struct Qul::ImageWriteGuard
```

> "A helper for calling Image::beginWrite() and Image::endWrite()"

If you write into an image's pixels while the renderer might be reading them,
you get tearing. `beginWrite()` and `endWrite()` bracket the edit. The guard
does it with RAII so you cannot forget the second half:

```cpp
{
    Qul::ImageWriteGuard guard(cameraImage);
    memcpy(cameraImage.bits(), newFrame, frameSize);
}   // endWrite() happens here, even on an early return
```

Move-constructible, not copyable. Use the guard rather than the raw calls.

## Qul::ImageProvider — serve images by URL

```cpp
#include <qul/imageprovider.h>

struct Qul::ImageProvider
```

> "Provides an interface for supporting image requests in QML."

```cpp
virtual Qul::SharedImage requestImage(const char *uri, size_t uriLength) = 0;
```

### Step by step

**1. Implement it:**

```cpp
struct CameraProvider : public Qul::ImageProvider
{
    Qul::SharedImage requestImage(const char *uri, size_t uriLength) override
    {
        if (uriLength == 4 && memcmp(uri, "live", 4) == 0)
            return cameraImage;
        return Qul::SharedImage();        // falsy: nothing to draw
    }
};
```

**2. Register it, keeping it alive:**

```cpp
static CameraProvider g_cameraProvider;
Qul::Application::addImageProvider("camera", &g_cameraProvider);
```

**3. Ask for it in QML:**

```qml
Image { source: "image://camera/live" }
```

The provider id is the host part. **The `uri` you receive is everything after
it** — for `"image://camera/live"` you get `"live"`, not the whole string.

### Asynchronous loading

If the image is not ready yet, the docs describe calling `Image::beginWrite()`
before returning and `Image::endWrite()` when the data arrives — posting the
completion through an `EventQueue` so it lands on the main loop.

### When you reach for it

When the pixels are not known at build time: a camera feed, a downloaded
image, a frame you decoded yourself. For art you ship with the binary, use an
ordinary `Image { source: "qrc:/..." }` — that path is compiled in and costs
nothing at runtime.

## Qul::PaintedItemDelegate — draw it yourself

```cpp
#include <qul/painteditemdelegate.h>

class Qul::PaintedItemDelegate : public Qul::Object
```

> "Base class for representing painted item objects."

```cpp
// both are pure virtual and const; namespaces abbreviated here for width,
// they are all Qul::PlatformInterface::
virtual Rect boundingRect(Size size) const = 0;
virtual void paint(DrawingDevice *device, const Rect &clip,
                   const Transform &transform, Size size,
                   float opacity) const = 0;

void update();
void update(int x, int y, int width, int height);
```

It pairs with the **`PaintedItem`** QML type. You implement `paint()` and draw
with the platform context or straight into the framebuffer; call `update()`
when what you would draw has changed.

### When you reach for it

Rarely, and that is the point. Reach for it when the thing genuinely cannot be
expressed as images and QML items — a waveform, a live plot, a radar sweep.

For anything static or semi-static, pre-rendered art is cheaper and sharper:
a `paint()` runs every frame it is dirty, on the CPU, whereas an image is a
blit. This project draws its gauges as pre-rendered layers for exactly that
reason and has no painted items at all.

Use `update(x, y, w, h)` rather than `update()` when only part changed. The
difference is real on a large item.

## Choosing

| You have | Use |
|---|---|
| Art you ship in the binary | plain QML `Image` with a `qrc:` source |
| A buffer filled by DMA or a decoder | `Qul::Image` wrapping it, via an `ImageProvider` |
| Pixels that change while on screen | `Image` + `ImageWriteGuard` |
| Something that must be drawn procedurally | `PaintedItemDelegate` |

## Traps

**Your provider outlives nothing.** The application does not take ownership.
A provider on the stack is a dangling pointer. Make it static.

**You parse the full URL in `requestImage`.** You get the part after the
provider id, not `image://...`.

**You write pixels without the guard.** Tearing, intermittently, worse under
load — the kind of bug that looks like a renderer problem.

**You ignore `requiredAlignment`.** Works on one chip, faults on another.

**You use a `PaintedItemDelegate` for something an image could do.** You pay
the drawing cost on every dirty frame, forever.

## Check it yourself

Providers must be statics:

```bash
grep -rn "addImageProvider\|Qul::ImageProvider" --include='*.cpp' .
```

And confirm every `image://` URL in QML has a provider registered under that
id:

```bash
grep -rhoE 'image://[a-z]+' qml --include='*.qml' | sort -u
```

## Sources

- [Qul::Image](https://doc.qt.io/QtForMCUs/qul-image.html)
- [Qul::SharedImage](https://doc.qt.io/QtForMCUs/qul-sharedimage.html)
- [Qul::ImageWriteGuard](https://doc.qt.io/QtForMCUs/qul-imagewriteguard.html)
- [Qul::ImageProvider](https://doc.qt.io/QtForMCUs/qul-imageprovider.html)
- [Qul::PaintedItemDelegate](https://doc.qt.io/QtForMCUs/qul-painteditemdelegate.html)

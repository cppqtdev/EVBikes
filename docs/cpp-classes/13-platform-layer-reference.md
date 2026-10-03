# 13 — The platform layer, class by class

Everything in `Qul::PlatformInterface`, `Qul::Platform` and `Tvii`. Fifty-eight
classes.

**You almost certainly do not need to write any of these.** If you bought a
board Qt supports, the port exists and these are already implemented. They
matter in three situations:

1. You are bringing Qt up on a board with no port
2. You are writing a `PaintedItemDelegate` and need the drawing types
3. You are reading a stack trace and want to know what a name means

The descriptions below are the ones Qt's own reference gives.

## Qul::PlatformInterface

### Drawing

| Class | What it is |
|---|---|
| `DrawingDevice` | "defines a device which can be drawn onto" |
| `DrawingEngine` | "provides an abstract interface for blending functions" |
| `Brush` | "Represents the fill pattern of shapes drawn using DrawingEngine" |
| `LinearGradient` | "Represents a linear gradient used by Brush" |
| `GradientStop` | "Represents a single gradient stop in a gradient" |
| `GradientStops` | "Represents a set of stop points used to define the color transitions of gradients" |
| `Texture` | "A class containing information about a texture" |
| `PixelDataPointer` | "A structure containing information about precise (bit perfect) pixel data location" |
| `Rgba32` | "provides storage space for RGBA colors" |

`DrawingDevice` is the one you meet first: it is the parameter to
`PaintedItemDelegate::paint()`, and it is how you reach the framebuffer.

### Geometry

| Class | What it is |
|---|---|
| `Point` | "defines a point in the plane using integer precision" |
| `PointF` | "defines a point in the plane using floating point precision" |
| `Rect` | "defines a rectangle in the plane using integer precision" |
| `RectF` | "defines a rectangle in the plane using floating point precision" |
| `Size` | "defines the size of a two-dimensional object using integer point precision" |
| `SizeF` | "defines the size of a two-dimensional object using floating point precision" |
| `Transform` | "specifies 2D transformations of a coordinate system" |
| `GenericMatrix` | "a template class representing a matrix" |

The plain Qt geometry types, without Qt Core. You will use `Rect`, `Size` and
`Transform` in any custom painted item.

### Vector paths

Thirteen of the fifty-eight classes are path segments. They are the pieces a
vector shape is decomposed into before stroking or filling.

| Class | What it is |
|---|---|
| `PathData` | "represents vector path data" |
| `PathDataSegment` | "Represents a single path data segment of the PathData class" |
| `PathDataIterator` | "A convenience class for iterating over path data segments" |
| `PathDataMoveSegment` | "Represents a path data move segment" |
| `PathDataLineSegment` | "Represents a path data line segment" |
| `PathDataQuadraticBezierSegment` | "Represents a path data quadratic bezier segment" |
| `PathDataCubicBezierSegment` | "Represents a path data cubic bezier segment" |
| `PathDataArcSegment` | "Represents a path data arc segment" |
| `PathDataSmallClockWiseArcSegment` | "Represents a path data small clockwise arc segment" |
| `PathDataSmallCounterClockWiseArcSegment` | "Represents a path data small counterclockwise arc segment" |
| `PathDataLargeClockWiseArcSegment` | "Represents a path data large clockwise arc segment" |
| `PathDataLargeCounterClockWiseArcSegment` | "Represents a path data large counterclockwise arc segment" |
| `PathDataPathSeparatorSegment` | "Represents a path data path separator segment" |
| `PathDataStroker` | "generates stroke representation for a shape" |
| `DefaultPathDataStroker` | "provides a default implementation of PathDataStroker" |

The four arc variants exist because an SVG arc needs two flags — large or
small sweep, clockwise or counter — and encoding them as separate types keeps
the segment data flat and branch-free.

**You meet these only if you implement a custom stroker or walk a path by
hand.** Using `Shapes` in QML does not require touching them.

### Layers and memory

| Class | What it is |
|---|---|
| `LayerEngine` | "provides an abstract interface for managing hardware layers" |
| `MemoryAllocator` | "provides an abstract interface for memory allocation" |
| `Allocator` | "A memory allocator for use with the C++ standard containers" |

`LayerEngine` is the interesting one on a board with hardware layers: it is
where on-the-fly rendering versus a framebuffer is actually decided. The
choice costs more memory than everything else in your application combined —
327,680 bytes versus 4,915,200 for a 1280×480 screen at 32 bpp.

### Files, images, time, input

| Class | What it is |
|---|---|
| `Filesystem` | "provides an abstract API to implement custom file systems" |
| `File` | "provides an abstract API to implement access to files" |
| `ImageDecoder` | "provides an abstract API to implement custom image decoders" |
| `DateTime` | "provides a native representation of data and time values in milliseconds" |
| `Screen` | "holds information about display size in pixels" |
| `TouchPoint` | "Represents single touch point" |
| `StrokeProperties` | "A struct specifying the stroke properties of a path" |

`Filesystem`, `File` and `ImageDecoder` are registered through
`Qul::Application` — see chapter 10.

## Qul::Platform

The lower half of the port: how the framebuffer is described, how frames are
transferred, how the host talks to the device.

| Class | What it is |
|---|---|
| `PlatformContext` | "provides an abstract interface to implement platform context" |
| `Config` | "provides runtime representation of platform configuration" |
| `FramebufferFormat` | "contains information about a framebuffer" |
| `FramebufferDataChunk` | "contains information about framebuffer data chunks" |
| `ChunkedFramebufferDataTransferSizes` | "contains information about chunked framebuffer data transfer sizes" |
| `FrameStatistics` | "Provides frame rendering statistics" |
| `PerformanceMetrics` | "Provides performance metrics" |
| `MessageQueue` | "A convenience class used to interface with the queue implementation" |
| `MessageQueueInterface` | "Interface class providing platform-specific queues to Qt Quick Ultralite" |
| `DeviceLink` | "provides functionality for communication between host and device" |
| `DeviceLinkInterface` | "This provides the interface to implement by the platform" |
| `SinglePointTouchEvent` | "contains information related to a single point touch event" |
| `SinglePointTouchEventDispatcher` | "A convenience class for handling single point touch from the platform" |
| `StackAllocator` | "Provides a simple memory allocator for functions that might temporarily require some extra memory for caching" |

`PlatformContext` is the root of a port — bring-up starts by implementing it.

`FrameStatistics` and `PerformanceMetrics` are the two you might use without
porting anything: they are what the profiling overlay reads. If
`QUL_ENABLE_PERFORMANCE_LOGGING` prints numbers on your board, these produced
them.

`MessageQueueInterface` is what `Qul::EventQueue` (chapter 6) sits on top of.
On an RTOS the port maps it to the RTOS's own queues, which is why the queue
is thread-safe there and merely interrupt-safe on baremetal.

## Tvii — TRAVEO T2G

| Namespace | Entry | What it is |
|---|---|---|
| `Tvii::Configuration` | `Config` | platform configuration for the TRAVEO port |
| `Tvii::Warping` | `WarpInfo` | display warping information |

These exist only in the Cypress TRAVEO T2G port. `WarpInfo` describes geometric
warping — correcting for a display that is not flat, or is viewed at an angle,
which is common in a motorcycle or automotive cluster where the glass is
curved.

## The practical summary

| If you are | You care about |
|---|---|
| Writing an application | nothing in this chapter |
| Writing a custom painted item | `DrawingDevice`, `Rect`, `Size`, `Transform`, `Rgba32` |
| Adding an SD card or external flash | `Filesystem`, `File` |
| Decoding images at runtime | `ImageDecoder` |
| Tuning memory on a board with layers | `LayerEngine` |
| Measuring performance | `FrameStatistics`, `PerformanceMetrics` |
| Porting to a new board | `PlatformContext` first, then the rest |
| On a curved TRAVEO display | `Tvii::Warping::WarpInfo` |

Everything else is implemented for you by the port, and the right amount of
attention to give it is none.

## Sources

- [Qul::PlatformInterface](https://doc.qt.io/QtForMCUs/qul-platforminterface.html)
- [Qul::Platform](https://doc.qt.io/QtForMCUs/qul-platform.html)
- [Qt Quick Ultralite Platform Porting Guide](https://doc.qt.io/QtForMCUs/qtul-platform-porting-guide-topic.html)
- [Layer and VRAM optimization — TRAVEO T2G](https://doc.qt.io/QtForMCUs/qtul-t2g-layer-vram-guide.html)

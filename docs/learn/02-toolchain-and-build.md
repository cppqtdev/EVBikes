# 02 — Toolchain and build

A Qt for MCUs build is five tools in a row. When something fails, the first
useful question is *which one*. The error text usually tells you if you know
the names.

## The pipeline

```
 .qmlproject ──► qmlprojectexporter ──► per-module build files
                        │
      your .qml ────────┼──► qmltocpp ──────────► generated C++  ──┐
                        │                                          │
    your images ────────┼──► qulrcc ────────────► resource blobs ──┼──► linker ──► binary
                        │                                          │
     your fonts ────────┼──► qulfontcompiler ───► glyph data  ─────┤
                        │                                          │
  interface headers ────┴──► qmlinterfacegenerator ► QML shims ────┘
```

Each runs **per module**, then the root project merges the lot. That merge step
is where a surprising number of errors actually come from — see "one module
owns an image" below.

### Who produces which error

| The message mentions | The tool | Typical cause |
|---|---|---|
| `error: ... could not be found in the include paths` | `qmltocpp` | A module is missing from `MCU.qulModules` or `ModuleFiles` |
| `Functions cannot be used as values` | `qmltocpp` | You used a Qt Quick property Ultralite does not have |
| `could not load value of ambiguous type` | `qmltocpp` | A ternary mixing an enum constant with an `int` |
| `Type <X> does not have a property <y>` | `qmltocpp` | Reading something the Ultralite type lacks |
| undefined `qul_rasterBuffer_*_handle` at link | `qulrcc` + linker | An image declared in two modules, or in none |
| undefined glyph / raster symbols at link | the linker | `ASM` missing from `project(... LANGUAGES ...)` |
| `Font.DemiBold` undefined | `qulfontcompiler` | A weight enum only the Spark engine has |

That last column is the part worth memorising. The tool names turn a wall of
template spew into a one-line diagnosis.

## The .qmlproject, honestly

`.qmlproject` is not a project file in the IDE sense. It is the **input to code
generation**, and its contents directly decide what ends up in your binary.

```qml
import QmlProject 1.3

Project {
    mainFile: "qml/Main.qml"
    qtForMCUs: true
    projectRootPath: "."

    MCU.Config {
        fontEngine: "Static"
        defaultFontFamily: "Inter"
        addDefaultFonts: false
        autoGenerateGlyphs: true
        Experimental.mergeStaticTextGlyphs: true
        maxResourceCacheSize: [[16777216, 1], [16777216]]
    }

    QmlFiles  { files: ["qml/Main.qml"] }
    ImageFiles { files: ["assets/icons/32/tt_abs.png"] }
    FontFiles { files: ["assets/fonts/Inter-Regular.ttf"] }

    ModuleFiles {
        files: ["qml/core/core.qmlproject", "qml/components/components.qmlproject"]
        MCU.qulModules: ["Shapes"]
    }
}
```

Three things to notice.

**`MCU.qulModules` costs flash.** `Shapes` brings a vector rasteriser and its
buffers. `Controls` brings the StyleDefault set. Only list what you draw with.

**Modules are a real boundary.** A module is its own `.qmlproject` with its own
`QmlFiles` and `ImageFiles`. Dependencies are listed in `ModuleFiles`.

**One module owns an image.** This one is worth its own section.

## One module owns an image

The rule, learned the hard way:

> A module must declare **every** image its own QML names — it does *not*
> inherit a dependency's images — **and** no image may be declared in two
> modules.

Break the first half and `qmltocpp` fails. Break the second half and it builds,
then fails at link with an undefined `qul_rasterBuffer_<name>_handle`, because
the merged `qulrcc` output kept one declaration and dropped the other.

Both halves at once means: if two modules want the same picture, you cannot
just list it twice. Put the image in **one** module, wrap it in a component
there, and have the other module use the component.

In this project the fix was `qml/components/GlowSpot.qml` — a one-element
component whose only job is to be the single owner of a glow image that two
modules wanted.

I got this rule wrong first time and asserted the opposite (that `ModuleFiles`
made a dependency's images visible). It cost two failed builds. The behaviour
above is what the build actually does.

## Generate the project files, don't hand-edit them

Once you have more than a couple of modules, keeping `QmlFiles`, `ImageFiles`
and `CMakeLists.txt` in step by hand stops working. Every new QML file is three
edits in three places, and the failure mode is a link error far from the cause.

Generate them. In this project `tools/sync_project_files.py` walks the tree and
writes every `.qmlproject` and `CMakeLists.txt`, and refuses when two modules
name the same image — the rule above, enforced instead of remembered.

It also decides each image's pixel format by **looking at the pixels** rather
than at the file name:

```python
def alpha_only(path):
    """True when every visible pixel is pure white, so the image is a mask."""
```

That matters because a mask stored as Alpha8 costs one byte a pixel and a full
colour image costs four. Guessing from the file name gets it wrong, silently,
in the expensive direction.

## Build profiles

The same QML usually has to build for more than one target: a desktop platform
for iteration, and the board. Those want different resource settings.

```cmake
set(EVB_QML_PROJECT EVBikes.qmlproject)
if(EVB_PLATFORM_LOWER MATCHES "^tviic2d")
    set(EVB_QML_PROJECT profiles/traveo/EVBikes.qmlproject)
endif()
```

The board profile differs only in resource placement:

```qml
MCU.resourceCompression: false
MCU.resourceCachePolicy: "NoCaching"
MCU.resourceStorageSection: "QulResourceDataInExternalFlash"
```

Resources live in external flash and are read in place, so there is no point
compressing them and no cache to fill. On desktop the opposite is true. Same
QML, different profile — and the profile files are generated too, so they
cannot drift.

## The CMake trap

```cmake
project(EVBikes VERSION 0.1.0 LANGUAGES C CXX ASM)
```

**`ASM` is not optional.** `qulrcc` and `qulfontcompiler` emit `.S` blobs. With
no `ASM` language enabled, CMake silently drops those files — no warning, no
error — and you get undefined glyph and raster symbols at link time with
nothing pointing at the cause.

## Check it yourself

Which tools actually ran, and what they produced:

```
find build -name "*.S" -o -name "*qulrcc*" -o -name "*Font*" | xargs ls -lS | head
```

What is in your binary, by section:

```
size build/<your-config>/<target>
```

Does anything declare an image twice?

```
grep -rho 'assets/[^"]*\.png' qml/*/*.qmlproject | sort | uniq -d
```

The last one should print nothing. If it prints anything, you have a link error
waiting.

## Sources

- [Managing resources](https://doc.qt.io/QtForMCUs/qtul-resources.html)
- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)

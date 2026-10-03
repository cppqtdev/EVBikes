# The Qt for MCUs C++ classes — a working guide

Every class Qt for MCUs gives you, what it is for, and how to actually wire it
to QML. Written for someone who has never used the C++ side before.

Checked against the Qt for MCUs 2.12 reference and against one real instrument
cluster that uses these classes in anger.

The same material as a single browsable page, with the diagrams:
https://claude.ai/artifact/HgnTBwD3zti4MVe88JLhCE

## Start here if you are new

Read chapters 1 to 4 in order. That is about an hour, and after it you can put
a number from C++ onto the screen and get a button press back. Everything else
in this guide is something you reach for later, when a specific need shows up.

| | Chapter | You will be able to |
|---|---|---|
| 1 | [How C++ reaches QML](01-how-cpp-reaches-qml.md) | Explain the whole mechanism, and write your first backend header |
| 2 | [Object and Singleton](02-object-and-singleton.md) | Choose between one shared instance and many |
| 3 | [Property](03-property.md) | Push live values to the screen |
| 4 | [Signal](04-signal.md) | Tell QML that something happened |
| 5 | [ListModel and ListProperty](05-listmodel-and-listproperty.md) | Feed a repeating list |
| 6 | [EventQueue](06-eventqueue.md) | Cross an interrupt or thread boundary safely |
| 7 | [Timer](07-timer.md) | Run something every N milliseconds |
| 8 | [Application and startup](08-application-and-startup.md) | Own `main()` and configure the engine |
| 9 | [Images](09-images.md) | Supply pixels from C++, or draw an item yourself |
| 10 | [Resources and files](10-resources-and-files.md) | Read a binary blob you shipped in flash |
| 11 | [String, Status, Flags](11-helpers.md) | Use the small helper types correctly |
| 12 | [Location and maps](12-location-and-maps.md) | Feed GPS and map tiles |
| 13 | [The platform layer](13-platform-layer-reference.md) | Know what every porting class is, and when it is yours to write |
| 14 | [Putting it together](14-putting-it-together.md) | Build a complete backend from nothing |

## The whole class list, at a glance

There are three namespaces and they are aimed at different people.

**`Qul`** — the application API. Twenty-five classes. **This is your namespace.**
Chapters 1 to 12 cover all of it.

**`Qul::PlatformInterface`** — forty-two classes. The porting layer: drawing
engine, layers, memory, geometry, path data. You touch these when you bring Qt
up on a board that has no port yet, or write a custom painted item.

**`Qul::Platform`** — fourteen classes. Framebuffer description, touch
dispatch, message queues, performance counters. Also porting.

**`Tvii`** — Cypress TRAVEO T2G specifics. Two entries.

Chapter 13 lists every class in the last three with what it does, so nothing
here is a mystery even if you never implement one.

## How each chapter is written

- **What it is** in one or two sentences, no jargon
- **When you reach for it**, and when you should not
- **The benefit** — what it buys you over doing it another way
- **Step by step**, from the header to the QML, with code that compiles
- **Traps** that cost real time, and how to see them coming
- **From this project** — the same class as it is actually used in EVBikes

Code marked *from this project* is copied out of the repository, not invented.

## One rule before you start

Qt for MCUs has no heap and no JavaScript engine. Every C++ object you expose
is laid out at build time. That single fact explains most of what follows: why
you declare properties instead of returning values, why a model's size is
awkward, why there is an `EventQueue` with a fixed capacity. Keep it in mind
and the API stops looking strange.

## Sources

Every chapter ends with links to the Qt documentation pages it draws on. The
index for all of it is
[C++ Classes and Namespaces](https://doc.qt.io/QtForMCUs/qtul-cppclasses.html).

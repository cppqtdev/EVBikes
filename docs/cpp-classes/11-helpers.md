# 11 — String, Status and Flags

Three small types. Each solves one problem, and each has a sharp edge.

## Qul::String

```cpp
#include <qul/unicodestring.h>      // note: not qul/string.h

class Qul::String
```

> "The String class is designed as an interface type. Its main use case is as a
> function parameter type. It allows a single function to accept a wide variety
> of string data sources."

```cpp
String();                                  // empty latin1, length 0
String(const char *utf8);                  // a VIEW on a UTF-8 string
String(const std::string &value);          // needs QUL_STD_STRING_SUPPORT
String(const Qul::StdStringType &value);   // needs QUL_STD_STRING_SUPPORT
```

### What it is for

**Function parameters.** One function that accepts a literal, a `std::string`,
or a buffer, without an overload for each:

```cpp
void setRoadName(Qul::String name);

setRoadName("Ring Road");
setRoadName(decodedStdString);
```

### The sharp edge

> The UTF-8 constructor creates "a view on a UTF-8 string" that **"does not own
> the data"**.

So this is a bug:

```cpp
Qul::String makeLabel()
{
    char buf[32];
    formatInto(buf);
    return Qul::String(buf);     // buf dies here; the String points at it
}
```

Treat `Qul::String` like `std::string_view`: fine as a parameter, dangerous as
a return value or a stored member, unless you are certain the bytes outlive it.

For **storage**, use `std::string` in your property, as this project does:

```cpp
Qul::Property<std::string> roadName;
```

And note the `std::string` constructors need `QUL_STD_STRING_SUPPORT` defined
in the core library. If they do not compile, that is why.

## Qul::Status

```cpp
template <typename ErrorEnum> class Qul::Status      // since 2.10
```

> "Encapsulates the result of a function that might succeed or fail with an
> error code."

```cpp
Status();                      // success
Status(ErrorEnum error);       // failure
bool hasError() const;
ErrorEnum error() const;       // only valid when hasError()
void setError(ErrorEnum error);
void clearError();
operator bool() const;         // true on success
```

### What it is for

Returning "it worked" or "it failed, and here is why", without exceptions —
which you do not have on an MCU — and without the classic `return -1` where
the caller has to look up what −1 meant.

```cpp
enum class MountError { None, NoCard, BadFormat, Timeout };

Qul::Status<MountError> mountCard();

if (auto st = mountCard(); !st)
    log(st.error());
```

`operator bool()` is **true on success**. Read that twice — it is the opposite
of a plain integer return code, and mixing the two conventions in one codebase
is how you ship an inverted check.

Since 2.10, so confirm your version before using it.

## Qul::Flags

```cpp
template <typename Enum> class Qul::Flags           // since 2.12
```

> "The Flags class provides a type-safe way to store OR and AND combinations of
> enum values."

```cpp
bool testFlag(Enum flag);
void setFlag(Enum flag, bool on);
auto toUnderlyingType();
// plus |  &  |=  &=  and a bool conversion
```

### What it is for

Bitmasks that the compiler checks. A raw `uint32_t` of flags accepts any
integer, including one from a different enum; `Flags<Enum>` does not.

```cpp
enum Telltale { Abs = 1, Airbag = 2, LowFuel = 4, HighBeam = 8 };

Qul::Flags<Telltale> lamps;
lamps.setFlag(Abs, true);
if (lamps.testFlag(LowFuel)) { ... }
```

Since 2.12, so it is new. On 2.11 and earlier you write the bit twiddling by
hand — which is what this project does, with a `uint32_t telltaleFlags`
property read in QML as `(VehicleData.telltaleFlags & (1 << index)) !== 0`.

That is worth noting: a single flags property is cheaper than one boolean
property per lamp, because it is one value for the engine to track instead of
sixteen.

## A note on the headers

The Qt documentation shows `#include <Status>` and `#include <Flags>` for these
two — module-style includes rather than a path. `Qul::String` is documented as
`#include <qul/unicodestring.h>`, which is not the name most people guess.

**Confirm the real header in your own installation before you include it:**

```bash
grep -rln "class Status\|class Flags\|class String" ~/QtForMCU/QtMCUs/*/include/qul/
```

Getting a header name wrong stops the build, and an invented include cost this
project a build round once already. Thirty seconds of grep is cheaper.

## Traps

**You store a `Qul::String` built from a temporary.** Dangling view.

**You read `error()` without checking `hasError()`.** The value is only
meaningful when there is an error.

**You treat `Status`'s `operator bool()` as "has error".** It is "succeeded".

**You use `Flags` or `Status` on an older release.** 2.12 and 2.10
respectively.

**You guess the header.** See above.

## Sources

- [Qul::String](https://doc.qt.io/QtForMCUs/qul-string.html)
- [Qul::Status](https://doc.qt.io/QtForMCUs/qul-status.html)
- [Qul::Flags](https://doc.qt.io/QtForMCUs/qul-flags.html)

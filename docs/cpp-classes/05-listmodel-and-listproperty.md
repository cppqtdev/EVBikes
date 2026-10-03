# 05 — Qul::ListModel and Qul::ListProperty

For when you have *several* of something and QML needs to repeat over them.

## Qul::ListModel — rows for a view

```cpp
#include <qul/model.h>

template <typename T> struct Qul::ListModel
```

> Inherit from this class to "expose a model to QML."

```cpp
virtual int count() const = 0;        // how many entries
virtual T data(int index) const = 0;  // the entry at index
T get(int index) const;               // for QML interface compatibility

Qul::Signal<void (int)> dataChanged;  // row `index` changed
Qul::Signal<void ()>    modelReset;   // the number of rows changed
```

Two pure virtuals to implement, two signals to emit. That is the whole
contract.

### Step by step

**1. Define the row type.** A plain struct; its public fields become the roles
QML can read.

```cpp
struct Contact
{
    std::string name;
    std::string number;
    bool        favourite;
};
```

**2. Implement the model:**

```cpp
#include <qul/model.h>
#include <qul/singleton.h>

struct ContactModel : public Qul::Singleton<ContactModel>,
                      public Qul::ListModel<Contact>
{
    int count() const override { return m_count; }

    Contact data(int index) const override { return m_rows[index]; }

    void setRow(int i, const Contact &c)
    {
        m_rows[i] = c;
        dataChanged(i);          // tell the view this one row changed
    }

    void setCount(int n)
    {
        m_count = n;
        modelReset();            // tell the view the row count changed
    }

private:
    Contact m_rows[8];           // fixed storage: no heap
    int     m_count = 0;
};
```

**3. Use it in QML:**

```qml
Repeater {
    model: ContactModel
    Text { text: model.name + "  " + model.number }
}
```

The row struct's fields arrive as `model.name`, `model.number`,
`model.favourite`.

### Which signal to emit

This is the part people get wrong.

| What changed | Emit |
|---|---|
| A field inside row 3 | `dataChanged(3)` |
| How many rows there are | `modelReset()` |

`dataChanged` is cheap: the view reloads one row. `modelReset` is expensive:
the view rebuilds. Emit the cheap one when you can.

### The constraint nobody warns you about

A `Repeater`'s delegates are **allocated at build time** from a compile-time
estimate. There is no heap, so a row that appears at runtime has nowhere to
come from.

In practice this means: **decide the maximum row count at build time**, keep
the `Repeater`'s model constant, and use `visible` to hide the rows you are
not using.

```qml
Repeater {
    model: 8                              // constant. always 8 delegates.
    ContactRow {
        visible: index < ContactModel.count
    }
}
```

That is the pattern this project uses, because the alternative froze the
device. If you must use a live `ListModel` as a `Repeater` model, test it on
hardware early — the desktop build creates delegates on demand and will not
warn you.

## Qul::ListProperty — a list as a property

```cpp
#include <qul/listproperty.h>

template <typename T> struct Qul::ListProperty
```

> "Use this class as a public member of your C++ objects, which are exposed as
> list of properties for that object in QML."

A richer API than `Property`:

```cpp
void append(T *t);
T    at(int index);
void clear();
int  count() const;
void removeLast();
void replace(int index, T newValue);
T    operator[](int index) const;
bool isStatic() const;
bool isDynamic() const;
bool isNull() const;
void setList(Qul::StaticList<T> *l);
void setList(Qul::DynamicList<T> *l);
```

### ListModel or ListProperty?

| | `ListModel` | `ListProperty` |
|---|---|---|
| Built for | a view to repeat over | a property that happens to be a list |
| You implement | `count()` and `data()` | nothing; you fill it |
| Change notification | you emit `dataChanged` / `modelReset` | handled by the property system |
| Typical use | contact list, message list | a set of child objects, a list of points |

Rule of thumb: if a `Repeater` or `ListView` consumes it, you want
`ListModel`. If it is just "this object has several of those", you want
`ListProperty`.

### Static and dynamic lists

`isStatic()` and `isDynamic()` exist because the backing store can be fixed at
build time or managed at runtime. On a system with no heap, prefer static. A
`StaticList` you declare once and fill is predictable; that is the whole game
on an MCU.

## From this project

This project has neither — and that is itself worth knowing.

The contact list is a singleton with a count property and indexed accessor
functions:

```cpp
// PhoneListData exposes contactCount, plus
//   Format.contactName(index), Format.contactNumber(index)
```

```qml
Repeater {
    model: 3                                      // constant
    MessageRow {
        visible: index < PhoneListData.contactCount
    }
}
```

It is less elegant than a `ListModel`. It is also completely predictable in
memory, and it is why the UI does not freeze. For lists of three to eight
fixed-size rows — which is most of an instrument cluster — the plain version
wins. Reach for `ListModel` when the list is genuinely long and genuinely
dynamic, and then verify on hardware.

## Traps

**You change the row count and emit `dataChanged`.** The view does not rebuild
and you see stale or missing rows. Count changes need `modelReset()`.

**You return a reference from `data()`.** The signature is `T data(int) const`
— by value. Return a copy.

**You index past `count()`.** Nothing stops you. There is no bounds checking
and no exception; you get whatever is in memory.

**You let a `Repeater` model grow at runtime.** Works on desktop, freezes on
the device.

## Check it yourself

```bash
grep -rn "model:" qml --include='*.qml' | grep -v "model: [0-9]"
```

Every hit is a model that is not a compile-time constant. Each one needs a
reason, and a test on hardware.

## Sources

- [Qul::ListModel](https://doc.qt.io/QtForMCUs/qul-listmodel.html)
- [Qul::ListProperty](https://doc.qt.io/QtForMCUs/qul-listproperty.html)

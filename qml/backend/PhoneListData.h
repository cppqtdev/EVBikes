#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <string>

// The contacts and reminders the phone sends up. Three slots each, because that
// is what the rows on the screen hold. Nothing here is built into the firmware:
// an empty slot draws as an empty row.
struct PhoneListData : public Qul::Singleton<PhoneListData>
{
    Qul::Property<std::string> contact0Name;
    Qul::Property<std::string> contact0Text;
    Qul::Property<std::string> contact0Initial;
    Qul::Property<std::string> contact1Name;
    Qul::Property<std::string> contact1Text;
    Qul::Property<std::string> contact1Initial;
    Qul::Property<std::string> contact2Name;
    Qul::Property<std::string> contact2Text;
    Qul::Property<std::string> contact2Initial;

    Qul::Property<std::string> reminder0Name;
    Qul::Property<std::string> reminder0Text;
    Qul::Property<std::string> reminder0Initial;
    Qul::Property<std::string> reminder1Name;
    Qul::Property<std::string> reminder1Text;
    Qul::Property<std::string> reminder1Initial;
    Qul::Property<std::string> reminder2Name;
    Qul::Property<std::string> reminder2Text;
    Qul::Property<std::string> reminder2Initial;

    Qul::Property<int> contactCount;
    Qul::Property<int> reminderCount;

    // list 0 = contacts, 1 = reminders. The initial is worked out here because
    // the JavaScript subset on the board has no way to take the first letter of
    // a string.
    void setEntry(int list, int slot, const std::string &name, const std::string &text);
    void clear();
};

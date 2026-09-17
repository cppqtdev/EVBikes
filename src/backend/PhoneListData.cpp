#include "PhoneListData.h"

namespace {

std::string firstLetter(const std::string &name)
{
    if (name.empty())
        return std::string();
    char c = name[0];
    if (c >= 'a' && c <= 'z')
        c = static_cast<char>(c - 'a' + 'A');
    return std::string(1, c);
}

} // namespace

void PhoneListData::setEntry(int list, int slot, const std::string &name, const std::string &text)
{
    Qul::Property<std::string> *names[2][3] = {{&contact0Name, &contact1Name, &contact2Name},
                                               {&reminder0Name, &reminder1Name, &reminder2Name}};
    Qul::Property<std::string> *texts[2][3] = {{&contact0Text, &contact1Text, &contact2Text},
                                               {&reminder0Text, &reminder1Text, &reminder2Text}};
    Qul::Property<std::string> *initials[2][3] = {{&contact0Initial, &contact1Initial, &contact2Initial},
                                                  {&reminder0Initial, &reminder1Initial, &reminder2Initial}};
    if (list < 0 || list > 1 || slot < 0 || slot > 2)
        return;

    names[list][slot]->setValue(name);
    texts[list][slot]->setValue(text);
    initials[list][slot]->setValue(firstLetter(name));

    Qul::Property<int> &count = list == 0 ? contactCount : reminderCount;
    if (!name.empty() && slot + 1 > count.value())
        count.setValue(slot + 1);
}

void PhoneListData::clear()
{
    for (int list = 0; list < 2; ++list)
        for (int slot = 0; slot < 3; ++slot)
            setEntry(list, slot, std::string(), std::string());
    contactCount.setValue(0);
    reminderCount.setValue(0);
}

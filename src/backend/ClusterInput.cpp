#include "ClusterInput.h"

void ClusterInput::inject(uint8_t button, uint8_t action)
{
    buttonEvent(static_cast<int>(button), static_cast<int>(action));
}

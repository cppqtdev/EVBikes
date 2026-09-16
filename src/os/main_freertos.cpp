#include "Main.h"
#include "../backend/Backend.h"

#include <qul/application.h>
#include <qul/qul.h>

#include <FreeRTOS.h>
#include <task.h>

namespace {

constexpr uint16_t kUiStackWords = 32 * 1024 / sizeof(StackType_t);
constexpr uint16_t kIoStackWords = 2 * 1024 / sizeof(StackType_t);

void uiTask(void *)
{
    Qul::initPlatform();
    Backend::init();

    Qul::Application app;
    static struct ::Main item;
    app.setRootItem(&item);
    app.exec();
}

// Low-rate housekeeping that must not block the UI: e.g. polling sensors
// that have no interrupt line. Driver ISRs post straight to Backend queues.
void ioTask(void *)
{
    for (;;) {
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

} // namespace

int main()
{
    Qul::initHardware();

    xTaskCreate(uiTask, "ui", kUiStackWords, nullptr, tskIDLE_PRIORITY + 2, nullptr);
    xTaskCreate(ioTask, "io", kIoStackWords, nullptr, tskIDLE_PRIORITY + 3, nullptr);
    vTaskStartScheduler();
    return 0;
}

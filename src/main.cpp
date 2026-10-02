#include "Main.h"
#include "backend/Backend.h"

#include <qul/application.h>
#include <qul/qul.h>

#include <cstdio>

//  TEMPORARY startup trace. The last line printed is where it stopped.
#define EVB_TRACE(msg) do { std::printf("[boot] " msg "\n"); std::fflush(stdout); } while (0)

int main()
{
    EVB_TRACE("initHardware");
    Qul::initHardware();
    EVB_TRACE("initPlatform");
    Qul::initPlatform();
    EVB_TRACE("Backend::init");
    Backend::init();

    EVB_TRACE("Application");
    Qul::Application app;
    EVB_TRACE("root item");
    static struct ::Main item;
    EVB_TRACE("setRootItem");
    app.setRootItem(&item);
    EVB_TRACE("exec");
    app.exec();
    EVB_TRACE("exec returned");
    return 0;
}

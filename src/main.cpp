#include "Main.h"
#include "backend/Backend.h"

#include <qul/application.h>
#include <qul/qul.h>

int main()
{
    Qul::initHardware();
    Qul::initPlatform();
    Backend::init();

    Qul::Application app;
    static struct ::Main item;
    app.setRootItem(&item);
    app.exec();
    return 0;
}

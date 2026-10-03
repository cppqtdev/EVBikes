#include "Main.h"
#include "backend/Backend.h"

#include <qul/application.h>
#include <qul/applicationconfiguration.h>
#include <qul/qul.h>

#include <cstdio>

//  TEMPORARY startup trace. The last line printed is where it stopped.
#define EVB_TRACE(msg) do { std::printf("[boot] " msg "\n"); std::fflush(stdout); } while (0)

//  The text cache lives in VRAM and defaults to 192 KB, which is a lot to
//  hold on a board whose layer buffers are already the tight part. Nothing
//  here needs that much: the static font engine puts the glyphs in flash and
//  mergeStaticTextGlyphs folds the fixed runs together, so what the cache
//  holds is the handful of readings that actually change.
//
//  Too small shows up loudly -- text stops drawing and the engine reports it
//  -- so tune it down on hardware rather than guessing upwards. Override at
//  configure time with -DEVB_TEXT_CACHE_BYTES=... to bisect.
#ifndef EVB_TEXT_CACHE_BYTES
#define EVB_TEXT_CACHE_BYTES (96 * 1024)
#endif

int main()
{
    EVB_TRACE("initHardware");
    Qul::initHardware();
    EVB_TRACE("initPlatform");
    Qul::initPlatform();
    EVB_TRACE("Backend::init");
    Backend::init();

    EVB_TRACE("Application");
    Qul::ApplicationConfiguration::setTextCacheSize(EVB_TEXT_CACHE_BYTES);
    Qul::Application app;
    EVB_TRACE("root item");
    static struct ::Main item;
    EVB_TRACE("setRootItem");
    app.setRootItem(&item);
    EVB_TRACE("start runtime");
    Backend::startRuntime();
    EVB_TRACE("exec");
    app.exec();
    EVB_TRACE("stop runtime");
    Backend::stopRuntime();
    EVB_TRACE("exec returned");
    return 0;
}

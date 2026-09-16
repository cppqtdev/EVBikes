#include "../src/backend/Backend.h"

#include <QColor>
#include <QDirIterator>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QKeyEvent>
#include <QKeySequence>
#include <QLoggingCategory>
#include <QMouseEvent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickView>
#include <QScreen>
#include <QSurfaceFormat>

namespace {

// Frameless preview: drag anywhere on the cluster to move it; Q or Ctrl+Q (Cmd+Q on macOS) quits.
class WindowController : public QObject
{
public:
    explicit WindowController(QQuickView *view)
        : QObject(view)
        , m_view(view)
    {
    }

protected:
    bool eventFilter(QObject *watched, QEvent *event) override
    {
        if (event->type() == QEvent::MouseButtonPress) {
            const auto *mouse = static_cast<QMouseEvent *>(event);
            if (mouse->button() == Qt::LeftButton && m_view->startSystemMove())
                return true;
        } else if (event->type() == QEvent::KeyPress) {
            const auto *key = static_cast<QKeyEvent *>(event);
            if (key->matches(QKeySequence::Quit) || key->key() == Qt::Key_Q) {
                QGuiApplication::quit();
                return true;
            }
        }
        return QObject::eventFilter(watched, event);
    }

private:
    QQuickView *m_view;
};

} // namespace

int main(int argc, char *argv[])
{
    // Qt Quick Ultralite documents Keys.onPressed with the injected `event`
    // parameter, which Qt 6 reports as deprecated. Hide only that warning.
    QLoggingCategory::setFilterRules(QStringLiteral("qt.qml.context.warning=false"));

    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("EVBikes Cluster"));

    QDirIterator fonts(QStringLiteral(":/assets/fonts"), {QStringLiteral("*.ttf")});
    while (fonts.hasNext())
        QFontDatabase::addApplicationFont(fonts.next());

    Backend::init();

    QQuickView view;
    view.setTitle(QStringLiteral("EVBikes Cluster"));
    view.setFlags(Qt::Window | Qt::FramelessWindowHint | Qt::NoDropShadowWindowHint);
    view.setColor(Qt::transparent);
    view.setResizeMode(QQuickView::SizeViewToRootObject);
    QObject::connect(view.engine(), &QQmlEngine::quit, &app, &QGuiApplication::quit);
    view.loadFromModule(QStringLiteral("EVBikesApp"), QStringLiteral("Main"));
    if (view.status() == QQuickView::Error)
        return -1;

    // The board clears the screen to black; on the desktop only the frame is drawn.
    if (QQuickItem *root = view.rootObject())
        root->setProperty("color", QColor(Qt::transparent));

    view.installEventFilter(new WindowController(&view));
    if (QScreen *screen = view.screen())
        view.setPosition(screen->availableGeometry().center() - QPoint(view.width() / 2, view.height() / 2));
    view.show();
    view.requestActivate();

    return app.exec();
}

// Loads every QML type in the cluster and fails on the first sign of trouble.
//
// A QML file that does not compile, a type used without its import, an image
// that is not in the resources or a binding that throws all show up only when
// the file is actually instantiated. The app loads most screens lazily, so a
// broken one can sit unnoticed until a rider opens that page. This walks every
// type in every module, creates it, and treats any warning as a failure.
#include "../src/backend/Backend.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQmlError>
#include <QString>
#include <QStringList>
#include <QtGlobal>

#include <cstdio>

namespace {

QStringList g_warnings;
QtMessageHandler g_previous = nullptr;

void collect(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    if (type != QtDebugMsg && type != QtInfoMsg)
        g_warnings << message;
    if (g_previous)
        g_previous(type, context, message);
}

QString moduleDir(const QString &uri)
{
    QString path = uri;
    return QStringLiteral(":/qt/qml/") + path.replace(QLatin1Char('.'), QLatin1Char('/'));
}

QStringList typesIn(const QString &uri)
{
    QStringList names;
    QDirIterator it(moduleDir(uri), {QStringLiteral("*.qml")}, QDir::Files);
    while (it.hasNext()) {
        it.next();
        names << it.fileInfo().completeBaseName();
    }
    names.sort();
    return names;
}

bool isSingleton(const QString &uri, const QString &name)
{
    QFile file(moduleDir(uri) + QLatin1Char('/') + name + QStringLiteral(".qml"));
    if (!file.open(QIODevice::ReadOnly))
        return false;
    return file.readAll().contains("pragma Singleton");
}

} // namespace

int main(int argc, char *argv[])
{
    qputenv("QT_QPA_PLATFORM", "offscreen");
    // Same rule as the app: Qt for MCUs documents Keys.onPressed with the
    // injected `event` parameter, which Qt 6 reports as deprecated.
    QLoggingCategory::setFilterRules(QStringLiteral("qt.qml.context.warning=false"));

    QGuiApplication app(argc, argv);

    QDirIterator fonts(QStringLiteral(":/assets/fonts"), {QStringLiteral("*.ttf")});
    while (fonts.hasNext())
        QFontDatabase::addApplicationFont(fonts.next());

    Backend::init();
    g_previous = qInstallMessageHandler(collect);

    QQmlEngine engine;
    const QStringList modules = {QStringLiteral("ClusterCore"), QStringLiteral("ClusterComponents"),
                                 QStringLiteral("ClusterScreens"), QStringLiteral("EVBikesApp")};
    int loaded = 0;
    int failed = 0;

    for (const QString &uri : modules) {
        const QStringList names = typesIn(uri);
        if (names.isEmpty()) {
            std::printf("FAIL %s: no QML types found in the resources\n", qPrintable(uri));
            ++failed;
            continue;
        }
        for (const QString &name : names) {
            if (isSingleton(uri, name)) {
                if (engine.singletonInstance<QObject *>(uri, name) == nullptr) {
                    std::printf("FAIL %s.%s: singleton did not load\n", qPrintable(uri), qPrintable(name));
                    ++failed;
                    continue;
                }
                ++loaded;
                continue;
            }

            QQmlComponent component(&engine);
            component.loadFromModule(uri, name);
            QObject *object = component.create();
            if (object == nullptr) {
                std::printf("FAIL %s.%s\n", qPrintable(uri), qPrintable(name));
                const QList<QQmlError> errors = component.errors();
                for (const QQmlError &error : errors)
                    std::printf("     %s\n", qPrintable(error.toString()));
                ++failed;
                continue;
            }
            delete object;
            ++loaded;
        }
    }

    // Timers and bindings that only run on the next pass get their chance here.
    QCoreApplication::processEvents();

    for (const QString &warning : g_warnings)
        std::printf("WARNING %s\n", qPrintable(warning));

    const int problems = failed + static_cast<int>(g_warnings.size());
    std::printf(problems ? "%d loaded, %d failed, %lld warning(s)\n" : "%d loaded, %d failed, %lld warning(s): QML LOAD PASSED\n",
                loaded, failed, static_cast<long long>(g_warnings.size()));
    return problems ? 1 : 0;
}

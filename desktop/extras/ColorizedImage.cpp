#include "ColorizedImage.h"

#include <QPainter>

namespace {

QString resolvePath(const QUrl &url)
{
    if (url.scheme() == QLatin1String("qrc"))
        return QLatin1Char(':') + url.path();
    if (url.isLocalFile())
        return url.toLocalFile();
    const QString s = url.toString();
    return s.startsWith(QLatin1Char(':')) ? s : QStringLiteral(":/") + s;
}

} // namespace

ColorizedImage::ColorizedImage(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(true);
}

void ColorizedImage::setSource(const QUrl &source)
{
    if (m_source == source)
        return;
    m_source = source;
    m_original = QImage(resolvePath(source));
    if (m_original.isNull() && !source.isEmpty())
        qWarning("ColorizedImage: cannot load %s", qPrintable(source.toString()));
    setImplicitSize(m_original.width(), m_original.height());
    rebuildTinted();
    emit sourceChanged();
}

void ColorizedImage::setColor(const QColor &color)
{
    if (m_color == color)
        return;
    m_color = color;
    rebuildTinted();
    emit colorChanged();
}

void ColorizedImage::rebuildTinted()
{
    if (m_original.isNull()) {
        m_tinted = QImage();
        update();
        return;
    }
    m_tinted = QImage(m_original.size(), QImage::Format_ARGB32_Premultiplied);
    m_tinted.fill(Qt::transparent);
    QPainter p(&m_tinted);
    p.drawImage(0, 0, m_original);
    p.setCompositionMode(QPainter::CompositionMode_SourceIn);
    p.fillRect(m_tinted.rect(), m_color);
    p.end();
    update();
}

void ColorizedImage::paint(QPainter *painter)
{
    if (m_tinted.isNull())
        return;
    // Qt Quick Ultralite draws images at their own size, so the preview does too.
    painter->drawImage(QPointF(0, 0), m_tinted);
}

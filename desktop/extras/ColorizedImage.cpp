#include "ColorizedImage.h"

#include <QPainter>
#include <QPixmap>

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

void ColorizedImage::setFillMode(int fillMode)
{
    if (m_fillMode == fillMode)
        return;
    m_fillMode = fillMode;
    update();
    emit fillModeChanged();
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
    painter->setRenderHint(QPainter::SmoothPixmapTransform, smooth());

    // Qt Quick Ultralite draws images at their own size, so the preview does too:
    // that is what the implicit size is for, and fillMode only comes into it once
    // the QML gives the item a size of its own.
    const QRectF box(0, 0, width(), height());

    switch (m_fillMode) {
    case Pad:
        painter->drawImage(QPointF(0, 0), m_tinted);
        break;
    case Tile:
        painter->drawTiledPixmap(box, QPixmap::fromImage(m_tinted));
        break;
    case TileHorizontally:
        painter->drawTiledPixmap(
            box, QPixmap::fromImage(m_tinted.scaledToHeight(qRound(box.height()),
                                                           Qt::SmoothTransformation)));
        break;
    case TileVertically:
        painter->drawTiledPixmap(
            box, QPixmap::fromImage(m_tinted.scaledToWidth(qRound(box.width()),
                                                          Qt::SmoothTransformation)));
        break;
    case PreserveAspectFit:
    case PreserveAspectCrop: {
        QSizeF art(m_tinted.size());
        art.scale(box.size(), m_fillMode == PreserveAspectFit ? Qt::KeepAspectRatio
                                                              : Qt::KeepAspectRatioByExpanding);
        const QRectF at(QPointF((box.width() - art.width()) / 2,
                                (box.height() - art.height()) / 2),
                        art);
        if (m_fillMode == PreserveAspectFit) {
            painter->drawImage(at, m_tinted);
        } else {
            painter->save();
            painter->setClipRect(box);
            painter->drawImage(at, m_tinted);
            painter->restore();
        }
        break;
    }
    case Stretch:
    default:
        painter->drawImage(box, m_tinted);
        break;
    }
}

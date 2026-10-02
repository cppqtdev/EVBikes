#pragma once

#include <QColor>
#include <QImage>
#include <QQuickPaintedItem>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

// Desktop version of QtQuickUltralite.Extras ColorizedImage:
// draws the image alpha channel filled with `color`.
class ColorizedImage : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged FINAL)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged FINAL)
    // int, not the enum, so the QML can keep saying Image.PreserveAspectFit the
    // way it does on Qt for MCUs. The values below are Image's own.
    Q_PROPERTY(int fillMode READ fillMode WRITE setFillMode NOTIFY fillModeChanged FINAL)

public:
    enum FillMode {
        Stretch = 0,
        PreserveAspectFit = 1,
        PreserveAspectCrop = 2,
        Tile = 3,
        TileVertically = 4,
        TileHorizontally = 5,
        Pad = 6,
    };

    explicit ColorizedImage(QQuickItem *parent = nullptr);

    QUrl source() const { return m_source; }
    void setSource(const QUrl &source);

    QColor color() const { return m_color; }
    void setColor(const QColor &color);

    int fillMode() const { return m_fillMode; }
    void setFillMode(int fillMode);

    void paint(QPainter *painter) override;

signals:
    void sourceChanged();
    void colorChanged();
    void fillModeChanged();

private:
    void rebuildTinted();

    QUrl m_source;
    QColor m_color = Qt::white;
    int m_fillMode = Stretch;
    QImage m_original;
    QImage m_tinted;
};

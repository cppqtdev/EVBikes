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

public:
    explicit ColorizedImage(QQuickItem *parent = nullptr);

    QUrl source() const { return m_source; }
    void setSource(const QUrl &source);

    QColor color() const { return m_color; }
    void setColor(const QColor &color);

    void paint(QPainter *painter) override;

signals:
    void sourceChanged();
    void colorChanged();

private:
    void rebuildTinted();

    QUrl m_source;
    QColor m_color = Qt::white;
    QImage m_original;
    QImage m_tinted;
};

#include "BreezeIconProvider.h"

#include <KF6/BreezeIcons/breezeicons.h>
#include <QIcon>
#include <QPainter>

BreezeIconProvider::BreezeIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap BreezeIconProvider::requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) {
    const int s = requestedSize.width() > 0 ? requestedSize.width() : 32;
    if (size) *size = QSize(s, s);

    // BreezeIcons::initIcons() ensures fromTheme works cross-platform
    QPixmap px = QIcon::fromTheme(id).pixmap(s, s);

    // Recolor to white so icons are visible on dark backgrounds
    QPainter p(&px);
    p.setCompositionMode(QPainter::CompositionMode_SourceIn);
    p.fillRect(px.rect(), Qt::white);

    return px;
}

QQuickImageProvider* createBreezeIconProvider() {
    BreezeIcons::initIcons();
    return new BreezeIconProvider();
}

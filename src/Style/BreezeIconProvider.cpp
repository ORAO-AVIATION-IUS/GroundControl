#include "BreezeIconProvider.h"

#ifdef AGC_HAS_KF6_BREEZE_ICONS
#include <KF6/BreezeIcons/breezeicons.h>
#endif

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QDebug>
#include <QHash>
#include <QIcon>
#include <QPainter>
#include <QSet>
#include <QSvgRenderer>

namespace {

constexpr int kDefaultIconSize = 32;
constexpr const char* kBreezeThemeName = "breeze";

QString breezeIconRoot() {
#ifdef AGC_BREEZE_ICON_ROOT
    return QStringLiteral(AGC_BREEZE_ICON_ROOT);
#else
    return {};
#endif
}

QHash<QString, QString> buildIconIndex(const QString& rootPath) {
    QHash<QString, QString> icons;
    if (rootPath.isEmpty() || !QDir(rootPath).exists()) {
        return icons;
    }

    const QStringList filters = {QStringLiteral("*.svg")};
    QDirIterator it(rootPath, filters, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString path = it.next();
        const QFileInfo info(path);
        const QString name = info.completeBaseName();
        if (!icons.contains(name)) {
            icons.insert(name, path);
        }
    }

    return icons;
}

const QHash<QString, QString>& iconIndex() {
    static const QHash<QString, QString> icons = buildIconIndex(breezeIconRoot());
    return icons;
}

QString iconPathForName(const QString& id) {
    const auto& icons = iconIndex();
    const auto it = icons.constFind(id);
    if (it != icons.constEnd()) {
        return it.value();
    }

    static const QHash<QString, QString> aliases = {
        {QStringLiteral("go-home-large"), QStringLiteral("go-home")},
        {QStringLiteral("routeplanning"), QStringLiteral("draw-path")},
    };
    const auto alias = aliases.constFind(id);
    if (alias == aliases.constEnd()) {
        return {};
    }

    const auto aliasIcon = icons.constFind(alias.value());
    if (aliasIcon == icons.constEnd()) {
        return {};
    }
    return aliasIcon.value();
}

void configureVendoredThemePath() {
    const QString rootPath = breezeIconRoot();
    if (rootPath.isEmpty() || !QDir(rootPath).exists()) {
        return;
    }

    QStringList searchPaths = QIcon::themeSearchPaths();
    const QString parentPath = QFileInfo(rootPath).absolutePath();
    if (!searchPaths.contains(parentPath)) {
        searchPaths.prepend(parentPath);
        QIcon::setThemeSearchPaths(searchPaths);
    }

    if (QIcon::themeName().isEmpty()) {
        QIcon::setThemeName(QString::fromLatin1(kBreezeThemeName));
    }
}

QPixmap pixmapFromIcon(const QIcon& icon, int size) {
    if (icon.isNull()) {
        return {};
    }

    return icon.pixmap(size, size);
}

QPixmap pixmapFromSvg(const QString& path, int size) {
    if (path.isEmpty()) {
        return {};
    }

    QSvgRenderer renderer(path);
    if (!renderer.isValid()) {
        return {};
    }

    QPixmap pixmap(size, size);
    pixmap.fill(Qt::transparent);

    QPainter painter(&pixmap);
    renderer.render(&painter);

    return pixmap;
}

void tintWhite(QPixmap* pixmap) {
    if (!pixmap || pixmap->isNull()) {
        return;
    }

    QPainter painter(pixmap);
    painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
    painter.fillRect(pixmap->rect(), Qt::white);
}

}  // namespace

BreezeIconProvider::BreezeIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap BreezeIconProvider::requestPixmap(const QString& id, QSize* size,
                                          const QSize& requestedSize) {
    const int iconSize = requestedSize.width() > 0 ? requestedSize.width()
                                                   : kDefaultIconSize;
    if (size) {
        *size = QSize(iconSize, iconSize);
    }

    QPixmap pixmap = pixmapFromIcon(QIcon::fromTheme(id), iconSize);
    if (pixmap.isNull()) {
        const QString iconPath = iconPathForName(id);
        pixmap = pixmapFromSvg(iconPath, iconSize);
    }
    if (pixmap.isNull()) {
        static QSet<QString> warnedIcons;
        if (!warnedIcons.contains(id)) {
            warnedIcons.insert(id);
            qWarning() << "Missing Breeze icon:" << id;
        }
    }

    tintWhite(&pixmap);

    return pixmap;
}

QQuickImageProvider* createBreezeIconProvider() {
#ifdef AGC_HAS_KF6_BREEZE_ICONS
    BreezeIcons::initIcons();
#else
    configureVendoredThemePath();
#endif
    return new BreezeIconProvider();
}

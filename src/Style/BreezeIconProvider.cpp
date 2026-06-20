#include "BreezeIconProvider.h"

#ifdef AGC_HAS_KF6_BREEZE_ICONS
#include <KF6/BreezeIcons/breezeicons.h>
#endif

#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QIcon>
#include <QPainter>
#include <QSet>
#include <QSvgRenderer>

namespace {

constexpr int kDefaultIconSize = 32;
constexpr const char* kBreezeThemeName = "breeze";

bool hasSvgIcons(const QString& rootPath) {
	if (rootPath.isEmpty() || !QDir(rootPath).exists()) {
		return false;
	}

	QDirIterator it(rootPath, {QStringLiteral("*.svg")}, QDir::Files,
		QDirIterator::Subdirectories);
	return it.hasNext();
}

QString breezeIconRoot() {
#ifdef AGC_BREEZE_ICON_ROOT
	const QString vendoredRoot = QStringLiteral(AGC_BREEZE_ICON_ROOT);
	if (hasSvgIcons(vendoredRoot)) {
		return vendoredRoot;
	}
#endif

	const QString systemRoot = QStringLiteral("/usr/share/icons/breeze");
	if (hasSvgIcons(systemRoot)) {
		return systemRoot;
	}

	return {};
}

QHash<QString, QString> buildIconIndex(const QString& rootPath) {
	QHash<QString, QString> icons;
	if (rootPath.isEmpty() || !QDir(rootPath).exists()) {
		return icons;
	}

	const QStringList filters = {QStringLiteral("*.svg")};
	QDirIterator it(
		rootPath, filters, QDir::Files, QDirIterator::Subdirectories);
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
	static const QHash<QString, QString> icons =
		buildIconIndex(breezeIconRoot());
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

	// Keep the application icon rendering independent from the desktop session.
	// XFCE/GTK theme changes can otherwise make Qt resolve different filled icons.
	QIcon::setThemeName(QString::fromLatin1(kBreezeThemeName));
}

QPixmap pixmapFromIcon(const QIcon& icon, int size) {
	if (icon.isNull()) {
		return {};
	}

	return icon.pixmap(size, size);
}

// On Windows, breeze-icons' Unix symlinks are checked out as small text files
// whose content is just the target filename (e.g. "go-home.svg"). Follow
// these textual references until we reach a real SVG (or a cycle / depth cap).
QString resolveTextSymlink(const QString& path, int maxDepth = 8) {
	if (path.isEmpty() || maxDepth <= 0) {
		return path;
	}
	QFile f(path);
	if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
		return path;
	}
	const qint64 size = f.size();
	if (size <= 0 || size >= 512) {
		return path;
	}
	const QByteArray content = f.readAll().trimmed();
	if (content.isEmpty() || content.startsWith('<')) {
		return path;
	}
	const QString target = QString::fromUtf8(content);
	if (target.contains('<') || target.contains('\n')) {
		return path;
	}
	const QFileInfo info(path);
	const QString resolved =
		QDir::cleanPath(info.absoluteDir().filePath(target));
	if (resolved == path || !QFile::exists(resolved)) {
		return path;
	}
	return resolveTextSymlink(resolved, maxDepth - 1);
}

QPixmap pixmapFromSvg(const QString& path, int size) {
	if (path.isEmpty()) {
		return {};
	}

	const QString realPath = resolveTextSymlink(path);
	QFile file(realPath);
	if (!file.open(QIODevice::ReadOnly)) {
		return {};
	}

	QByteArray svg = file.readAll();
	// Some Breeze icons encode outlines and inner holes as a single compound path.
	// On this setup QSvgRenderer fills those inner subpaths unless the fill rule is
	// explicit, making icons look like solid white blobs after tinting.
	if (!svg.contains("fill-rule")) {
		svg.replace(
			"<path ", "<path fill-rule=\"evenodd\" clip-rule=\"evenodd\" ");
	}

	QSvgRenderer renderer(svg);
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
	if (pixmap == nullptr || pixmap->isNull()) {
		return;
	}

	QPainter painter(pixmap);
	painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
	painter.fillRect(pixmap->rect(), Qt::white);
}

}  // namespace

BreezeIconProvider::BreezeIconProvider()
	: QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap BreezeIconProvider::requestPixmap(
	const QString& id, QSize* size, const QSize& requestedSize) {
	const int iconSize =
		requestedSize.width() > 0 ? requestedSize.width() : kDefaultIconSize;
	if (size != nullptr) {
		*size = QSize(iconSize, iconSize);
	}

	// Prefer the vendored Breeze SVGs so the app does not change appearance with
	// the desktop session/icon theme (for example XFCE can make QIcon::fromTheme
	// return filled icons, which become solid white after tinting).
	QPixmap pixmap = pixmapFromSvg(iconPathForName(id), iconSize);
	if (pixmap.isNull()) {
		pixmap = pixmapFromIcon(QIcon::fromTheme(id), iconSize);
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
	return new BreezeIconProvider();  // NOLINT(cppcoreguidelines-owning-memory)
}

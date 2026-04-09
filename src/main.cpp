#include "GStreamerVideoItem.h"

#include <kddockwidgets/Config.h>
#include <kddockwidgets/core/DockRegistry.h>
#include <kddockwidgets/qtquick/Platform.h>

#include <breezeicons.h>

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QPainter>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickImageProvider>

class IconImageProvider : public QQuickImageProvider {
public:
	IconImageProvider()
		: QQuickImageProvider(QQuickImageProvider::Pixmap) {}

	QPixmap requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) override {
		const int w = requestedSize.width() > 0 ? requestedSize.width() : 32;
		const int h = requestedSize.height() > 0 ? requestedSize.height() : 32;
		if (size)
			*size = QSize(w, h);

		QPixmap px = QIcon::fromTheme(id).pixmap(w, h);

		// Recolor to white so icons are visible on dark backgrounds
		QPainter p(&px);
		p.setCompositionMode(QPainter::CompositionMode_SourceIn);
		p.fillRect(px.rect(), Qt::white);

		return px;
	}
};

int main(int argc, char* argv[]) {
#ifdef Q_OS_WIN
	QGuiApplication::setAttribute(Qt::AA_UseOpenGLES);
#endif
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
	QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
	QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif

	QGuiApplication app(argc, argv);

	BreezeIcons::initIcons();

	KDDockWidgets::initFrontend(KDDockWidgets::FrontendType::QtQuick);

	QQmlApplicationEngine appEngine;

	qmlRegisterType<GStreamerVideoItem>("gc", 1, 0, "GStreamerVideoItem");
	appEngine.addImageProvider("icon", new IconImageProvider());

	KDDockWidgets::QtQuick::Platform::instance()->setQmlEngine(&appEngine);
	appEngine.load(QUrl("qrc:/src/Main.qml"));

	return app.exec();
}

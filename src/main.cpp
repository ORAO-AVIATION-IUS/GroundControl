#include <kddockwidgets/Config.h>
#include <kddockwidgets/core/DockRegistry.h>
#include <kddockwidgets/qtquick/Platform.h>

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QJSEngine>
#include <QQuickWindow>
#include <QSGRendererInterface>

#include <QtQml/QQmlExtensionPlugin>

#include "BreezeIconProvider.h"
#include "Camera/CameraManager.h"

Q_IMPORT_QML_PLUGIN(Agc_StylePlugin)
Q_IMPORT_QML_PLUGIN(Agc_ComponentsPlugin)
Q_IMPORT_QML_PLUGIN(Agc_PanelsPlugin)
Q_IMPORT_QML_PLUGIN(Agc_NetworkPlugin)
Q_IMPORT_QML_PLUGIN(Agc_MavlinkPlugin)
Q_IMPORT_QML_PLUGIN(Agc_CameraPlugin)

// Singleton provider for CameraManager
static CameraManager* s_cameraManagerInstance = nullptr;

static QObject* cameraManagerProvider(QQmlEngine* engine, QJSEngine* script) {
	Q_UNUSED(engine);
	Q_UNUSED(script);
	return s_cameraManagerInstance;
}

int main(int argc, char* argv[]) {
#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
	QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
#endif

	QGuiApplication app(argc, argv);

	KDDockWidgets::initFrontend(KDDockWidgets::FrontendType::QtQuick);

	QQmlApplicationEngine appEngine;

	appEngine.addImageProvider("icon", createBreezeIconProvider());

	KDDockWidgets::QtQuick::Platform::instance()->setQmlEngine(&appEngine);

	// camera manager singleton - owned by this function
	s_cameraManagerInstance = new CameraManager(&appEngine);
	qmlRegisterSingletonType<CameraManager>("Agc.Camera", 1, 0, "CameraManager",
											cameraManagerProvider);

	appEngine.loadFromModule("Agc", "Main");

	return app.exec();
}
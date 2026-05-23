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
#include "Mavlink/SwarmManager.h"
#include "MessageHandler.h"

Q_IMPORT_QML_PLUGIN(Agc_StylePlugin)
Q_IMPORT_QML_PLUGIN(Agc_ComponentsPlugin)
Q_IMPORT_QML_PLUGIN(Agc_PanelsPlugin)
Q_IMPORT_QML_PLUGIN(Agc_NetworkPlugin)
Q_IMPORT_QML_PLUGIN(Agc_MavlinkPlugin)
Q_IMPORT_QML_PLUGIN(Agc_CameraPlugin)



int main(int argc, char* argv[]) {
#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
	QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
#endif

	installMessageHandler();

	QGuiApplication app(argc, argv);

	KDDockWidgets::initFrontend(KDDockWidgets::FrontendType::QtQuick);

	QQmlApplicationEngine appEngine;

	appEngine.addImageProvider("icon", createBreezeIconProvider());

	KDDockWidgets::QtQuick::Platform::instance()->setQmlEngine(&appEngine);

	appEngine.loadFromModule("Agc", "Main");

	return app.exec();
}
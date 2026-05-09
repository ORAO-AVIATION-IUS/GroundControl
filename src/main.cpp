#include <kddockwidgets/Config.h>
#include <kddockwidgets/core/DockRegistry.h>
#include <kddockwidgets/qtquick/Platform.h>

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSGRendererInterface>

#include <QtQml/QQmlExtensionPlugin>

Q_IMPORT_QML_PLUGIN(Agc_StylePlugin)
Q_IMPORT_QML_PLUGIN(Agc_ComponentsPlugin)
Q_IMPORT_QML_PLUGIN(Agc_PanelsPlugin)
Q_IMPORT_QML_PLUGIN(Agc_NetworkPlugin)
Q_IMPORT_QML_PLUGIN(Agc_MavlinkPlugin)
Q_IMPORT_QML_PLUGIN(Agc_CameraPlugin)

int main(int argc, char* argv[]) {
    // MapLibre requires OpenGL; force Qt Quick's RHI to use it on all platforms.
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

	QGuiApplication app(argc, argv);

	KDDockWidgets::initFrontend(KDDockWidgets::FrontendType::QtQuick);

	QQmlApplicationEngine appEngine;

	KDDockWidgets::QtQuick::Platform::instance()->setQmlEngine(&appEngine);
	appEngine.loadFromModule("Agc", "Main");

	return app.exec();
}

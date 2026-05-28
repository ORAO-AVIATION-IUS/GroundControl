#include <kddockwidgets/Config.h>
#include <kddockwidgets/core/DockRegistry.h>
#include <kddockwidgets/qtquick/Platform.h>

#include <QCommandLineParser>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QJSEngine>
#include <QPalette>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSGRendererInterface>

#include <QtQml/QQmlExtensionPlugin>

#include "BreezeIconProvider.h"
#include "Camera/CameraManager.h"
#include "DarkViewFactory.h"
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

	// Dark palette – propagates to KDDW tabs/separators/titlebars and all dialogs.
	QPalette darkPalette;
	darkPalette.setColor(QPalette::Window, QColor("#0d1117"));
	darkPalette.setColor(QPalette::WindowText, QColor("#e6edf3"));
	darkPalette.setColor(QPalette::Base, QColor("#161b22"));
	darkPalette.setColor(QPalette::AlternateBase, QColor("#1c2128"));
	darkPalette.setColor(QPalette::Text, QColor("#e6edf3"));
	darkPalette.setColor(QPalette::Button, QColor("#21262d"));
	darkPalette.setColor(QPalette::ButtonText, QColor("#e6edf3"));
	darkPalette.setColor(QPalette::BrightText, QColor("#f85149"));
	darkPalette.setColor(QPalette::Highlight, QColor("#1f6feb"));
	darkPalette.setColor(QPalette::HighlightedText, QColor("#ffffff"));
	darkPalette.setColor(QPalette::Dark, QColor("#30363d"));
	darkPalette.setColor(QPalette::Mid, QColor("#21262d"));
	darkPalette.setColor(QPalette::Light, QColor("#484f58"));
	darkPalette.setColor(QPalette::Midlight, QColor("#30363d"));
	darkPalette.setColor(QPalette::Link, QColor("#58a6ff"));
	darkPalette.setColor(QPalette::PlaceholderText, QColor("#6e7681"));
	app.setPalette(darkPalette);

	KDDockWidgets::initFrontend(KDDockWidgets::FrontendType::QtQuick);

	// Dark-themed view factory for KDDockWidgets (separator, title bar, group frame).
	KDDockWidgets::Config::self().setViewFactory(new DarkViewFactory());

	QQmlApplicationEngine appEngine;

	appEngine.addImageProvider("icon", createBreezeIconProvider());

	KDDockWidgets::QtQuick::Platform::instance()->setQmlEngine(&appEngine);

	appEngine.loadFromModule("Agc", "Main");

	return app.exec();
}
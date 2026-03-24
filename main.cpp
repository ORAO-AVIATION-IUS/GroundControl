#include <kddockwidgets/Config.h>
#include <kddockwidgets/core/DockRegistry.h>
#include <kddockwidgets/qtquick/Platform.h>

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug> // Hata ayıklama için şart
#include <MAVLinkManager.h>

int main(int argc, char* argv[]) {
#ifdef Q_OS_WIN
	QGuiApplication::setAttribute(Qt::AA_UseOpenGLES);
#endif
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
	QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
	QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif

	QGuiApplication app(argc, argv);

	// 1. KRİTİK: KDDockWidgets'ı başlat (Bu satır sende eksikti, QML yüklenmesini engelleyebilir)
	KDDockWidgets::initFrontend(KDDockWidgets::FrontendType::QtQuick);

	QQmlApplicationEngine engine;

	// 2. MAVLinkManager nesnesini oluştur
	MAVLinkManager* mavManager = new MAVLinkManager(&app);
	qDebug() << "MAVLinkManager olusturuldu, UDP dinleniyor...";

	// 3. QML tarafına 'mavManager' ismiyle gönder
	engine.rootContext()->setContextProperty("mavManager", mavManager);

	// 4. Platform motorunu ayarla
	KDDockWidgets::QtQuick::Platform::instance()->setQmlEngine(&engine);

	// 5. QML Yükleme ve Hata Kontrolü
	const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));

	// Yükleme sırasında hata olursa terminale bas
	QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
					 &app, [url](QObject *obj, const QUrl &objUrl) {
						 if (!obj && url == objUrl) {
							 qCritical() << "HATA: QML nesnesi olusturulamadi! Dosya yolunu veya QML kodunu kontrol et:" << url;
							 QCoreApplication::exit(-1);
						 }
					 }, Qt::QueuedConnection);

	engine.load(url);

	if (engine.rootObjects().isEmpty()) {
		qWarning() << "UYARI: Root nesnesi bos, uygulama baslatilamiyor.";
		return -1;
	}

	qDebug() << "Uygulama basariyla baslatildi.";
	return app.exec();
}

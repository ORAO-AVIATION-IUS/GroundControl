#pragma once

#include <QMap>
#include <QObject>
#include <QPointer>
#include <QQmlApplicationEngine>
#include <QString>
#include <QUrl>

#include <QVideoSink>

using GstElement = struct _GstElement;

struct CameraInfo {
	QString name;
	QUrl streamUrl;
	QString customPipeline;
	bool useCustomPipeline = false;
	bool connected = false;
	QString status;
	QPointer<QVideoSink> sink;
	GstElement* pipeline = nullptr;
	void* appsink = nullptr;  // GstAppSink*
};

class CameraManager : public QObject {
	Q_OBJECT

   public:
	explicit CameraManager(QQmlApplicationEngine* engine,
						   QObject* parent = nullptr);
	~CameraManager() override;

	Q_INVOKABLE int addStream(const QString& name, const QUrl& url);
	Q_INVOKABLE int addCustomStream(const QString& name,
									const QString& pipeline);
	Q_INVOKABLE void removeStream(int id);
	Q_INVOKABLE void editStream(int id, const QString& name, const QUrl& url);
	Q_INVOKABLE void editCustomStream(int id, const QString& name,
									  const QString& pipeline);
	Q_INVOKABLE void attachSink(int id, QVideoSink* sink);
	Q_INVOKABLE void reconnectStream(int id);

	Q_INVOKABLE QString streamStatus(int id) const;
	Q_INVOKABLE bool streamConnected(int id) const;

	void setStreamState(int id, const QString& status, bool connected);

   signals:
	void streamStatusChanged(int id, const QString& status);
	void streamConnectedChanged(int id, bool connected);
	void streamError(int id, const QString& message);

   private:
	void startPipeline(int id);
	void startCustomPipeline(int id);
	void stopPipeline(int id);

	QQmlApplicationEngine* m_engine;
	QMap<int, CameraInfo> m_cameras;
	int m_nextId = 0;
};

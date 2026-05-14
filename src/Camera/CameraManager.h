#pragma once

#include <QObject>
#include <QQmlApplicationEngine>
#include <QString>
#include <QVideoSink>

#include <map>
#include <memory>

struct CameraInfo;

class CameraManager : public QObject {
	Q_OBJECT

   public:
	explicit CameraManager(QQmlApplicationEngine* engine,
						   QObject* parent = nullptr);
	~CameraManager() override;

	Q_INVOKABLE int addStream(const QString& name, const QString& url,
							  const QString& customPipeline,
							  bool useCustomPipeline);
	Q_INVOKABLE void removeStream(int id);
	Q_INVOKABLE void editStream(int id, const QString& name, const QString& url,
								const QString& customPipeline,
								bool useCustomPipeline);
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
	void stopPipeline(int id);

	QQmlApplicationEngine* m_engine;
	std::map<int, std::unique_ptr<CameraInfo>> m_cameras;
	int m_nextId = 0;
};

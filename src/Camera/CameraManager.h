#pragma once

#include <qqmlintegration.h>
#include <QJSEngine>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVideoSink>

#include <map>
#include <memory>

struct CameraInfo;

class CameraManager : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_SINGLETON

   public:
	explicit CameraManager(QQmlEngine* engine, QObject* parent = nullptr);

	static CameraManager* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);
	~CameraManager() override;

	CameraManager(const CameraManager&) = delete;
	CameraManager& operator=(const CameraManager&) = delete;
	CameraManager(CameraManager&&) = delete;
	CameraManager& operator=(CameraManager&&) = delete;

	Q_INVOKABLE int addStream(const QString& name, const QString& url,
		const QString& customPipeline, bool useCustomPipeline);
	Q_INVOKABLE void removeStream(int id);
	Q_INVOKABLE void editStream(int id, const QString& name, const QString& url,
		const QString& customPipeline, bool useCustomPipeline);
	Q_INVOKABLE void attachSink(int id, QVideoSink* sink);
	Q_INVOKABLE void reconnectStream(int id);
	Q_INVOKABLE void setDetectionEnabled(int id, bool enabled);

	[[nodiscard]] Q_INVOKABLE QString streamStatus(int id) const;
	[[nodiscard]] Q_INVOKABLE bool streamConnected(int id) const;
	[[nodiscard]] Q_INVOKABLE QVariantList detections(int id) const;

	void setStreamState(int id, const QString& status, bool connected);

   signals:
	void streamStatusChanged(int id, const QString& status);
	void streamConnectedChanged(int id, bool connected);
	void streamError(int id, const QString& message);
	void detectionsChanged(int id, QVariantList detections);

   private:
	void startPipeline(int id);
	void stopPipeline(int id);

	QQmlEngine* m_engine;
	std::map<int, std::unique_ptr<CameraInfo>> m_cameras;
	int m_nextId = 0;
};

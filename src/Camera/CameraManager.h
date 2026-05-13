#pragma once

#include <QMap>
#include <QObject>
#include <QQmlApplicationEngine>

#include "CameraInfo.h"

class CameraManager : public QObject {
	Q_OBJECT

   public:
	explicit CameraManager(QQmlApplicationEngine* engine,
						   QObject* parent = nullptr);

	Q_INVOKABLE void addCamera(int id, const QString& name, const QUrl& url);
	Q_INVOKABLE void removeCamera(int id);
	Q_INVOKABLE void editCamera(int id, const QString& name, const QUrl& url);

	Q_INVOKABLE void initialize();

	Q_INVOKABLE void startCamera(int id);

   private:
	QObject* findPlayerItem(const QString& name);

   private:
	QQmlApplicationEngine* m_engine;

	QMap<int, CameraInfo> m_cameras;
};

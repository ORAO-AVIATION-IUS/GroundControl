#pragma once

#include <QString>
#include <QUrl>

/*
    Stores the pointers to the QML
    for easier mapping in CameraManager
*/

struct CameraInfo {
	QString name;
	QUrl streamUrl;

	QObject* playerItem = nullptr;
	QObject* mediaPlayer = nullptr;
};

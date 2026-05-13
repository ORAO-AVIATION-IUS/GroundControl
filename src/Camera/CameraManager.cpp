#include "CameraManager.h"

#include <QMediaPlayer>
#include <QDebug>

CameraManager::CameraManager(QQmlApplicationEngine* engine, QObject* parent)
    : QObject(parent), m_engine(engine) {}

void CameraManager::addCamera(int id, const QString& name, const QUrl& url) {
    CameraInfo info;
    info.name = name;
    info.streamUrl = url;
    m_cameras[id] = info;
}

void CameraManager::removeCamera(int id) {
    if (!m_cameras.contains(id)) {
        qWarning() << "Camera not found:" << id;
        return;
    }

    CameraInfo& cam = m_cameras[id];

    if (cam.mediaPlayer) {
        QMetaObject::invokeMethod(cam.mediaPlayer, "stop");
        QMetaObject::invokeMethod(cam.mediaPlayer, "setSource", QUrl(""));
    }

    m_cameras.remove(id);
}

void CameraManager::editCamera(int id, const QString& name, const QUrl& url) {
    if (!m_cameras.contains(id)) {
        qWarning() << "Camera not found:" << id;
        return;
    }

    CameraInfo& cam = m_cameras[id];

    if (!cam.mediaPlayer)
        return;

    if (url == cam.streamUrl) {
        cam.name = name;
        return;
    }

    QMetaObject::invokeMethod(cam.mediaPlayer, "stop");
    cam.streamUrl = url;
    startCamera(id);
}

QObject* CameraManager::findPlayerItem(const QString& name) {
    if (m_engine->rootObjects().isEmpty())
        return nullptr;

    QObject* root = m_engine->rootObjects().first();
    return root->findChild<QObject*>(name);
}

void CameraManager::initialize() {
    for (auto it = m_cameras.begin(); it != m_cameras.end(); ++it) {
        CameraInfo& cam = it.value();

        cam.playerItem = findPlayerItem(cam.name);

        if (!cam.playerItem) {
            qWarning() << "Could not find player item:" << cam.name;
            continue;
        }

        cam.mediaPlayer = cam.playerItem->property("mediaPlayer").value<QObject*>();

        if (!cam.mediaPlayer)
            qWarning() << "Could not access MediaPlayer:" << cam.name;
    }
}

void CameraManager::startCamera(int id) {
    if (!m_cameras.contains(id))
        return;

    CameraInfo& cam = m_cameras[id];

    if (!cam.mediaPlayer)
        return;

    QMetaObject::invokeMethod(cam.mediaPlayer, "setSource", cam.streamUrl);
    QMetaObject::invokeMethod(cam.mediaPlayer, "play");

    qInfo() << "Started camera:" << id << "source:" << cam.streamUrl;
}

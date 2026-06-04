#include "DetectionWorker.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutexLocker>
#include <QDataStream>

DetectionWorker::DetectionWorker(int streamId, QObject* parent)
    : QObject(parent), m_streamId(streamId) {}

DetectionWorker::~DetectionWorker() {
    stop();
}

void DetectionWorker::start() {
    m_process = new QProcess(this);

    const QString buildDir = QCoreApplication::applicationDirPath(); // .../build
    const QString projectRoot = buildDir + "/..";                    // .../GroundControl

    const QString python = projectRoot + "/.venv/bin/python3";
    const QString script = buildDir    + "/detector.py";

    m_process->setProgram(python);
    m_process->setArguments({script});

    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &DetectionWorker::onReadyRead);
    connect(m_process, &QProcess::errorOccurred,
            this, &DetectionWorker::onProcessError);

    m_process->start();
    //qwarning doesnt seem to write to stdout gotta investigate
    if (!m_process->waitForStarted(3000)) {
        qWarning() << "Detector failed to start for stream" << m_streamId;
        qWarning() << "  python :" << python;
        qWarning() << "  exists :" << QFileInfo(python).exists();
        qWarning() << "  script :" << script;
        qWarning() << "  exists :" << QFileInfo(script).exists();
    } else {
        qInfo() << "Detector started for stream" << m_streamId;
    }
}

void DetectionWorker::stop() {
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->terminate();
        m_process->waitForFinished(2000);
    }
}

// Called from GStreamer thread — only stores the latest frame
void DetectionWorker::submitFrame(const QByteArray& bgrData, int width, int height) {
    QMutexLocker lock(&m_frameMutex);
    m_pendingFrame = bgrData;
    m_pendingW = width;
    m_pendingH = height;
    m_hasPending = true;

    // start send on worker's thread
    if (!m_busy) {
        QMetaObject::invokeMethod(this, [this]() {
            QMutexLocker l(&m_frameMutex);
            if (!m_hasPending) return;
            QByteArray data = std::move(m_pendingFrame);
            int w = m_pendingW, h = m_pendingH;
            m_hasPending = false;
            m_busy = true;
            l.unlock();
            writeFrame(data, w, h);
        }, Qt::QueuedConnection);
    }
}

void DetectionWorker::writeFrame(const QByteArray& data, int w, int h) {
    if (!m_process || m_process->state() != QProcess::Running) {
        m_busy = false;
        return;
    }
    // raw rgb bytes
    char header[8];
    memcpy(header, &w, 4);
    memcpy(header + 4, &h, 4);
    m_process->write(header, 8);
    m_process->write(data);
}

void DetectionWorker::onReadyRead() {
    while (m_process->canReadLine()) {
        QByteArray line = m_process->readLine().trimmed();
        if (line.isEmpty()) continue;

        // should probably delete this its pretty useless rn
        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(line, &err);
        if (err.error != QJsonParseError::NoError || !doc.isArray()) {
            qWarning() << "Bad detection JSON:" << err.errorString();
            m_busy = false;
            continue;
        }

        QList<Detection> detections;
        for (const QJsonValue& v : doc.array()) {
            QJsonObject o = v.toObject();
            detections.append({
                .x = (float)o["x"].toDouble(),
                .y = (float)o["y"].toDouble(),
                .w = (float)o["w"].toDouble(),
                .h = (float)o["h"].toDouble(),
                .label = o["label"].toString(),
                .score = (float)o["score"].toDouble()
            });
        }

        emit detectionsReady(m_streamId, detections);
        m_busy = false;

        // send next pending frame asap
        QMutexLocker l(&m_frameMutex);
        if (m_hasPending) {
            QByteArray data = std::move(m_pendingFrame);
            int w = m_pendingW, h = m_pendingH;
            m_hasPending = false;
            m_busy = true;
            l.unlock();
            writeFrame(data, w, h);
        }
    }
}

void DetectionWorker::onProcessError(QProcess::ProcessError error) {
    qWarning() << "Detector process error for stream" << m_streamId << ":" << error;
    m_busy = false;
}
#pragma once
#include <QObject>
#include <QProcess>
#include <QByteArray>
#include <QJsonArray>
#include <QThread>
#include <QMutex>
#include <QList>
#include <QCoreApplication>
#include <QDir>
#include <QFile>

struct Detection {
    float x, y, w, h;
    QString label;
    float score;
};

Q_DECLARE_METATYPE(Detection)
Q_DECLARE_METATYPE(QList<Detection>)

class DetectionWorker : public QObject {
    Q_OBJECT
public:
    explicit DetectionWorker(int streamId, QObject* parent = nullptr);
    ~DetectionWorker() override;

    DetectionWorker(const DetectionWorker&) = delete;
    DetectionWorker& operator=(const DetectionWorker&) = delete;
    DetectionWorker(DetectionWorker&&) = delete;
    DetectionWorker& operator=(DetectionWorker&&) = delete;

    // called from gstreamer thread
    void submitFrame(const QByteArray& bgrData, int width, int height);

public slots:
    void start();
    void stop();

signals:
    void detectionsReady(int streamId, QList<Detection> detections);

private slots:
    void onReadyRead();
    void onProcessError(QProcess::ProcessError error);

private:
    void writeFrame(const QByteArray& data, int w, int h);
    void sendNextPending();

    int m_streamId;
    QProcess* m_process = nullptr;
    QMutex m_frameMutex;
    QByteArray m_pendingFrame;
    int m_pendingW = 0, m_pendingH = 0;
    bool m_hasPending = false;
    bool m_busy = false;
};
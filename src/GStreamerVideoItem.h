#pragma once

#include <QImage>
#include <QMutex>
#include <QQuickPaintedItem>

#include <gst/gst.h>
#include <gst/app/gstappsink.h>

#include <atomic>

class GStreamerVideoItem : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QString pipeline MEMBER m_pipelineStr NOTIFY pipelineChanged)
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit GStreamerVideoItem(QQuickItem* parent = nullptr);
    ~GStreamerVideoItem() override;

    void paint(QPainter* painter) override;

    Q_INVOKABLE void connectStream();
    Q_INVOKABLE void disconnectStream();

    bool isConnected() const { return m_connected; }
    QString status() const { return m_status; }

signals:
    void pipelineChanged();
    void connectedChanged();
    void statusChanged();
    void errorOccurred(const QString& message);

private:
    static gboolean onGstBusMessage(GstBus* bus, GstMessage* msg, gpointer user_data);
    static GstFlowReturn onNewSample(GstAppSink* appsink, gpointer user_data);

    void setStatus(const QString& status);
    void setConnected(bool connected);
    void cleanupPipeline();

    GstElement* m_pipeline = nullptr;
    GstElement* m_appsink = nullptr;
    GstBus* m_bus = nullptr;

    QString m_pipelineStr;
    std::atomic<bool> m_connected{false};
    QString m_status;

    QMutex m_frameMutex;
    QImage m_frame;
};

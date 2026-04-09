#include "GStreamerVideoItem.h"

#include <QPainter>

#include <gst/gst.h>
#include <gst/app/gstappsink.h>

GStreamerVideoItem::GStreamerVideoItem(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    static bool gstInitialized = false;
    if (!gstInitialized) {
        gst_init(nullptr, nullptr);
        gstInitialized = true;
    }
}

GStreamerVideoItem::~GStreamerVideoItem() {
    cleanupPipeline();
}

void GStreamerVideoItem::paint(QPainter* painter) {
    QMutexLocker locker(&m_frameMutex);

    if (m_frame.isNull()) {
        painter->fillRect(boundingRect(), QColor(20, 20, 30));
        painter->setPen(Qt::white);
        painter->drawText(boundingRect(), Qt::AlignCenter,
                          m_connected ? "Waiting for video..." : "No stream connected");
        return;
    }

    QSizeF scaled = QSizeF(m_frame.size()).scaled(boundingRect().size(), Qt::KeepAspectRatio);
    qreal x = (width() - scaled.width()) / 2.0;
    qreal y = (height() - scaled.height()) / 2.0;
    QRectF targetRect(x, y, scaled.width(), scaled.height());

    painter->drawImage(targetRect, m_frame);
}

void GStreamerVideoItem::connectStream() {
    if (m_connected) {
        cleanupPipeline();
    }

    if (m_pipelineStr.isEmpty()) {
        setStatus("Error: pipeline string is empty");
        return;
    }

    GError* error = nullptr;
    m_pipeline = gst_parse_launch(m_pipelineStr.toUtf8().constData(), &error);

    if (!m_pipeline) {
        QString errMsg = error ? QString::fromUtf8(error->message) : "Unknown error";
        if (error) g_error_free(error);
        setStatus("Pipeline error: " + errMsg);
        emit errorOccurred(errMsg);
        return;
    }

    // Find appsink named "sink"
    m_appsink = gst_bin_get_by_name(GST_BIN(m_pipeline), "sink");
    if (!m_appsink || !GST_IS_APP_SINK(m_appsink)) {
        setStatus("Error: pipeline must have an appsink named 'sink'");
        cleanupPipeline();
        return;
    }

    // Configure appsink
    g_object_set(m_appsink, "emit-signals", TRUE, "sync", FALSE, "max-buffers", 1,
                 "drop", TRUE, nullptr);

    g_signal_connect(m_appsink, "new-sample", G_CALLBACK(onNewSample), this);
    gst_object_unref(m_appsink);  // pipeline holds the ref

    // Watch bus for messages
    m_bus = gst_element_get_bus(m_pipeline);
    gst_bus_add_watch(m_bus, onGstBusMessage, this);
    gst_object_unref(m_bus);

    GstStateChangeReturn ret = gst_element_set_state(m_pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        setStatus("Failed to start pipeline");
        cleanupPipeline();
        return;
    }

    setConnected(true);
    setStatus("Connecting...");
    update();
}

void GStreamerVideoItem::disconnectStream() {
    cleanupPipeline();
    setStatus("Disconnected");
    update();
}

void GStreamerVideoItem::cleanupPipeline() {
    if (m_pipeline) {
        gst_element_set_state(m_pipeline, GST_STATE_NULL);
        gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
    }
    m_bus = nullptr;
    m_appsink = nullptr;
    setConnected(false);

    QMutexLocker locker(&m_frameMutex);
    m_frame = QImage();
}

void GStreamerVideoItem::setStatus(const QString& status) {
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
    }
}

void GStreamerVideoItem::setConnected(bool connected) {
    if (m_connected != connected) {
        m_connected = connected;
        emit connectedChanged();
    }
}

// static
gboolean GStreamerVideoItem::onGstBusMessage(GstBus* /*bus*/, GstMessage* msg,
                                         gpointer user_data) {
    auto* self = static_cast<GStreamerVideoItem*>(user_data);

    switch (GST_MESSAGE_TYPE(msg)) {
        case GST_MESSAGE_ERROR: {
            GError* err = nullptr;
            gchar* debug = nullptr;
            gst_message_parse_error(msg, &err, &debug);
            QString errMsg = QString::fromUtf8(err->message);
            QString debugInfo = QString::fromUtf8(debug);
            g_error_free(err);
            g_free(debug);
            QMetaObject::invokeMethod(
                self, [self, errMsg, debugInfo]() {
                    self->setStatus("Error: " + errMsg);
                    self->setConnected(false);
                    emit self->errorOccurred(errMsg + "\nDebug: " + debugInfo);
                },
                Qt::QueuedConnection);
            break;
        }
        case GST_MESSAGE_WARNING: {
            GError* err = nullptr;
            gchar* debug = nullptr;
            gst_message_parse_warning(msg, &err, &debug);
            QString warnMsg = QString::fromUtf8(err->message);
            g_error_free(err);
            g_free(debug);
            QMetaObject::invokeMethod(
                self, [self, warnMsg]() { self->setStatus("Warning: " + warnMsg); },
                Qt::QueuedConnection);
            break;
        }
        case GST_MESSAGE_EOS:
            QMetaObject::invokeMethod(
                self,
                [self]() {
                    self->setStatus("Stream ended (EOS)");
                    self->setConnected(false);
                },
                Qt::QueuedConnection);
            break;
        case GST_MESSAGE_STATE_CHANGED: {
            GstState oldState, newState, pending;
            gst_message_parse_state_changed(msg, &oldState, &newState, &pending);
            if (newState == GST_STATE_PLAYING) {
                QMetaObject::invokeMethod(
                    self, [self]() { self->setStatus("Streaming"); },
                    Qt::QueuedConnection);
            }
            break;
        }
        default:
            break;
    }
    return TRUE;
}

// static
GstFlowReturn GStreamerVideoItem::onNewSample(GstAppSink* appsink, gpointer user_data) {
    auto* self = static_cast<GStreamerVideoItem*>(user_data);

    GstSample* sample = gst_app_sink_pull_sample(appsink);
    if (!sample) return GST_FLOW_OK;

    GstCaps* caps = gst_sample_get_caps(sample);
    if (!caps) {
        gst_sample_unref(sample);
        return GST_FLOW_OK;
    }

    GstStructure* s = gst_caps_get_structure(caps, 0);
    int width = 0, height = 0;
    gst_structure_get_int(s, "width", &width);
    gst_structure_get_int(s, "height", &height);

    if (width <= 0 || height <= 0) {
        gst_sample_unref(sample);
        return GST_FLOW_OK;
    }

    GstBuffer* buf = gst_sample_get_buffer(sample);
    GstMapInfo map;
    if (!gst_buffer_map(buf, &map, GST_MAP_READ)) {
        gst_sample_unref(sample);
        return GST_FLOW_OK;
    }

    // Determine format from caps
    const gchar* format = gst_structure_get_string(s, "format");
    QImage::Format qimgFormat = QImage::Format_Invalid;
    int bytesPerPixel = 3;

    if (g_strcmp0(format, "RGB") == 0) {
        qimgFormat = QImage::Format_RGB888;
        bytesPerPixel = 3;
    } else if (g_strcmp0(format, "BGR") == 0) {
        qimgFormat = QImage::Format_BGR30;  // Will convert below
        bytesPerPixel = 3;
    } else if (g_strcmp0(format, "RGBA") == 0) {
        qimgFormat = QImage::Format_RGBA8888;
        bytesPerPixel = 4;
    } else if (g_strcmp0(format, "BGRA") == 0) {
        qimgFormat = QImage::Format_ARGB32;  // BGRA maps to ARGB32 in memory
        bytesPerPixel = 4;
    }

    if (qimgFormat != QImage::Format_Invalid) {
        QImage img;
        if (g_strcmp0(format, "BGR") == 0) {
            // BGR needs manual conversion to RGB
            img = QImage(width, height, QImage::Format_RGB888);
            const uchar* src = map.data;
            for (int y = 0; y < height; ++y) {
                auto* dst = img.scanLine(y);
                const uchar* srcLine = src + y * width * 3;
                for (int x = 0; x < width; ++x) {
                    dst[x * 3 + 0] = srcLine[x * 3 + 2];  // R
                    dst[x * 3 + 1] = srcLine[x * 3 + 1];  // G
                    dst[x * 3 + 2] = srcLine[x * 3 + 0];  // B
                }
            }
        } else {
            img = QImage(map.data, width, height, width * bytesPerPixel, qimgFormat).copy();
        }

        {
            QMutexLocker locker(&self->m_frameMutex);
            self->m_frame = std::move(img);
        }

        QMetaObject::invokeMethod(self, "update", Qt::QueuedConnection);
    }

    gst_buffer_unmap(buf, &map);
    gst_sample_unref(sample);
    return GST_FLOW_OK;
}

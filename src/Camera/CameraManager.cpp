#include "CameraManager.h"

#include <QDebug>
#include <QImage>
#include <QVideoFrame>

#include <gst/gst.h>
#include <gst/app/gstappsink.h>

namespace {

// Walk up from a GstObject to find a pipeline tagged with our stream id.
int findStreamId(GstObject* obj) {
	while (obj) {
		auto id = GPOINTER_TO_INT(
			g_object_get_data(G_OBJECT(obj), "agc-stream-id"));
		if (id > 0)
			return id;
		obj = GST_OBJECT_PARENT(obj);
	}
	return -1;
}

void onNewSample(GstAppSink* appsink, gpointer userData) {
	auto* cam = static_cast<CameraInfo*>(userData);
	GstSample* sample = gst_app_sink_pull_sample(appsink);
	if (!sample)
		return;

	GstCaps* caps = gst_sample_get_caps(sample);
	if (!caps) {
		gst_sample_unref(sample);
		return;
	}

	GstStructure* s = gst_caps_get_structure(caps, 0);
	int width = 0, height = 0;
	gst_structure_get_int(s, "width", &width);
	gst_structure_get_int(s, "height", &height);

	if (width <= 0 || height <= 0) {
		gst_sample_unref(sample);
		return;
	}

	GstBuffer* buffer = gst_sample_get_buffer(sample);
	GstMapInfo map;

	if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
		QImage image(map.data, width, height, QImage::Format_RGBA8888);

		QImage frame = (image.bytesPerLine() == width * 4)
			? std::move(image)
			: image.copy();

		QVideoSink* sink = cam->sink;  // QPointer copy — thread-safe
		if (sink) {
			QMetaObject::invokeMethod(
				sink, [sink, f = std::move(frame)]() {
					sink->setVideoFrame(QVideoFrame(f));
				});
		}

		gst_buffer_unmap(buffer, &map);
	}

	gst_sample_unref(sample);
}

void onPadAdded(GstElement* /*src*/, GstPad* newPad, gpointer userData) {
	auto* convert = static_cast<GstElement*>(userData);
	GstPad* sinkPad = gst_element_get_static_pad(convert, "sink");

	if (gst_pad_is_linked(sinkPad)) {
		gst_object_unref(sinkPad);
		return;
	}

	GstCaps* newPadCaps = gst_pad_get_current_caps(newPad);
	if (!newPadCaps) {
		gst_object_unref(sinkPad);
		return;
	}

	GstCaps* filter = gst_caps_new_simple("video/x-raw", nullptr);
	bool isVideo = gst_caps_can_intersect(newPadCaps, filter);
	gst_caps_unref(filter);
	gst_caps_unref(newPadCaps);

	if (!isVideo) {
		gst_object_unref(sinkPad);
		return;
	}

	GstPadLinkReturn ret = gst_pad_link(newPad, sinkPad);
	if (ret != GST_PAD_LINK_OK)
		qWarning() << "Pad link failed:" << gst_pad_link_get_name(ret);
	else
		qInfo() << "Linked uridecodebin video pad";

	gst_object_unref(sinkPad);
}

// Sync bus handler — runs on GStreamer streaming thread.
// Marshals all work to Qt GUI thread via QMetaObject::invokeMethod.
GstBusSyncReply onBusMessage(GstBus* /*bus*/, GstMessage* msg,
							 gpointer userData) {
	auto* mgr = static_cast<CameraManager*>(userData);

	int streamId = findStreamId(GST_MESSAGE_SRC(msg)) - 1;
	if (streamId < 0) {
		return GST_BUS_PASS;
	}

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
			mgr,
			[mgr, streamId, errMsg, debugInfo]() {
				mgr->setStreamState(streamId, "Error: " + errMsg,
									false);
				emit mgr->streamError(streamId,
									  errMsg + "\n" + debugInfo);
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
			mgr,
			[mgr, streamId, warnMsg]() {
				mgr->setStreamState(streamId,
									"Warning: " + warnMsg, true);
			},
			Qt::QueuedConnection);
		break;
	}
	case GST_MESSAGE_EOS:
		QMetaObject::invokeMethod(
			mgr,
			[mgr, streamId]() {
				mgr->setStreamState(streamId, "Stream ended", false);
			},
			Qt::QueuedConnection);
		break;
	case GST_MESSAGE_STATE_CHANGED: {
		GstState oldState, newState, pending;
		gst_message_parse_state_changed(msg, &oldState, &newState,
										&pending);
		if (newState == GST_STATE_PLAYING) {
			QMetaObject::invokeMethod(
				mgr,
				[mgr, streamId]() {
					mgr->setStreamState(streamId, "Streaming", true);
				},
				Qt::QueuedConnection);
		}
		break;
	}
	default:
		break;
	}

	return GST_BUS_PASS;
}

}  // namespace

CameraManager::CameraManager(QQmlApplicationEngine* engine, QObject* parent)
    : QObject(parent), m_engine(engine) {
	gst_init(nullptr, nullptr);
}

CameraManager::~CameraManager() {
	for (auto it = m_cameras.begin(); it != m_cameras.end(); ++it)
		stopPipeline(it.key());
}

int CameraManager::addStream(const QString& name, const QUrl& url) {
	int id = m_nextId++;
	auto& cam = m_cameras[id];
	cam.name = name;
	cam.streamUrl = url;

	startPipeline(id);
	setStreamState(id, "Connecting...", false);

	qInfo() << "Added stream:" << id << name << url;
	return id;
}

int CameraManager::addCustomStream(const QString& name,
								   const QString& pipeline) {
	int id = m_nextId++;
	auto& cam = m_cameras[id];
	cam.name = name;
	cam.customPipeline = pipeline;
	cam.useCustomPipeline = true;

	startCustomPipeline(id);
	setStreamState(id, "Connecting...", false);

	qInfo() << "Added custom stream:" << id << name;
	return id;
}

void CameraManager::removeStream(int id) {
	if (!m_cameras.contains(id)) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	stopPipeline(id);
	m_cameras.remove(id);

	qInfo() << "Removed stream:" << id;
}

void CameraManager::editStream(int id, const QString& name, const QUrl& url) {
	if (!m_cameras.contains(id)) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	auto& cam = m_cameras[id];
	cam.name = name;

	if (url != cam.streamUrl || cam.useCustomPipeline) {
		cam.streamUrl = url;
		cam.useCustomPipeline = false;
		cam.customPipeline.clear();
		stopPipeline(id);
		startPipeline(id);
		setStreamState(id, "Connecting...", false);
	}

	qInfo() << "Edited stream:" << id << name << url;
}

void CameraManager::editCustomStream(int id, const QString& name,
									 const QString& pipeline) {
	if (!m_cameras.contains(id)) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	auto& cam = m_cameras[id];
	cam.name = name;

	if (pipeline != cam.customPipeline || !cam.useCustomPipeline) {
		cam.customPipeline = pipeline;
		cam.useCustomPipeline = true;
		cam.streamUrl.clear();
		stopPipeline(id);
		startCustomPipeline(id);
		setStreamState(id, "Connecting...", false);
	}

	qInfo() << "Edited custom stream:" << id << name;
}

void CameraManager::attachSink(int id, QVideoSink* sink) {
	if (!m_cameras.contains(id)) {
		qWarning() << "Stream not found:" << id;
		return;
	}
	m_cameras[id].sink = sink;
	qInfo() << "Attached sink for stream:" << id << sink;
}

void CameraManager::reconnectStream(int id) {
	if (!m_cameras.contains(id)) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	auto& cam = m_cameras[id];
	stopPipeline(id);

	if (cam.useCustomPipeline)
		startCustomPipeline(id);
	else
		startPipeline(id);

	setStreamState(id, "Reconnecting...", false);
}

QString CameraManager::streamStatus(int id) const {
	return m_cameras.value(id).status;
}

bool CameraManager::streamConnected(int id) const {
	return m_cameras.value(id).connected;
}

void CameraManager::setStreamState(int id, const QString& status,
								   bool connected) {
	if (!m_cameras.contains(id))
		return;

	auto& cam = m_cameras[id];

	if (cam.status != status) {
		cam.status = status;
		emit streamStatusChanged(id, status);
	}
	if (cam.connected != connected) {
		cam.connected = connected;
		emit streamConnectedChanged(id, connected);
	}
}

void CameraManager::startPipeline(int id) {
	auto& cam = m_cameras[id];
	if (cam.streamUrl.isEmpty())
		return;

	GstElement* uridecodebin = gst_element_factory_make("uridecodebin",
														nullptr);
	GstElement* convert = gst_element_factory_make("videoconvert", nullptr);
	GstElement* capsfilter = gst_element_factory_make("capsfilter", nullptr);
	GstElement* appsink = gst_element_factory_make("appsink", "sink");

	if (!uridecodebin || !convert || !capsfilter || !appsink) {
		qWarning() << "Failed to create GStreamer elements";
		if (uridecodebin) gst_object_unref(uridecodebin);
		if (convert) gst_object_unref(convert);
		if (capsfilter) gst_object_unref(capsfilter);
		if (appsink) gst_object_unref(appsink);
		setStreamState(id, "Error: failed to create elements", false);
		return;
	}

	// Low-latency: disable all buffering for live drone streams.
	g_object_set(uridecodebin,
				 "uri", cam.streamUrl.toString().toUtf8().constData(),
				 "buffer-size", static_cast<gint64>(0),
				 "buffer-duration", static_cast<gint64>(0),
				 "download", FALSE,
				 "use-buffering", FALSE,
				 nullptr);

	GstCaps* caps = gst_caps_new_simple("video/x-raw",
										"format", G_TYPE_STRING, "RGBA",
										nullptr);
	g_object_set(capsfilter, "caps", caps, nullptr);
	gst_caps_unref(caps);

	g_object_set(appsink,
				 "emit-signals", TRUE,
				 "drop", TRUE,
				 "max-buffers", 1,
				 "sync", FALSE,
				 nullptr);

	cam.pipeline = gst_pipeline_new(nullptr);
	gst_bin_add_many(GST_BIN(cam.pipeline),
					 uridecodebin, convert, capsfilter, appsink, nullptr);

	gst_element_link_many(convert, capsfilter, appsink, nullptr);

	// Tag pipeline so bus messages can find the stream id.
	g_object_set_data(G_OBJECT(cam.pipeline), "agc-stream-id",
					  GINT_TO_POINTER(id + 1));  // +1 so 0 = not found

	g_signal_connect(uridecodebin, "pad-added",
					 G_CALLBACK(onPadAdded), convert);

	g_signal_connect(appsink, "new-sample",
					 G_CALLBACK(onNewSample), &m_cameras[id]);
	cam.appsink = appsink;

	GstBus* bus = gst_pipeline_get_bus(GST_PIPELINE(cam.pipeline));
	gst_bus_set_sync_handler(bus, onBusMessage, this, nullptr);
	gst_object_unref(bus);

	gst_element_set_state(cam.pipeline, GST_STATE_PLAYING);
	qInfo() << "Pipeline started for:" << cam.streamUrl;
}

void CameraManager::startCustomPipeline(int id) {
	auto& cam = m_cameras[id];
	if (cam.customPipeline.isEmpty())
		return;

	QString fullPipeline = QStringLiteral(
		"%1 ! videoconvert ! video/x-raw,format=RGBA ! "
		"appsink name=sink sync=false drop=true max-buffers=1 emit-signals=true")
		.arg(cam.customPipeline);

	GError* error = nullptr;
	cam.pipeline = gst_parse_launch(fullPipeline.toUtf8().constData(),
									&error);

	if (!cam.pipeline) {
		QString errMsg = error ? QString::fromUtf8(error->message)
							   : "Unknown error";
		if (error) g_error_free(error);
		setStreamState(id, "Error: " + errMsg, false);
		return;
	}

	g_object_set_data(G_OBJECT(cam.pipeline), "agc-stream-id",
					  GINT_TO_POINTER(id + 1));

	auto* appsink = gst_bin_get_by_name(GST_BIN(cam.pipeline), "sink");
	if (!appsink) {
		setStreamState(id,
					   "Error: pipeline must produce decoded video",
					   false);
		gst_object_unref(cam.pipeline);
		cam.pipeline = nullptr;
		return;
	}
	cam.appsink = appsink;

	g_signal_connect(appsink, "new-sample",
					 G_CALLBACK(onNewSample), &m_cameras[id]);

	GstBus* bus = gst_pipeline_get_bus(GST_PIPELINE(cam.pipeline));
	gst_bus_set_sync_handler(bus, onBusMessage, this, nullptr);
	gst_object_unref(bus);

	gst_element_set_state(cam.pipeline, GST_STATE_PLAYING);
	qInfo() << "Custom pipeline started for:" << cam.name;
}

void CameraManager::stopPipeline(int id) {
	auto& cam = m_cameras[id];
	if (!cam.pipeline)
		return;

	gst_element_set_state(cam.pipeline, GST_STATE_NULL);
	gst_object_unref(cam.pipeline);
	cam.pipeline = nullptr;
	cam.appsink = nullptr;
}

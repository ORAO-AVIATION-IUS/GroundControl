#include "CameraManager.h"

#include <QDebug>
#include <QImage>
#include <QUrl>
#include <QVideoFrame>

#include <gst/gst.h>
#include <gst/app/gstappsink.h>

// Per-stream state, internal to this translation unit.
struct CameraInfo {
	QString name;
	QUrl streamUrl;
	QString customPipeline;
	bool useCustomPipeline = false;
	bool connected = false;
	QString status;
	QPointer<QVideoSink> sink;
	GstElement* pipeline = nullptr;
};

namespace {

// Walk up GstObject hierarchy to find the pipeline tagged with our stream id.
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

GstFlowReturn onNewSample(GstAppSink* appsink, gpointer userData) {
	auto* cam = static_cast<CameraInfo*>(userData);
	GstSample* sample = gst_app_sink_pull_sample(appsink);
	if (!sample)
		return GST_FLOW_OK;

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

	GstBuffer* buffer = gst_sample_get_buffer(sample);
	GstMapInfo map;

	if (gst_buffer_map(buffer, &map, GST_MAP_READ)) {
		QImage image(map.data, width, height, QImage::Format_RGBA8888);

		QImage frame = (image.bytesPerLine() == width * 4)
			? std::move(image)
			: image.copy();

		QVideoSink* sink = cam->sink;
		if (sink) {
			QMetaObject::invokeMethod(
				sink, [sink, f = std::move(frame)]() {
					sink->setVideoFrame(QVideoFrame(f));
				});
		}

		gst_buffer_unmap(buffer, &map);
	}

	gst_sample_unref(sample);
	return GST_FLOW_OK;
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

	#pragma GCC diagnostic push
	#pragma GCC diagnostic ignored "-Wsentinel"
	GstCaps* filter = gst_caps_new_simple("video/x-raw", nullptr);
	#pragma GCC diagnostic pop
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

// Bus handler running on GStreamer streaming thread; marshals to GUI thread.
GstBusSyncReply onBusMessage(GstBus* /*bus*/, GstMessage* msg,
							 gpointer userData) {
	auto* mgr = static_cast<CameraManager*>(userData);

	int streamId = findStreamId(GST_MESSAGE_SRC(msg)) - 1;
	if (streamId < 0)
		return GST_BUS_PASS;

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
				mgr->setStreamState(streamId, "Error: " + errMsg, false);
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

CameraManager::CameraManager(QQmlEngine* engine, QObject* parent)
	: QObject(parent), m_engine(engine) {
	gst_init(nullptr, nullptr);
}

CameraManager* CameraManager::create(QQmlEngine* qmlEngine, QJSEngine* jsEngine) {
	Q_UNUSED(jsEngine);
	return new CameraManager(qmlEngine, qmlEngine);
}

CameraManager::~CameraManager() {
	for (auto& [key, value] : m_cameras)
		stopPipeline(key);
}

int CameraManager::addStream(const QString& name, const QString& url,
							 const QString& customPipeline,
							 bool useCustomPipeline) {
	int id = m_nextId++;
	m_cameras[id] = std::make_unique<CameraInfo>();
	auto* cam = m_cameras[id].get();
	cam->name = name;
	cam->streamUrl = QUrl(url);
	cam->customPipeline = customPipeline;
	cam->useCustomPipeline = useCustomPipeline;

	startPipeline(id);
	setStreamState(id, "Connecting...", false);

	qInfo() << "Added stream:" << id << name
			<< (useCustomPipeline ? customPipeline : url);
	return id;
}

void CameraManager::removeStream(int id) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	stopPipeline(id);
	m_cameras.erase(it);
	qInfo() << "Removed stream:" << id;
}

void CameraManager::editStream(int id, const QString& name,
							   const QString& url,
							   const QString& customPipeline,
							   bool useCustomPipeline) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	auto* cam = it->second.get();
	cam->name = name;

	bool needsRestart = false;

	if (useCustomPipeline) {
		if (cam->customPipeline != customPipeline
			|| !cam->useCustomPipeline) {
			cam->customPipeline = customPipeline;
			cam->useCustomPipeline = true;
			cam->streamUrl.clear();
			needsRestart = true;
		}
	} else {
		QUrl newUrl(url);
		if (cam->streamUrl != newUrl || cam->useCustomPipeline) {
			cam->streamUrl = newUrl;
			cam->useCustomPipeline = false;
			cam->customPipeline.clear();
			needsRestart = true;
		}
	}

	if (needsRestart) {
		stopPipeline(id);
		startPipeline(id);
		setStreamState(id, "Connecting...", false);
	}

	qInfo() << "Edited stream:" << id << name;
}

void CameraManager::attachSink(int id, QVideoSink* sink) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		qWarning() << "Stream not found:" << id;
		return;
	}
	it->second->sink = sink;
	qInfo() << "Attached sink for stream:" << id << sink;
}

void CameraManager::reconnectStream(int id) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	stopPipeline(id);
	startPipeline(id);
	setStreamState(id, "Reconnecting...", false);
}

QString CameraManager::streamStatus(int id) const {
	auto it = m_cameras.find(id);
	return (it != m_cameras.end()) ? it->second->status : QString();
}

bool CameraManager::streamConnected(int id) const {
	auto it = m_cameras.find(id);
	return (it != m_cameras.end()) ? it->second->connected : false;
}

void CameraManager::setStreamState(int id, const QString& status,
								   bool connected) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end())
		return;

	auto* cam = it->second.get();

	if (cam->status != status) {
		cam->status = status;
		emit streamStatusChanged(id, status);
	}
	if (cam->connected != connected) {
		cam->connected = connected;
		emit streamConnectedChanged(id, connected);
	}
}

void CameraManager::startPipeline(int id) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end())
		return;

	auto* cam = it->second.get();
	GstElement* pipeline = nullptr;
	GstElement* appsinkElem = nullptr;

	if (cam->useCustomPipeline) {
		if (cam->customPipeline.isEmpty())
			return;

		QString fullPipeline = QStringLiteral(
			"%1 ! videoconvert ! video/x-raw,format=RGBA ! "
			"appsink name=sink sync=false drop=true max-buffers=1 "
			"emit-signals=true")
			.arg(cam->customPipeline);

		GError* error = nullptr;
		pipeline = gst_parse_launch(
			fullPipeline.toUtf8().constData(), &error);

		if (!pipeline) {
			QString errMsg = error ? QString::fromUtf8(error->message)
								   : "Unknown error";
			if (error) g_error_free(error);
			setStreamState(id, "Error: " + errMsg, false);
			return;
		}

		appsinkElem =
			gst_bin_get_by_name(GST_BIN(pipeline), "sink");
		if (!appsinkElem) {
			setStreamState(id,
						   "Error: pipeline must produce decoded video",
						   false);
			gst_object_unref(pipeline);
			return;
		}
	} else {
		if (cam->streamUrl.isEmpty())
			return;

		GstElement* uridecodebin =
			gst_element_factory_make("uridecodebin", nullptr);
		GstElement* convert =
			gst_element_factory_make("videoconvert", nullptr);
		GstElement* capsfilter =
			gst_element_factory_make("capsfilter", nullptr);
		appsinkElem = gst_element_factory_make("appsink", "sink");

		if (!uridecodebin || !convert || !capsfilter || !appsinkElem) {
			qWarning() << "Failed to create GStreamer elements";
			if (uridecodebin) gst_object_unref(uridecodebin);
			if (convert) gst_object_unref(convert);
			if (capsfilter) gst_object_unref(capsfilter);
			if (appsinkElem) gst_object_unref(appsinkElem);
			setStreamState(id, "Error: failed to create elements", false);
			return;
		}

		g_object_set(uridecodebin,
					 "uri",
					 cam->streamUrl.toString().toUtf8().constData(),
					 "buffer-size", static_cast<gint64>(0),
					 "buffer-duration", static_cast<gint64>(0),
					 "download", FALSE,
					 "use-buffering", FALSE,
					 nullptr);

		GstCaps* caps = gst_caps_new_simple("video/x-raw", "format",
											G_TYPE_STRING, "RGBA",
											nullptr);
		g_object_set(capsfilter, "caps", caps, nullptr);
		gst_caps_unref(caps);

		g_object_set(appsinkElem,
					 "emit-signals", TRUE,
					 "drop", TRUE,
					 "max-buffers", 1,
					 "sync", FALSE,
					 nullptr);

		pipeline = gst_pipeline_new(nullptr);
		gst_bin_add_many(GST_BIN(pipeline), uridecodebin, convert,
						 capsfilter, appsinkElem, nullptr);
		gst_element_link_many(convert, capsfilter, appsinkElem, nullptr);

		g_signal_connect(uridecodebin, "pad-added",
						 G_CALLBACK(onPadAdded), convert);
	}

	// Tag pipeline for bus message routing.
	g_object_set_data(G_OBJECT(pipeline), "agc-stream-id",
					  GINT_TO_POINTER(id + 1));  // +1 so 0 = not found

	cam->pipeline = pipeline;

	g_signal_connect(appsinkElem, "new-sample",
					 G_CALLBACK(onNewSample), cam);

	// gst_bin_get_by_name returns an owned ref; release it after connecting signals.
	if (cam->useCustomPipeline)
		gst_object_unref(appsinkElem);

	GstBus* bus = gst_pipeline_get_bus(GST_PIPELINE(pipeline));
	gst_bus_set_sync_handler(bus, onBusMessage, this, nullptr);
	gst_object_unref(bus);

	gst_element_set_state(pipeline, GST_STATE_PLAYING);
	qInfo() << "Pipeline started for:" << cam->name;
}

void CameraManager::stopPipeline(int id) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end())
		return;

	auto* cam = it->second.get();
	if (!cam->pipeline)
		return;

	gst_element_set_state(cam->pipeline, GST_STATE_NULL);
	gst_object_unref(cam->pipeline);
	cam->pipeline = nullptr;
}

#include "CameraManager.h"

#include <QDebug>
#include <QImage>
#include <QUrl>
#include <QVideoFrame>

#include <gst/app/gstappsink.h>
#include <gst/gst.h>

#include <QThread>
#include "DetectionWorker.h"

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

	// Detection
	std::unique_ptr<QThread> detectionThread;
	std::unique_ptr<DetectionWorker> detectionWorker;
	QList<Detection> lastDetections;
	bool detectionEnabled = false;
};

namespace {

// Walk up GstObject hierarchy to find the pipeline tagged with our stream id.
int findStreamId(GstObject* obj) {
	while (obj != nullptr) {
		auto id =
			GPOINTER_TO_INT(g_object_get_data(G_OBJECT(obj), "agc-stream-id"));
		if (id > 0) {
			return id;
		}
		obj = GST_OBJECT_PARENT(obj);
	}
	return -1;
}

GstFlowReturn onNewSample(GstAppSink* appsink, gpointer userData) {
	auto* cam = static_cast<CameraInfo*>(userData);
	GstSample* sample = gst_app_sink_pull_sample(appsink);
	if (sample == nullptr) {
		return GST_FLOW_OK;
	}

	GstCaps* caps = gst_sample_get_caps(sample);
	if (caps == nullptr) {
		gst_sample_unref(sample);
		return GST_FLOW_OK;
	}

	GstStructure* s = gst_caps_get_structure(caps, 0);
	int width = 0;
	int height = 0;
	gst_structure_get_int(s, "width", &width);
	gst_structure_get_int(s, "height", &height);
	if (width <= 0 || height <= 0) {
		gst_sample_unref(sample);
		return GST_FLOW_OK;
	}

	GstBuffer* buffer = gst_sample_get_buffer(sample);
	GstMapInfo map;

	if (gst_buffer_map(buffer, &map, GST_MAP_READ) != 0) {
		QImage image(map.data, width, height, QImage::Format_RGBA8888);

		// Deep-copy: `image` aliases the GStreamer buffer, which is unmapped
		// below — but the frame is consumed later on the GUI thread, so it must
		// own its pixels or it renders black (use-after-unmap).
		QImage frame = image.copy();

		QVideoSink* sink = cam->sink;
		if (sink != nullptr) {
			QMetaObject::invokeMethod(sink, [sink, f = std::move(frame)]() {
				sink->setVideoFrame(QVideoFrame(f));
			});
		}

		if (cam->detectionEnabled && cam->detectionWorker) {
			const int pixels = width * height;
			QByteArray bgr(pixels * 3, Qt::Uninitialized);
			const uchar* src = map.data;
			auto* dst = reinterpret_cast<uchar*>(bgr.data());
			for (int i = 0; i < pixels; ++i) {
				dst[(i * 3) + 0] = src[(i * 4) + 2];
				dst[(i * 3) + 1] = src[(i * 4) + 1];
				dst[(i * 3) + 2] = src[(i * 4) + 0];
			}
			cam->detectionWorker->submitFrame(bgr, width, height);
		}

		gst_buffer_unmap(buffer, &map);
	}

	gst_sample_unref(sample);
	return GST_FLOW_OK;
}

void onPadAdded(GstElement* /*src*/, GstPad* newPad, gpointer userData) {
	auto* convert = static_cast<GstElement*>(userData);
	GstPad* sinkPad = gst_element_get_static_pad(convert, "sink");

	if (gst_pad_is_linked(sinkPad) != 0) {
		gst_object_unref(sinkPad);
		return;
	}

	GstCaps* newPadCaps = gst_pad_get_current_caps(newPad);
	if (newPadCaps == nullptr) {
		gst_object_unref(sinkPad);
		return;
	}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsentinel"
	GstCaps* filter = gst_caps_new_simple("video/x-raw", nullptr);
#pragma GCC diagnostic pop
	bool isVideo = gst_caps_can_intersect(newPadCaps, filter) != 0;
	gst_caps_unref(filter);
	gst_caps_unref(newPadCaps);

	if (!isVideo) {
		gst_object_unref(sinkPad);
		return;
	}

	GstPadLinkReturn ret = gst_pad_link(newPad, sinkPad);
	if (ret != GST_PAD_LINK_OK) {
		qWarning() << "Pad link failed:" << gst_pad_link_get_name(ret);
	} else {
		qInfo() << "Linked uridecodebin video pad";
	}

	gst_object_unref(sinkPad);
}

// Bus handler running on GStreamer streaming thread; marshals to GUI thread.
GstBusSyncReply onBusMessage(
	GstBus* /*bus*/, GstMessage* msg, gpointer userData) {
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
					mgr->setStreamState(streamId, "Error: " + errMsg, false);
					emit mgr->streamError(streamId, errMsg + "\n" + debugInfo);
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
					mgr->setStreamState(streamId, "Warning: " + warnMsg, true);
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
			GstState oldState = GST_STATE_NULL;
			GstState newState = GST_STATE_NULL;
			GstState pending = GST_STATE_NULL;
			gst_message_parse_state_changed(
				msg, &oldState, &newState, &pending);
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

struct PipelineSetup {
	GstElement* pipeline = nullptr;
	GstElement* appSink = nullptr;
	bool releaseAppSink = false;
};

void unrefElement(GstElement* element) {
	if (element != nullptr) {
		gst_object_unref(element);
	}
}

void unrefCreatedElements(GstElement* uridecodebin, GstElement* convert,
	GstElement* capsfilter, GstElement* appsinkElem) {
	unrefElement(uridecodebin);
	unrefElement(convert);
	unrefElement(capsfilter);
	unrefElement(appsinkElem);
}

PipelineSetup createCustomPipeline(
	CameraManager* manager, int id, const CameraInfo& camera) {
	QString fullPipeline = QStringLiteral(
		"%1 ! videoconvert ! video/x-raw,format=RGBA ! "
		"appsink name=sink sync=false drop=true max-buffers=1 "
		"emit-signals=true")
							   .arg(camera.customPipeline);

	GError* error = nullptr;
	GstElement* pipeline =
		gst_parse_launch(fullPipeline.toUtf8().constData(), &error);

	if (pipeline == nullptr) {
		QString errMsg = (error != nullptr) ? QString::fromUtf8(error->message)
											: QStringLiteral("Unknown error");
		if (error != nullptr) {
			g_error_free(error);
		}
		manager->setStreamState(id, "Error: " + errMsg, false);
		return {};
	}

	GstElement* appsinkElem = gst_bin_get_by_name(GST_BIN(pipeline), "sink");
	if (appsinkElem == nullptr) {
		manager->setStreamState(
			id, "Error: pipeline must produce decoded video", false);
		gst_object_unref(pipeline);
		return {};
	}

	return {
		.pipeline = pipeline, .appSink = appsinkElem, .releaseAppSink = true};
}

PipelineSetup createUriPipeline(
	CameraManager* manager, int id, const CameraInfo& camera) {
	GstElement* uridecodebin =
		gst_element_factory_make("uridecodebin", nullptr);
	GstElement* convert = gst_element_factory_make("videoconvert", nullptr);
	GstElement* capsfilter = gst_element_factory_make("capsfilter", nullptr);
	GstElement* appsinkElem = gst_element_factory_make("appsink", "sink");

	if (uridecodebin == nullptr || convert == nullptr ||
		capsfilter == nullptr || appsinkElem == nullptr) {
		qWarning() << "Failed to create GStreamer elements";
		unrefCreatedElements(uridecodebin, convert, capsfilter, appsinkElem);
		manager->setStreamState(id, "Error: failed to create elements", false);
		return {};
	}

	g_object_set(uridecodebin, "uri",
		camera.streamUrl.toString().toUtf8().constData(), "buffer-size",
		static_cast<gint64>(0), "buffer-duration", static_cast<gint64>(0),
		"download", FALSE, "use-buffering", FALSE, nullptr);

	GstCaps* caps = gst_caps_new_simple(
		"video/x-raw", "format", G_TYPE_STRING, "RGBA", nullptr);
	g_object_set(capsfilter, "caps", caps, nullptr);
	gst_caps_unref(caps);

	g_object_set(appsinkElem, "emit-signals", TRUE, "drop", TRUE, "max-buffers",
		1, "sync", FALSE, nullptr);

	GstElement* pipeline = gst_pipeline_new(nullptr);
	gst_bin_add_many(GST_BIN(pipeline), uridecodebin, convert, capsfilter,
		appsinkElem, nullptr);
	gst_element_link_many(convert, capsfilter, appsinkElem, nullptr);

	g_signal_connect(
		uridecodebin, "pad-added", G_CALLBACK(onPadAdded), convert);

	return {.pipeline = pipeline, .appSink = appsinkElem};
}

}  // namespace

CameraManager::CameraManager(QQmlEngine* engine, QObject* parent)
	: QObject(parent), m_engine(engine) {
	qRegisterMetaType<Detection>("Detection");
	qRegisterMetaType<QList<Detection>>("QList<Detection>");
	gst_init(nullptr, nullptr);
}

CameraManager* CameraManager::create(
	QQmlEngine* qmlEngine, QJSEngine* jsEngine) {
	Q_UNUSED(jsEngine);
	// NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
	return new CameraManager(qmlEngine, qmlEngine);
}

CameraManager::~CameraManager() {
	for (auto& [key, value] : m_cameras) {
		stopPipeline(key);
	}
}

int CameraManager::addStream(const QString& name, const QString& url,
	const QString& customPipeline, bool useCustomPipeline) {
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

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void CameraManager::editStream(int id, const QString& name, const QString& url,
	const QString& customPipeline, bool useCustomPipeline) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		qWarning() << "Stream not found:" << id;
		return;
	}

	auto* cam = it->second.get();
	cam->name = name;

	bool needsRestart = false;

	if (useCustomPipeline) {
		if (cam->customPipeline != customPipeline || !cam->useCustomPipeline) {
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

void CameraManager::setStreamState(
	int id, const QString& status, bool connected) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		return;
	}

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
	if (it == m_cameras.end()) {
		return;
	}

	auto* cam = it->second.get();
	if (cam->useCustomPipeline && cam->customPipeline.isEmpty()) {
		return;
	}
	if (!cam->useCustomPipeline && cam->streamUrl.isEmpty()) {
		return;
	}

	PipelineSetup setup = cam->useCustomPipeline
		? createCustomPipeline(this, id, *cam)
		: createUriPipeline(this, id, *cam);
	if (setup.pipeline == nullptr || setup.appSink == nullptr) {
		return;
	}

	// Tag pipeline for bus message routing.
	g_object_set_data(G_OBJECT(setup.pipeline), "agc-stream-id",
		GINT_TO_POINTER(id + 1));  // +1 so 0 = not found

	cam->pipeline = setup.pipeline;

	g_signal_connect(setup.appSink, "new-sample", G_CALLBACK(onNewSample), cam);

	// gst_bin_get_by_name returns an owned ref; release it after connecting signals.
	if (setup.releaseAppSink) {
		gst_object_unref(setup.appSink);
	}

	GstBus* bus = gst_pipeline_get_bus(GST_PIPELINE(setup.pipeline));
	gst_bus_set_sync_handler(bus, onBusMessage, this, nullptr);
	gst_object_unref(bus);

	gst_element_set_state(setup.pipeline, GST_STATE_PLAYING);
	qInfo() << "Pipeline started for:" << cam->name;
}

void CameraManager::stopPipeline(int id) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end()) {
		return;
	}

	auto* cam = it->second.get();
	if (cam->pipeline == nullptr) {
		return;
	}

	gst_element_set_state(cam->pipeline, GST_STATE_NULL);
	gst_object_unref(cam->pipeline);
	cam->pipeline = nullptr;
}

// ai sahi detection stuff
void CameraManager::setDetectionEnabled(int id, bool enabled) {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end())
		return;
	auto* cam = it->second.get();

	if (enabled == cam->detectionEnabled)
		return;
	cam->detectionEnabled = enabled;

	if (enabled) {
		cam->detectionThread = std::make_unique<QThread>();
		cam->detectionWorker = std::make_unique<DetectionWorker>(id);
		cam->detectionWorker->moveToThread(cam->detectionThread.get());

		// Wire results back to CameraManager on the GUI thread
		connect(
			cam->detectionWorker.get(), &DetectionWorker::detectionsReady, this,
			[this](int streamId, QList<Detection> dets) {
				auto it2 = m_cameras.find(streamId);
				if (it2 == m_cameras.end())
					return;
				it2->second->lastDetections = dets;

				QVariantList out;
				for (const auto& d : dets) {
					QVariantMap m;
					m["x"] = d.x;
					m["y"] = d.y;
					m["w"] = d.w;
					m["h"] = d.h;
					m["label"] = d.label;
					m["score"] = d.score;
					out.append(m);
				}
				emit detectionsChanged(streamId, out);
			},
			Qt::QueuedConnection);

		connect(cam->detectionThread.get(), &QThread::started,
			cam->detectionWorker.get(), &DetectionWorker::start);
		connect(
			cam->detectionWorker.get(), &DetectionWorker::alertReady, this,
			[this](int streamId, const QString& alert) {
				emit alertChanged(streamId, alert);
			},
			Qt::QueuedConnection);

		cam->detectionThread->start();
	} else {
		if (cam->detectionWorker)
			cam->detectionWorker->stop();
		if (cam->detectionThread) {
			cam->detectionThread->quit();
			cam->detectionThread->wait();
		}
		cam->detectionWorker.reset();
		cam->detectionThread.reset();
		cam->lastDetections.clear();
		emit detectionsChanged(id, {});
	}
}

QVariantList CameraManager::detections(int id) const {
	auto it = m_cameras.find(id);
	if (it == m_cameras.end())
		return {};
	QVariantList out;
	for (const auto& d : it->second->lastDetections) {
		QVariantMap m;
		m["x"] = d.x;
		m["y"] = d.y;
		m["w"] = d.w;
		m["h"] = d.h;
		m["label"] = d.label;
		m["score"] = d.score;
		out.append(m);
	}
	return out;
}
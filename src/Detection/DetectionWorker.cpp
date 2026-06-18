#include "DetectionWorker.h"

#include <QDebug>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutexLocker>
#include <QProcessEnvironment>

#include <array>
#include <cstring>

#ifndef AGC_DETECTION_SOURCE_DIR
#define AGC_DETECTION_SOURCE_DIR "."
#endif

namespace {
constexpr int kDetectorStartTimeoutMs = 3000;
constexpr int kDetectorStopTimeoutMs = 2000;
constexpr qsizetype kFrameHeaderBytes =
	static_cast<qsizetype>(sizeof(qint32)) * 2;

Detection detectionFromJson(const QJsonObject& object) {
	return {
		.x = static_cast<float>(object.value(QStringLiteral("x")).toDouble()),
		.y = static_cast<float>(object.value(QStringLiteral("y")).toDouble()),
		.w = static_cast<float>(object.value(QStringLiteral("w")).toDouble()),
		.h = static_cast<float>(object.value(QStringLiteral("h")).toDouble()),
		.label = object.value(QStringLiteral("label")).toString(),
		.score = static_cast<float>(
			object.value(QStringLiteral("score")).toDouble())};
}
}  // namespace

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
DetectionWorker::DetectionWorker(
	int streamId, double confidenceThreshold, QObject* parent)
	: QObject(parent),
	  m_streamId(streamId),
	  m_confidenceThreshold(confidenceThreshold) {}

DetectionWorker::~DetectionWorker() {
	stop();
}

void DetectionWorker::start() {
	if (m_process != nullptr) {
		return;
	}

	const QString projectDir = QStringLiteral(AGC_DETECTION_SOURCE_DIR);
	const QString script = projectDir + QStringLiteral("/detector.py");

	// NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
	m_process = new QProcess(this);
	m_process->setProgram(QStringLiteral("uv"));
	m_process->setArguments(
		{QStringLiteral("run"), QStringLiteral("--project"), projectDir,
			QStringLiteral("--no-sync"), QStringLiteral("python"), script});
	m_process->setWorkingDirectory(projectDir);
	QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
	env.insert(QStringLiteral("AGC_DETECTION_CONFIDENCE"),
		QString::number(m_confidenceThreshold, 'f', 2));
	m_process->setProcessEnvironment(env);
	m_process->setProcessChannelMode(QProcess::SeparateChannels);

	connect(m_process, &QProcess::readyReadStandardError, this, [this]() {
		qWarning() << "Detector stderr [stream" << m_streamId
				   << "]:" << m_process->readAllStandardError();
	});
	connect(m_process, &QProcess::readyReadStandardOutput, this,
		&DetectionWorker::onReadyRead);
	connect(m_process, &QProcess::errorOccurred, this,
		&DetectionWorker::onProcessError);

	m_process->start();
	if (!m_process->waitForStarted(kDetectorStartTimeoutMs)) {
		qWarning() << "Detector failed to start for stream" << m_streamId;
		qWarning() << "  uv executable must be available on PATH";
		qWarning() << "  project:" << projectDir;
		qWarning() << "  script :" << script;
		qWarning() << "  exists :" << QFileInfo(script).exists();
	} else {
		qInfo() << "Detector started for stream" << m_streamId;
	}
}

void DetectionWorker::stop() {
	if (m_process == nullptr || m_process->state() == QProcess::NotRunning) {
		return;
	}

	m_process->terminate();
	m_process->waitForFinished(kDetectorStopTimeoutMs);
}

void DetectionWorker::submitFrame(const QByteArray& bgrData, QSize frameSize) {
	bool shouldSend = false;
	{
		QMutexLocker lock(&m_frameMutex);
		m_pendingFrame = bgrData;
		m_pendingSize = frameSize;
		m_hasPending = true;
		shouldSend = !m_busy;
	}

	if (shouldSend) {
		QMetaObject::invokeMethod(
			this, &DetectionWorker::sendPendingFrame, Qt::QueuedConnection);
	}
}

void DetectionWorker::writeFrame(const QByteArray& data, QSize frameSize) {
	if (m_process == nullptr || m_process->state() != QProcess::Running) {
		QMutexLocker lock(&m_frameMutex);
		m_busy = false;
		return;
	}

	const qint32 frameWidth = frameSize.width();
	const qint32 frameHeight = frameSize.height();
	std::array<char, kFrameHeaderBytes> header{};
	std::memcpy(header.data(), &frameWidth, sizeof(frameWidth));
	std::memcpy(
		header.data() + sizeof(frameWidth), &frameHeight, sizeof(frameHeight));
	m_process->write(header.data(), header.size());
	m_process->write(data);
}

void DetectionWorker::sendPendingFrame() {
	QByteArray data;
	QSize frameSize;

	{
		QMutexLocker lock(&m_frameMutex);
		if (!m_hasPending || m_busy) {
			return;
		}
		data = std::move(m_pendingFrame);
		frameSize = m_pendingSize;
		m_hasPending = false;
		m_busy = true;
	}

	writeFrame(data, frameSize);
}

void DetectionWorker::onReadyRead() {
	while (m_process->canReadLine()) {
		const QByteArray line = m_process->readLine().trimmed();
		if (line.isEmpty()) {
			continue;
		}

		QJsonParseError err;
		const QJsonDocument doc = QJsonDocument::fromJson(line, &err);
		if (err.error != QJsonParseError::NoError || !doc.isObject()) {
			qWarning() << "Bad detection JSON:" << err.errorString();
			{
				QMutexLocker lock(&m_frameMutex);
				m_busy = false;
			}
			sendPendingFrame();
			continue;
		}

		const QJsonObject root = doc.object();
		const QJsonArray boxes = root.value(QStringLiteral("boxes")).toArray();

		QList<Detection> detections;
		detections.reserve(boxes.size());
		for (const auto box : boxes) {
			detections.append(detectionFromJson(box.toObject()));
		}
		emit detectionsReady(m_streamId, detections);

		const QString alert =
			root.value(QStringLiteral("alert")).toString().trimmed();
		if (!alert.isEmpty()) {
			emit alertReady(m_streamId, alert);
		}

		{
			QMutexLocker lock(&m_frameMutex);
			m_busy = false;
		}
		sendPendingFrame();
	}
}

void DetectionWorker::onProcessError(QProcess::ProcessError error) {
	qWarning() << "Detector process error for stream" << m_streamId << ":"
			   << error;
	QMutexLocker lock(&m_frameMutex);
	m_busy = false;
}

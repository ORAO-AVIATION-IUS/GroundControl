#include "DetectionWorker.h"

#include <QCoreApplication>
#include <QDebug>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutexLocker>

#include <cstring>

DetectionWorker::DetectionWorker(int streamId, QObject* parent)
	: QObject(parent), m_streamId(streamId) {}

DetectionWorker::~DetectionWorker() {
	stop();
}

void DetectionWorker::start() {
	m_process = new QProcess(this);

	const QString buildDir =
		QCoreApplication::applicationDirPath();	   // .../build
	const QString projectRoot = buildDir + "/..";  // .../GroundControl

	const QString python = projectRoot + "/.venv/bin/python3";
	const QString script = buildDir + "/detector.py";

	m_process->setProgram(python);
	m_process->setArguments({script});

	QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
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
	// qWarning does not seem to write to stdout; investigate if needed.
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

void DetectionWorker::submitFrame(
	const QByteArray& bgrData, int width, int height) {
	QMutexLocker lock(&m_frameMutex);
	m_pendingFrame = bgrData;
	m_pendingW = width;
	m_pendingH = height;
	m_hasPending = true;

	if (!m_busy) {
		QMetaObject::invokeMethod(
			this,
			[this]() {
				QMutexLocker l(&m_frameMutex);
				if (!m_hasPending) {
					return;
				}
				QByteArray data = std::move(m_pendingFrame);
				int w = m_pendingW;
				int h = m_pendingH;
				m_hasPending = false;
				m_busy = true;
				l.unlock();
				writeFrame(data, w, h);
			},
			Qt::QueuedConnection);
	}
}

void DetectionWorker::writeFrame(const QByteArray& data, int w, int h) {
	if (!m_process || m_process->state() != QProcess::Running) {
		m_busy = false;
		return;
	}

	char header[8];
	std::memcpy(header, &w, 4);
	std::memcpy(header + 4, &h, 4);
	m_process->write(header, 8);
	m_process->write(data);
}

void DetectionWorker::onReadyRead() {
	while (m_process->canReadLine()) {
		QByteArray line = m_process->readLine().trimmed();
		if (line.isEmpty()) {
			continue;
		}

		QJsonParseError err;
		QJsonDocument doc = QJsonDocument::fromJson(line, &err);
		if (err.error != QJsonParseError::NoError || !doc.isObject()) {
			qWarning() << "Bad detection JSON:" << err.errorString();
			m_busy = false;
			continue;
		}

		QJsonObject root = doc.object();

		QList<Detection> detections;
		for (const QJsonValue& v : root["boxes"].toArray()) {
			QJsonObject o = v.toObject();
			detections.append({.x = static_cast<float>(o["x"].toDouble()),
				.y = static_cast<float>(o["y"].toDouble()),
				.w = static_cast<float>(o["w"].toDouble()),
				.h = static_cast<float>(o["h"].toDouble()),
				.label = o["label"].toString(),
				.score = static_cast<float>(o["score"].toDouble())});
		}
		emit detectionsReady(m_streamId, detections);

		QString alert = root["alert"].toString().trimmed();
		if (!alert.isEmpty()) {
			emit alertReady(m_streamId, alert);
		}

		m_busy = false;

		QMutexLocker l(&m_frameMutex);
		if (m_hasPending) {
			QByteArray data = std::move(m_pendingFrame);
			int w = m_pendingW;
			int h = m_pendingH;
			m_hasPending = false;
			m_busy = true;
			l.unlock();
			writeFrame(data, w, h);
		}
	}
}

void DetectionWorker::onProcessError(QProcess::ProcessError error) {
	qWarning() << "Detector process error for stream" << m_streamId << ":"
			   << error;
	m_busy = false;
}

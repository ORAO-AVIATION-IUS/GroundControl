#include "LogManager.h"

#include "LogFileWriter.h"
#include "LogModel.h"
#include "QtLogBridge.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QMutexLocker>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QThread>

namespace agc {

LogManager& LogManager::instance() {
	static LogManager s;
	return s;
}

LogManager* LogManager::create(QQmlEngine*, QJSEngine*) {
	auto* self = &instance();
	QQmlEngine::setObjectOwnership(self, QQmlEngine::CppOwnership);
	return self;
}

LogManager::LogManager() : QObject(nullptr) {
	qRegisterMetaType<agc::LogEntry>("agc::LogEntry");
	m_model = new LogModel(this);
}

LogManager::~LogManager() {
	if (m_writerThread) {
		m_writerThread->quit();
		m_writerThread->wait();
	}
}

void LogManager::bootstrap(const QString& logDir) {
	if (m_bootstrapped) return;
	m_bootstrapped = true;

	QString dir = logDir;
	if (dir.isEmpty()) {
		dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
		if (dir.isEmpty()) dir = QDir::tempPath();
		dir += QStringLiteral("/logs");
	}
	QDir().mkpath(dir);

	m_writer = new LogFileWriter(dir);
	m_writerThread = new QThread(this);
	m_writer->moveToThread(m_writerThread);
	connect(m_writerThread, &QThread::finished, m_writer, &QObject::deleteLater);
	connect(this, &LogManager::sourceDiscovered,
	        m_writer, &LogFileWriter::openSource,
	        Qt::QueuedConnection);
	m_writerThread->start();

	QtLogBridge::install();
}

QAbstractItemModel* LogManager::modelAsAbstract() const {
	return m_model;
}

QStringList LogManager::sources() const {
	QMutexLocker lock(&m_srcMutex);
	return m_sources;
}

void LogManager::post(LogEntry entry) {
	bool isNew = false;
	{
		QMutexLocker lock(&m_srcMutex);
		if (!m_sources.contains(entry.source)) {
			m_sources.append(entry.source);
			isNew = true;
		}
	}
	if (isNew) {
		emit sourceDiscovered(entry.source);
		emit sourcesChanged();
	}

	QMetaObject::invokeMethod(m_model, "append",
		Qt::QueuedConnection, Q_ARG(agc::LogEntry, entry));

	if (m_writer) {
		QMetaObject::invokeMethod(m_writer, "write",
			Qt::QueuedConnection, Q_ARG(agc::LogEntry, entry));
	}
}

void LogManager::emitLog(const QString& source, int level, const QString& message) {
	LogEntry e;
	e.timestampMs = QDateTime::currentMSecsSinceEpoch();
	e.level       = static_cast<LogLevel>(qBound(0, level, 4));
	e.source      = source;
	e.message     = message;
	e.threadId    = reinterpret_cast<quintptr>(QThread::currentThreadId());
	post(std::move(e));
}

void LogManager::clear() {
	QMetaObject::invokeMethod(m_model, "clear", Qt::QueuedConnection);
}

} // namespace agc

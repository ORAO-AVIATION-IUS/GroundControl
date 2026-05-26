#pragma once

#include "LogEntry.h"
#include "LogManager.h"

#include <QDateTime>
#include <QString>
#include <QThread>

namespace agc {

class LogSource {
public:
	explicit LogSource(QString name) : m_name(std::move(name)) {}

	const QString& name() const { return m_name; }

	void debug   (const QString& m) const { emit_(LogLevel::Debug,    m); }
	void info    (const QString& m) const { emit_(LogLevel::Info,     m); }
	void warning (const QString& m) const { emit_(LogLevel::Warning,  m); }
	void error   (const QString& m) const { emit_(LogLevel::Error,    m); }
	void critical(const QString& m) const { emit_(LogLevel::Critical, m); }

private:
	void emit_(LogLevel lvl, const QString& msg) const {
		LogEntry e;
		e.timestampMs = QDateTime::currentMSecsSinceEpoch();
		e.level       = lvl;
		e.source      = m_name;
		e.message     = msg;
		e.threadId    = reinterpret_cast<quintptr>(QThread::currentThreadId());
		LogManager::instance().post(std::move(e));
	}

	QString m_name;
};

} // namespace agc

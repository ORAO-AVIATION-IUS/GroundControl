#pragma once

#include <QMetaType>
#include <QString>
#include <QtGlobal>

namespace agc {

enum class LogLevel : quint8 {
	Debug    = 0,
	Info     = 1,
	Warning  = 2,
	Error    = 3,
	Critical = 4,
};

struct LogEntry {
	qint64   timestampMs = 0;
	LogLevel level       = LogLevel::Info;
	QString  source;
	QString  message;
	quintptr threadId    = 0;
};

const char* levelName(LogLevel l);

} // namespace agc

Q_DECLARE_METATYPE(agc::LogEntry)

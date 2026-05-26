#include "QtLogBridge.h"

#include "LogEntry.h"
#include "LogManager.h"

#include <QDateTime>
#include <QString>
#include <QThread>
#include <QtGlobal>

namespace agc {

namespace {

QtMessageHandler g_previous = nullptr;

LogLevel toLevel(QtMsgType t) {
	switch (t) {
		case QtDebugMsg:    return LogLevel::Debug;
		case QtInfoMsg:     return LogLevel::Info;
		case QtWarningMsg:  return LogLevel::Warning;
		case QtCriticalMsg: return LogLevel::Error;
		case QtFatalMsg:    return LogLevel::Critical;
	}
	return LogLevel::Info;
}

bool shouldSuppress(QtMsgType type, const QString& message) {
	if (type != QtWarningMsg) return false;
	if (message.contains(QStringLiteral("QTimer::start: interval exceeds maximum")))
		return true;
	return false;
}

void handler(QtMsgType type, const QMessageLogContext& ctx, const QString& msg) {
	if (shouldSuppress(type, msg)) return;

	LogEntry e;
	e.timestampMs = QDateTime::currentMSecsSinceEpoch();
	e.level       = toLevel(type);
	e.source      = (ctx.category && *ctx.category)
	                  ? QString::fromLatin1(ctx.category)
	                  : QStringLiteral("qt");
	e.message     = msg;
	e.threadId    = reinterpret_cast<quintptr>(QThread::currentThreadId());
	LogManager::instance().post(std::move(e));

	if (g_previous) g_previous(type, ctx, msg);
}

} // namespace

void QtLogBridge::install() {
	static bool installed = false;
	if (installed) return;
	installed = true;
	g_previous = qInstallMessageHandler(handler);
}

} // namespace agc

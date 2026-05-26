#include "LogFileWriter.h"

#include <QDateTime>
#include <QDir>

namespace agc {

namespace {
constexpr int kFlushEvery = 32;

QString sanitize(const QString& source) {
	QString s = source;
	for (QChar& c : s) {
		if (!c.isLetterOrNumber() && c != QChar('-') && c != QChar('_'))
			c = QChar('_');
	}
	if (s.isEmpty()) s = QStringLiteral("unknown");
	return s;
}
} // namespace

LogFileWriter::LogFileWriter(QString dir, QObject* parent)
	: QObject(parent), m_dir(std::move(dir)) {
	QDir().mkpath(m_dir);
	m_allFile = std::make_unique<QFile>(m_dir + QStringLiteral("/_all.log"));
	if (m_allFile->open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
		m_allStream = std::make_unique<QTextStream>(m_allFile.get());
	}
}

LogFileWriter::~LogFileWriter() {
	flushAll();
}

QString LogFileWriter::formatLine(const LogEntry& e) {
	return QStringLiteral("%1 [%2] [%3] %4\n")
		.arg(QDateTime::fromMSecsSinceEpoch(e.timestampMs)
		         .toString(Qt::ISODateWithMs),
		     QString::fromLatin1(levelName(e.level)).leftJustified(8),
		     e.source,
		     e.message);
}

LogFileWriter::Sink* LogFileWriter::sinkFor(const QString& source) {
	auto it = m_sinks.find(source);
	if (it != m_sinks.end()) return &it->second;

	Sink sink;
	sink.file = std::make_unique<QFile>(m_dir + QStringLiteral("/") + sanitize(source) + QStringLiteral(".log"));
	if (!sink.file->open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
		return nullptr;
	sink.stream = std::make_unique<QTextStream>(sink.file.get());
	auto [iter, ok] = m_sinks.emplace(source, std::move(sink));
	return &iter->second;
}

void LogFileWriter::openSource(const QString& source) {
	sinkFor(source);
}

void LogFileWriter::write(const LogEntry& entry) {
	const QString line = formatLine(entry);
	if (auto* s = sinkFor(entry.source)) {
		*s->stream << line;
	}
	if (m_allStream) {
		*m_allStream << line;
	}
	if (++m_writesSinceFlush >= kFlushEvery) {
		flushAll();
		m_writesSinceFlush = 0;
	}
}

void LogFileWriter::flushAll() {
	for (auto& kv : m_sinks) {
		if (kv.second.stream) kv.second.stream->flush();
	}
	if (m_allStream) m_allStream->flush();
}

} // namespace agc

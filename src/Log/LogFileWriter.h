#pragma once

#include "LogEntry.h"

#include <QFile>
#include <QObject>
#include <QString>
#include <QTextStream>
#include <map>
#include <memory>

namespace agc {

class LogFileWriter : public QObject {
	Q_OBJECT
public:
	explicit LogFileWriter(QString dir, QObject* parent = nullptr);
	~LogFileWriter() override;

public slots:
	void openSource(const QString& source);
	void write(const agc::LogEntry& entry);
	void flushAll();

private:
	struct Sink {
		std::unique_ptr<QFile>       file;
		std::unique_ptr<QTextStream> stream;
	};

	Sink* sinkFor(const QString& source);
	static QString formatLine(const LogEntry& e);

	QString                    m_dir;
	std::map<QString, Sink>    m_sinks;
	std::unique_ptr<QFile>       m_allFile;
	std::unique_ptr<QTextStream> m_allStream;
	int                    m_writesSinceFlush = 0;
};

} // namespace agc

#pragma once

#include "LogEntry.h"

#include <QAbstractItemModel>
#include <QMutex>
#include <QObject>
#include <QStringList>
#include <qqmlintegration.h>

class QQmlEngine;
class QJSEngine;
class QThread;

namespace agc {

class LogModel;
class LogFileWriter;

class LogManager : public QObject {
	Q_OBJECT
	QML_NAMED_ELEMENT(LogManager)
	QML_SINGLETON

	Q_PROPERTY(QAbstractItemModel* model READ modelAsAbstract CONSTANT)
	Q_PROPERTY(QStringList sources READ sources NOTIFY sourcesChanged)

public:
	static LogManager& instance();
	static LogManager* create(QQmlEngine*, QJSEngine*);

	void bootstrap(const QString& logDir = {});

	LogModel*           model() const { return m_model; }
	QAbstractItemModel* modelAsAbstract() const;
	QStringList         sources() const;

	void post(LogEntry entry);

	Q_INVOKABLE void clear();
	Q_INVOKABLE QStringList knownSources() const { return sources(); }
	Q_INVOKABLE void emitLog(const QString& source, int level, const QString& message);

signals:
	void sourcesChanged();
	void sourceDiscovered(const QString& source);

private:
	LogManager();
	~LogManager() override;

	LogModel*       m_model     = nullptr;
	LogFileWriter*  m_writer    = nullptr;
	QThread*        m_writerThread = nullptr;

	mutable QMutex  m_srcMutex;
	QStringList     m_sources;

	bool            m_bootstrapped = false;
};

} // namespace agc

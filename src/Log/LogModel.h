#pragma once

#include "LogEntry.h"

#include <QAbstractListModel>
#include <deque>

namespace agc {

class LogModel : public QAbstractListModel {
	Q_OBJECT
public:
	enum Roles {
		TimestampMsRole = Qt::UserRole + 1,
		TimestampRole,    // pre-formatted "HH:mm:ss.zzz"
		LevelRole,        // int (LogLevel)
		LevelNameRole,    // "Info", "Warning", ...
		SourceRole,
		MessageRole,
		ThreadRole,
	};

	explicit LogModel(QObject* parent = nullptr, int capacity = 50'000);

	int rowCount(const QModelIndex& parent = {}) const override;
	QVariant data(const QModelIndex& index, int role) const override;
	QHash<int, QByteArray> roleNames() const override;

	int capacity() const { return m_capacity; }

public slots:
	void append(const agc::LogEntry& e);
	void clear();

private:
	int                  m_capacity;
	std::deque<LogEntry> m_buf;
};

} // namespace agc

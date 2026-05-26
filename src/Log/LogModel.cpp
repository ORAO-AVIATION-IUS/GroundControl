#include "LogModel.h"

#include <QDateTime>

namespace agc {

LogModel::LogModel(QObject* parent, int capacity)
	: QAbstractListModel(parent), m_capacity(capacity) {}

int LogModel::rowCount(const QModelIndex& parent) const {
	if (parent.isValid()) return 0;
	return int(m_buf.size());
}

QVariant LogModel::data(const QModelIndex& index, int role) const {
	if (!index.isValid()) return {};
	const int row = index.row();
	if (row < 0 || row >= int(m_buf.size())) return {};
	const LogEntry& e = m_buf[row];
	switch (role) {
		case TimestampMsRole: return QVariant::fromValue(e.timestampMs);
		case TimestampRole:   return QDateTime::fromMSecsSinceEpoch(e.timestampMs)
		                              .toString(QStringLiteral("HH:mm:ss.zzz"));
		case LevelRole:       return int(e.level);
		case LevelNameRole:   return QString::fromLatin1(levelName(e.level));
		case SourceRole:      return e.source;
		case MessageRole:     return e.message;
		case ThreadRole:      return QVariant::fromValue<qulonglong>(e.threadId);
		default:              return {};
	}
}

QHash<int, QByteArray> LogModel::roleNames() const {
	return {
		{ TimestampMsRole, "timestampMs" },
		{ TimestampRole,   "timestamp"   },
		{ LevelRole,       "level"       },
		{ LevelNameRole,   "levelName"   },
		{ SourceRole,      "source"      },
		{ MessageRole,     "message"     },
		{ ThreadRole,      "threadId"    },
	};
}

void LogModel::append(const LogEntry& e) {
	const bool willTrim = int(m_buf.size()) >= m_capacity;
	if (willTrim) {
		beginRemoveRows({}, 0, 0);
		m_buf.pop_front();
		endRemoveRows();
	}
	const int row = int(m_buf.size());
	beginInsertRows({}, row, row);
	m_buf.push_back(e);
	endInsertRows();
}

void LogModel::clear() {
	if (m_buf.empty()) return;
	beginResetModel();
	m_buf.clear();
	endResetModel();
}

} // namespace agc

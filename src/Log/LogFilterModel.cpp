#include "LogFilterModel.h"

#include "LogModel.h"

namespace agc {

LogFilterModel::LogFilterModel(QObject* parent)
	: QSortFilterProxyModel(parent) {
	setDynamicSortFilter(true);
}

void LogFilterModel::setSourceFilter(const QStringList& v) {
	if (m_sources == v) return;
	m_sources = v;
	invalidateFilter();
	emit filterChanged();
}

void LogFilterModel::setMinLevel(int v) {
	if (m_minLevel == v) return;
	m_minLevel = v;
	invalidateFilter();
	emit filterChanged();
}

void LogFilterModel::setSearch(const QString& v) {
	if (m_search == v) return;
	m_search = v;
	invalidateFilter();
	emit filterChanged();
}

bool LogFilterModel::filterAcceptsRow(int row, const QModelIndex& parent) const {
	const auto* src = sourceModel();
	if (!src) return false;
	const QModelIndex idx = src->index(row, 0, parent);

	const int lvl = src->data(idx, LogModel::LevelRole).toInt();
	if (lvl < m_minLevel) return false;

	if (!m_sources.isEmpty()) {
		const QString s = src->data(idx, LogModel::SourceRole).toString();
		if (!m_sources.contains(s)) return false;
	}

	if (!m_search.isEmpty()) {
		const QString msg = src->data(idx, LogModel::MessageRole).toString();
		const QString s   = src->data(idx, LogModel::SourceRole).toString();
		if (!msg.contains(m_search, Qt::CaseInsensitive)
		 && !s.contains(m_search, Qt::CaseInsensitive))
			return false;
	}
	return true;
}

} // namespace agc

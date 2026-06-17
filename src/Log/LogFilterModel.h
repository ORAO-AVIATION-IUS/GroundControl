#pragma once

#include <QSortFilterProxyModel>
#include <QStringList>
#include <qqmlintegration.h>

namespace agc {

class LogFilterModel : public QSortFilterProxyModel {
	Q_OBJECT
	QML_NAMED_ELEMENT(LogFilterModel)

	Q_PROPERTY(QStringList sourceFilter READ sourceFilter WRITE setSourceFilter NOTIFY filterChanged)
	Q_PROPERTY(int         minLevel     READ minLevel     WRITE setMinLevel     NOTIFY filterChanged)
	Q_PROPERTY(QString     search       READ search       WRITE setSearch       NOTIFY filterChanged)

public:
	explicit LogFilterModel(QObject* parent = nullptr);

	QStringList sourceFilter() const { return m_sources; }
	void setSourceFilter(const QStringList& v);

	int  minLevel() const { return m_minLevel; }
	void setMinLevel(int v);

	QString search() const { return m_search; }
	void setSearch(const QString& v);

signals:
	void filterChanged();

protected:
	bool filterAcceptsRow(int row, const QModelIndex& parent) const override;

private:
	QStringList m_sources;
	int         m_minLevel = 0;
	QString     m_search;
};

} // namespace agc

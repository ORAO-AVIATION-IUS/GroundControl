#pragma once

#include <qqmlintegration.h>
#include <QObject>
#include <QString>
#include <QVariantMap>

class GuidedTargetModel : public QObject {
	Q_OBJECT
	QML_ELEMENT

	Q_PROPERTY(bool goTargetValid READ goTargetValid NOTIFY targetsChanged)
	Q_PROPERTY(
		double goTargetLatitude READ goTargetLatitude NOTIFY targetsChanged)
	Q_PROPERTY(
		double goTargetLongitude READ goTargetLongitude NOTIFY targetsChanged)
	Q_PROPERTY(double goTargetAltitude READ goTargetAltitude WRITE
			setGoTargetAltitude NOTIFY targetsChanged)
	Q_PROPERTY(double goTargetHeading READ goTargetHeading WRITE
			setGoTargetHeading NOTIFY targetsChanged)
	Q_PROPERTY(bool lookTargetValid READ lookTargetValid NOTIFY targetsChanged)
	Q_PROPERTY(
		double lookTargetLatitude READ lookTargetLatitude NOTIFY targetsChanged)
	Q_PROPERTY(double lookTargetLongitude READ lookTargetLongitude NOTIFY
			targetsChanged)
	Q_PROPERTY(double lookTargetHeading READ lookTargetHeading WRITE
			setLookTargetHeading NOTIFY targetsChanged)
	Q_PROPERTY(bool localHomeValid READ localHomeValid NOTIFY targetsChanged)
	Q_PROPERTY(
		double localHomeLatitude READ localHomeLatitude NOTIFY targetsChanged)
	Q_PROPERTY(
		double localHomeLongitude READ localHomeLongitude NOTIFY targetsChanged)
	Q_PROPERTY(
		double localHomeAltitude READ localHomeAltitude NOTIFY targetsChanged)
	Q_PROPERTY(bool flyPromptOpen READ flyPromptOpen WRITE setFlyPromptOpen
			NOTIFY promptChanged)
	Q_PROPERTY(QString flyPromptKind READ flyPromptKind WRITE setFlyPromptKind
			NOTIFY promptChanged)
	Q_PROPERTY(bool mapContextOpen READ mapContextOpen WRITE setMapContextOpen
			NOTIFY contextChanged)
	Q_PROPERTY(
		double mapContextLatitude READ mapContextLatitude NOTIFY contextChanged)
	Q_PROPERTY(double mapContextLongitude READ mapContextLongitude NOTIFY
			contextChanged)
	Q_PROPERTY(double mapContextX READ mapContextX NOTIFY contextChanged)
	Q_PROPERTY(double mapContextY READ mapContextY NOTIFY contextChanged)
	Q_PROPERTY(bool snapshotValid READ snapshotValid NOTIFY snapshotChanged)

   public:
	explicit GuidedTargetModel(QObject* parent = nullptr);

	[[nodiscard]] bool goTargetValid() const;
	[[nodiscard]] double goTargetLatitude() const;
	[[nodiscard]] double goTargetLongitude() const;
	[[nodiscard]] double goTargetAltitude() const;
	void setGoTargetAltitude(double altitude);
	[[nodiscard]] double goTargetHeading() const;
	void setGoTargetHeading(double heading);

	[[nodiscard]] bool lookTargetValid() const;
	[[nodiscard]] double lookTargetLatitude() const;
	[[nodiscard]] double lookTargetLongitude() const;
	[[nodiscard]] double lookTargetHeading() const;
	void setLookTargetHeading(double heading);

	[[nodiscard]] bool localHomeValid() const;
	[[nodiscard]] double localHomeLatitude() const;
	[[nodiscard]] double localHomeLongitude() const;
	[[nodiscard]] double localHomeAltitude() const;

	[[nodiscard]] bool flyPromptOpen() const;
	void setFlyPromptOpen(bool open);
	[[nodiscard]] QString flyPromptKind() const;
	void setFlyPromptKind(const QString& kind);

	[[nodiscard]] bool mapContextOpen() const;
	void setMapContextOpen(bool open);
	[[nodiscard]] double mapContextLatitude() const;
	[[nodiscard]] double mapContextLongitude() const;
	[[nodiscard]] double mapContextX() const;
	[[nodiscard]] double mapContextY() const;
	[[nodiscard]] bool snapshotValid() const;

	Q_INVOKABLE void setGoTarget(
		double latitude, double longitude, double altitude, double heading);
	Q_INVOKABLE void setLookTarget(
		double latitude, double longitude, double heading);
	Q_INVOKABLE void setLocalHome(
		double latitude, double longitude, double altitude);
	Q_INVOKABLE void clearTarget(const QString& kind);
	Q_INVOKABLE void setMapContext(
		double latitude, double longitude, double x, double y);
	Q_INVOKABLE void closeMapContext();
	Q_INVOKABLE void openPrompt(const QString& kind);
	Q_INVOKABLE void closePrompt();
	Q_INVOKABLE void snapshotTarget(const QString& kind);
	Q_INVOKABLE void restoreSnapshot();
	Q_INVOKABLE void clearSnapshot();

   signals:
	void targetsChanged();
	void promptChanged();
	void contextChanged();
	void snapshotChanged();

   private:
	struct TargetSnapshot {
		QString kind;
		bool valid{false};
		double latitude{0.0};
		double longitude{0.0};
		double altitude{0.0};
		double heading{0.0};
	};

	[[nodiscard]] static double normalizeHeading(double heading);
	void emitPromptIfChanged(bool oldOpen, const QString& oldKind);

	bool m_goTargetValid{false};
	double m_goTargetLatitude{0.0};
	double m_goTargetLongitude{0.0};
	double m_goTargetAltitude{0.0};
	double m_goTargetHeading{0.0};

	bool m_lookTargetValid{false};
	double m_lookTargetLatitude{0.0};
	double m_lookTargetLongitude{0.0};
	double m_lookTargetHeading{0.0};

	bool m_localHomeValid{false};
	double m_localHomeLatitude{0.0};
	double m_localHomeLongitude{0.0};
	double m_localHomeAltitude{0.0};

	bool m_flyPromptOpen{false};
	QString m_flyPromptKind;

	bool m_mapContextOpen{false};
	double m_mapContextLatitude{0.0};
	double m_mapContextLongitude{0.0};
	double m_mapContextX{0.0};
	double m_mapContextY{0.0};

	TargetSnapshot m_snapshot;
	bool m_snapshotValid{false};
};

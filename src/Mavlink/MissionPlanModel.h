#pragma once

#include <qqmlintegration.h>
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class MissionPlanModel : public QObject {
	Q_OBJECT
	QML_ELEMENT

	Q_PROPERTY(QVariantList items READ items WRITE setItems NOTIFY itemsChanged)
	Q_PROPERTY(int selectedIndex READ selectedIndex WRITE setSelectedIndex
			NOTIFY selectedIndexChanged)
	Q_PROPERTY(bool returnHomeAfterMission READ returnHomeAfterMission WRITE
			setReturnHomeAfterMission NOTIFY returnHomeAfterMissionChanged)
	Q_PROPERTY(bool landAfterMission READ landAfterMission WRITE
			setLandAfterMission NOTIFY landAfterMissionChanged)
	Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)
	Q_PROPERTY(QString signature READ signature NOTIFY signatureChanged)
	Q_PROPERTY(double distanceMeters READ distanceMeters NOTIFY distanceChanged)
	Q_PROPERTY(double defaultAltitude READ defaultAltitude WRITE
			setDefaultAltitude NOTIFY defaultAltitudeChanged)
	Q_PROPERTY(double defaultSpeed READ defaultSpeed WRITE setDefaultSpeed
			NOTIFY defaultSpeedChanged)

   public:
	explicit MissionPlanModel(QObject* parent = nullptr);

	[[nodiscard]] QVariantList items() const;
	void setItems(const QVariantList& items);

	[[nodiscard]] int selectedIndex() const;
	void setSelectedIndex(int index);

	[[nodiscard]] bool returnHomeAfterMission() const;
	void setReturnHomeAfterMission(bool enabled);

	[[nodiscard]] bool landAfterMission() const;
	void setLandAfterMission(bool enabled);

	[[nodiscard]] int revision() const;
	[[nodiscard]] QString signature() const;
	[[nodiscard]] double distanceMeters() const;

	[[nodiscard]] double defaultAltitude() const;
	void setDefaultAltitude(double altitudeMeters);

	[[nodiscard]] double defaultSpeed() const;
	void setDefaultSpeed(double speedMetersPerSecond);

	[[nodiscard]] Q_INVOKABLE QVariant selectedItem() const;
	Q_INVOKABLE void addWaypoint(double latitude, double longitude);
	Q_INVOKABLE void insertWaypointAtSegment(
		int segmentIndex, double latitude, double longitude);
	Q_INVOKABLE void moveWaypoint(
		int index, double latitude, double longitude);	// NOLINT
	Q_INVOKABLE void removeSelectedWaypoint();
	Q_INVOKABLE void clear();
	Q_INVOKABLE void setSelectedField(
		const QString& fieldName, double value, double minimumValue);
	Q_INVOKABLE void setSelectedOptionEnabled(
		const QString& fieldName, bool enabled);
	Q_INVOKABLE void setSelectedFlyThrough(bool flyThrough);
	Q_INVOKABLE void setSelectedCommand(const QString& command);
	[[nodiscard]] Q_INVOKABLE QString validateForUpload() const;
	[[nodiscard]] Q_INVOKABLE QString distanceText() const;

   signals:
	void itemsChanged();
	void selectedIndexChanged();
	void returnHomeAfterMissionChanged();
	void landAfterMissionChanged();
	void revisionChanged();
	void signatureChanged();
	void distanceChanged();
	void defaultAltitudeChanged();
	void defaultSpeedChanged();

   private:
	[[nodiscard]] static QVariantMap waypointFromCoordinate(
		double latitude, double longitude, double altitude, double speed);
	[[nodiscard]] double appendAltitude() const;
	[[nodiscard]] double appendSpeed() const;
	[[nodiscard]] double segmentAltitude(int segmentIndex) const;
	[[nodiscard]] double segmentSpeed(int segmentIndex) const;
	void replaceSelectedItem(const QVariantMap& update);
	void markEdited();
	void emitPlanChanged();
	void clampSelectedIndex();

	QVariantList m_items;
	int m_selectedIndex{-1};
	bool m_returnHomeAfterMission{false};
	bool m_landAfterMission{false};
	int m_revision{0};
	double m_defaultAltitude;
	double m_defaultSpeed;
};

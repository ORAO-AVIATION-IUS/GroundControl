#include "MissionPlanModel.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtMath>

namespace {
constexpr double kDefaultMissionAltitudeMeters = 50.0;
constexpr double kDefaultMissionSpeedMetersPerSecond = 8.0;
constexpr double kMinimumAltitudeMeters = 5.0;
constexpr double kMinimumSpeedMetersPerSecond = 0.5;
constexpr double kMinimumAcceptanceRadiusMeters = 0.5;
constexpr double kEarthRadiusMeters = 6371000.0;
constexpr double kDegreesCircle = 360.0;
constexpr double kMetersPerKilometer = 1000.0;
constexpr double kDiameterMultiplier = 2.0;
constexpr double kHalf = 0.5;
constexpr int kLatitudeMaxDegrees = 90;
constexpr int kLongitudeMaxDegrees = 180;
constexpr int kRequiredUploadWaypoints = 2;

[[nodiscard]] double valueFromItem(
	const QVariant& item, const QString& key, double fallback) {
	const QVariantMap map = item.toMap();
	const QVariant value = map.value(key);
	return value.isValid() ? value.toDouble() : fallback;
}

[[nodiscard]] double distanceMeters(const QVariant& from, const QVariant& to) {
	const double lat1 = qDegreesToRadians(valueFromItem(from, "latitude", 0.0));
	const double lon1 =
		qDegreesToRadians(valueFromItem(from, "longitude", 0.0));
	const double lat2 = qDegreesToRadians(valueFromItem(to, "latitude", 0.0));
	const double lon2 = qDegreesToRadians(valueFromItem(to, "longitude", 0.0));
	const double dlat = lat2 - lat1;
	const double dlon = lon2 - lon1;
	const double sinLat = qSin(dlat * kHalf);
	const double sinLon = qSin(dlon * kHalf);
	const double a =
		(sinLat * sinLat) + (qCos(lat1) * qCos(lat2) * sinLon * sinLon);
	return kEarthRadiusMeters * kDiameterMultiplier *
		qAtan2(qSqrt(a), qSqrt(1.0 - a));
}

[[nodiscard]] double normalizeHeading(double heading) {
	return std::fmod(
		std::fmod(heading, kDegreesCircle) + kDegreesCircle, kDegreesCircle);
}
}  // namespace

MissionPlanModel::MissionPlanModel(QObject* parent)
	: QObject(parent),
	  m_defaultAltitude(kDefaultMissionAltitudeMeters),
	  m_defaultSpeed(kDefaultMissionSpeedMetersPerSecond) {}

QVariantList MissionPlanModel::items() const {
	return m_items;
}

void MissionPlanModel::setItems(const QVariantList& items) {
	if (m_items == items) {
		return;
	}
	m_items = items;
	clampSelectedIndex();
	markEdited();
}

int MissionPlanModel::selectedIndex() const {
	return m_selectedIndex;
}

void MissionPlanModel::setSelectedIndex(int index) {
	const int clampedIndex = m_items.isEmpty()
		? -1
		: std::max(-1, std::min(index, static_cast<int>(m_items.size()) - 1));
	if (m_selectedIndex == clampedIndex) {
		return;
	}
	m_selectedIndex = clampedIndex;
	emit selectedIndexChanged();
}

bool MissionPlanModel::returnHomeAfterMission() const {
	return m_returnHomeAfterMission;
}

void MissionPlanModel::setReturnHomeAfterMission(bool enabled) {
	if (m_returnHomeAfterMission == enabled) {
		return;
	}
	m_returnHomeAfterMission = enabled;
	emit returnHomeAfterMissionChanged();
	emit signatureChanged();
	markEdited();
}

int MissionPlanModel::revision() const {
	return m_revision;
}

QString MissionPlanModel::signature() const {
	if (m_items.isEmpty()) {
		return {};
	}
	QJsonObject root;
	root.insert("returnHomeAfterMission", m_returnHomeAfterMission);
	root.insert("items", QJsonArray::fromVariantList(m_items));
	return QString::fromUtf8(
		QJsonDocument(root).toJson(QJsonDocument::Compact));
}

double MissionPlanModel::distanceMeters() const {
	double distance = 0.0;
	for (int i = 1; i < m_items.size(); ++i) {
		distance += ::distanceMeters(m_items.at(i - 1), m_items.at(i));
	}
	return distance;
}

double MissionPlanModel::defaultAltitude() const {
	return m_defaultAltitude;
}

void MissionPlanModel::setDefaultAltitude(double altitudeMeters) {
	if (qFuzzyCompare(m_defaultAltitude, altitudeMeters)) {
		return;
	}
	m_defaultAltitude = altitudeMeters;
	emit defaultAltitudeChanged();
}

double MissionPlanModel::defaultSpeed() const {
	return m_defaultSpeed;
}

void MissionPlanModel::setDefaultSpeed(double speedMetersPerSecond) {
	if (qFuzzyCompare(m_defaultSpeed, speedMetersPerSecond)) {
		return;
	}
	m_defaultSpeed = speedMetersPerSecond;
	emit defaultSpeedChanged();
}

QVariant MissionPlanModel::selectedItem() const {
	if (m_selectedIndex < 0 || m_selectedIndex >= m_items.size()) {
		return {};
	}
	return m_items.at(m_selectedIndex);
}

void MissionPlanModel::addWaypoint(double latitude, double longitude) {
	m_items.append(waypointFromCoordinate(
		latitude, longitude, appendAltitude(), appendSpeed()));
	setSelectedIndex(static_cast<int>(m_items.size()) - 1);
	markEdited();
}

void MissionPlanModel::insertWaypointAtSegment(
	int segmentIndex, double latitude, double longitude) {
	const int itemCount = static_cast<int>(m_items.size());
	const int insertIndex = itemCount < kRequiredUploadWaypoints
		? itemCount
		: std::max(0, std::min(segmentIndex + 1, itemCount));
	m_items.insert(insertIndex,
		waypointFromCoordinate(latitude, longitude,
			segmentAltitude(segmentIndex), segmentSpeed(segmentIndex)));
	setSelectedIndex(insertIndex);
	markEdited();
}

void MissionPlanModel::moveWaypoint(
	int index, double latitude, double longitude) {	 // NOLINT
	if (index < 0 || index >= m_items.size()) {
		return;
	}
	QVariantMap item = m_items.at(index).toMap();
	item.insert("latitude", latitude);
	item.insert("longitude", longitude);
	m_items.replace(index, item);
	setSelectedIndex(index);
	markEdited();
}

void MissionPlanModel::removeSelectedWaypoint() {
	if (m_selectedIndex < 0 || m_selectedIndex >= m_items.size()) {
		return;
	}
	m_items.removeAt(m_selectedIndex);
	setSelectedIndex(
		std::min(m_selectedIndex, static_cast<int>(m_items.size()) - 1));
	markEdited();
}

void MissionPlanModel::clear() {
	if (m_items.isEmpty() && m_selectedIndex == -1 &&
		!m_returnHomeAfterMission) {
		return;
	}
	m_items.clear();
	setSelectedIndex(-1);
	if (m_returnHomeAfterMission) {
		m_returnHomeAfterMission = false;
		emit returnHomeAfterMissionChanged();
	}
	markEdited();
}

void MissionPlanModel::setSelectedField(
	const QString& fieldName, double value, double minimumValue) {
	QVariantMap update;
	update.insert(fieldName, std::max(minimumValue, value));
	if (fieldName == "heading") {
		update.insert(fieldName, normalizeHeading(value));
	}
	replaceSelectedItem(update);
}

void MissionPlanModel::setSelectedOptionEnabled(
	const QString& fieldName, bool enabled) {
	QVariantMap update;
	update.insert(fieldName, enabled);
	replaceSelectedItem(update);
}

void MissionPlanModel::setSelectedFlyThrough(bool flyThrough) {
	QVariantMap update;
	update.insert("flyThrough", flyThrough);
	replaceSelectedItem(update);
}

QString MissionPlanModel::validateForUpload() const {
	if (m_items.size() < kRequiredUploadWaypoints) {
		return tr("Add at least 2 waypoints");
	}
	for (int i = 0; i < m_items.size(); ++i) {
		const QVariantMap item = m_items.at(i).toMap();
		const double latitude = item.value("latitude").toDouble();
		const double longitude = item.value("longitude").toDouble();
		if (std::abs(latitude) > kLatitudeMaxDegrees ||
			std::abs(longitude) > kLongitudeMaxDegrees) {
			return tr("Waypoint %1 position is invalid").arg(i + 1);
		}
		if (item.value("altitude").toDouble() < kMinimumAltitudeMeters) {
			return tr("Waypoint %1 altitude is too low").arg(i + 1);
		}
		if (item.value("speedEnabled").toBool() &&
			item.value("speed").toDouble() < kMinimumSpeedMetersPerSecond) {
			return tr("Waypoint %1 speed is invalid").arg(i + 1);
		}
		if (item.value("acceptanceRadiusEnabled").toBool() &&
			item.value("acceptanceRadius").toDouble() <
				kMinimumAcceptanceRadiusMeters) {
			return tr("Waypoint %1 acceptance radius is invalid").arg(i + 1);
		}
	}
	return {};
}

QString MissionPlanModel::distanceText() const {
	const double distance = distanceMeters();
	return distance >= kMetersPerKilometer
		? tr("%1 km").arg(distance / kMetersPerKilometer, 0, 'f', 2)
		: tr("%1 m").arg(qRound(distance));
}

QVariantMap MissionPlanModel::waypointFromCoordinate(
	double latitude, double longitude, double altitude, double speed) {
	return {{"latitude", latitude}, {"longitude", longitude},
		{"altitude", altitude}, {"speed", speed}, {"speedEnabled", false},
		{"acceptanceRadius", kMinimumAcceptanceRadiusMeters},
		{"acceptanceRadiusEnabled", false}, {"flyThrough", true},
		{"loiter", 0.0}, {"loiterEnabled", false}, {"heading", 0.0},
		{"headingEnabled", false}};
}

double MissionPlanModel::appendAltitude() const {
	return m_items.isEmpty()
		? m_defaultAltitude
		: valueFromItem(m_items.constLast(), "altitude", m_defaultAltitude);
}

double MissionPlanModel::appendSpeed() const {
	return m_items.isEmpty()
		? m_defaultSpeed
		: valueFromItem(m_items.constLast(), "speed", m_defaultSpeed);
}

double MissionPlanModel::segmentAltitude(int segmentIndex) const {
	if (segmentIndex < 0 || segmentIndex >= m_items.size() - 1) {
		return appendAltitude();
	}
	return (valueFromItem(
				m_items.at(segmentIndex), "altitude", m_defaultAltitude) +
			   valueFromItem(m_items.at(segmentIndex + 1), "altitude",
				   m_defaultAltitude)) *
		kHalf;
}

double MissionPlanModel::segmentSpeed(int segmentIndex) const {
	if (segmentIndex < 0 || segmentIndex >= m_items.size() - 1) {
		return appendSpeed();
	}
	return (valueFromItem(m_items.at(segmentIndex), "speed", m_defaultSpeed) +
			   valueFromItem(
				   m_items.at(segmentIndex + 1), "speed", m_defaultSpeed)) *
		kHalf;
}

void MissionPlanModel::replaceSelectedItem(const QVariantMap& update) {
	if (m_selectedIndex < 0 || m_selectedIndex >= m_items.size()) {
		return;
	}
	QVariantMap item = m_items.at(m_selectedIndex).toMap();
	for (auto it = update.cbegin(); it != update.cend(); ++it) {
		item.insert(it.key(), it.value());
	}
	m_items.replace(m_selectedIndex, item);
	markEdited();
}

void MissionPlanModel::markEdited() {
	++m_revision;
	emit revisionChanged();
	emitPlanChanged();
}

void MissionPlanModel::emitPlanChanged() {
	emit itemsChanged();
	emit signatureChanged();
	emit distanceChanged();
}

void MissionPlanModel::clampSelectedIndex() {
	const int oldIndex = m_selectedIndex;
	m_selectedIndex = m_items.isEmpty()
		? -1
		: std::max(-1,
			  std::min(m_selectedIndex, static_cast<int>(m_items.size()) - 1));
	if (oldIndex != m_selectedIndex) {
		emit selectedIndexChanged();
	}
}

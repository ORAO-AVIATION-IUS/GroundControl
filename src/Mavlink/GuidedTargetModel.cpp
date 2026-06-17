#include "GuidedTargetModel.h"

#include <cmath>

namespace {
constexpr double kDegreesCircle = 360.0;
}

GuidedTargetModel::GuidedTargetModel(QObject* parent) : QObject(parent) {}

bool GuidedTargetModel::goTargetValid() const {
	return m_goTargetValid;
}

double GuidedTargetModel::goTargetLatitude() const {
	return m_goTargetLatitude;
}

double GuidedTargetModel::goTargetLongitude() const {
	return m_goTargetLongitude;
}

double GuidedTargetModel::goTargetAltitude() const {
	return m_goTargetAltitude;
}

void GuidedTargetModel::setGoTargetAltitude(double altitude) {
	if (qFuzzyCompare(m_goTargetAltitude, altitude)) {
		return;
	}
	m_goTargetAltitude = altitude;
	emit targetsChanged();
}

double GuidedTargetModel::goTargetHeading() const {
	return m_goTargetHeading;
}

void GuidedTargetModel::setGoTargetHeading(double heading) {
	const double normalized = normalizeHeading(heading);
	if (qFuzzyCompare(m_goTargetHeading, normalized)) {
		return;
	}
	m_goTargetHeading = normalized;
	emit targetsChanged();
}

bool GuidedTargetModel::lookTargetValid() const {
	return m_lookTargetValid;
}

double GuidedTargetModel::lookTargetLatitude() const {
	return m_lookTargetLatitude;
}

double GuidedTargetModel::lookTargetLongitude() const {
	return m_lookTargetLongitude;
}

double GuidedTargetModel::lookTargetHeading() const {
	return m_lookTargetHeading;
}

void GuidedTargetModel::setLookTargetHeading(double heading) {
	const double normalized = normalizeHeading(heading);
	if (qFuzzyCompare(m_lookTargetHeading, normalized)) {
		return;
	}
	m_lookTargetHeading = normalized;
	emit targetsChanged();
}

bool GuidedTargetModel::localHomeValid() const {
	return m_localHomeValid;
}

double GuidedTargetModel::localHomeLatitude() const {
	return m_localHomeLatitude;
}

double GuidedTargetModel::localHomeLongitude() const {
	return m_localHomeLongitude;
}

double GuidedTargetModel::localHomeAltitude() const {
	return m_localHomeAltitude;
}

bool GuidedTargetModel::flyPromptOpen() const {
	return m_flyPromptOpen;
}

void GuidedTargetModel::setFlyPromptOpen(bool open) {
	if (m_flyPromptOpen == open) {
		return;
	}
	m_flyPromptOpen = open;
	emit promptChanged();
}

QString GuidedTargetModel::flyPromptKind() const {
	return m_flyPromptKind;
}

void GuidedTargetModel::setFlyPromptKind(const QString& kind) {
	if (m_flyPromptKind == kind) {
		return;
	}
	m_flyPromptKind = kind;
	emit promptChanged();
}

bool GuidedTargetModel::mapContextOpen() const {
	return m_mapContextOpen;
}

void GuidedTargetModel::setMapContextOpen(bool open) {
	if (m_mapContextOpen == open) {
		return;
	}
	m_mapContextOpen = open;
	emit contextChanged();
}

double GuidedTargetModel::mapContextLatitude() const {
	return m_mapContextLatitude;
}

double GuidedTargetModel::mapContextLongitude() const {
	return m_mapContextLongitude;
}

double GuidedTargetModel::mapContextX() const {
	return m_mapContextX;
}

double GuidedTargetModel::mapContextY() const {
	return m_mapContextY;
}

bool GuidedTargetModel::snapshotValid() const {
	return m_snapshotValid;
}

// NOLINTBEGIN(bugprone-easily-swappable-parameters)
void GuidedTargetModel::setGoTarget(
	double latitude, double longitude, double altitude, double heading) {
	m_goTargetValid = true;
	m_goTargetLatitude = latitude;
	m_goTargetLongitude = longitude;
	m_goTargetAltitude = altitude;
	m_goTargetHeading = normalizeHeading(heading);
	emit targetsChanged();
}

void GuidedTargetModel::setLookTarget(
	double latitude, double longitude, double heading) {
	m_lookTargetValid = true;
	m_lookTargetLatitude = latitude;
	m_lookTargetLongitude = longitude;
	m_lookTargetHeading = normalizeHeading(heading);
	emit targetsChanged();
}

void GuidedTargetModel::setLocalHome(
	double latitude, double longitude, double altitude) {
	m_localHomeValid = true;
	m_localHomeLatitude = latitude;
	m_localHomeLongitude = longitude;
	m_localHomeAltitude = altitude;
	emit targetsChanged();
}

void GuidedTargetModel::clearTarget(const QString& kind) {
	if (kind == "go") {
		m_goTargetValid = false;
	} else if (kind == "look") {
		m_lookTargetValid = false;
	} else if (kind == "home") {
		m_localHomeValid = false;
	} else {
		return;
	}
	emit targetsChanged();
}

void GuidedTargetModel::setMapContext(
	double latitude, double longitude, double x, double y) {
	m_mapContextLatitude = latitude;
	m_mapContextLongitude = longitude;
	m_mapContextX = x;
	m_mapContextY = y;
	m_mapContextOpen = true;
	emit contextChanged();
}
// NOLINTEND(bugprone-easily-swappable-parameters)

void GuidedTargetModel::closeMapContext() {
	setMapContextOpen(false);
}

void GuidedTargetModel::openPrompt(const QString& kind) {
	const bool oldOpen = m_flyPromptOpen;
	const QString oldKind = m_flyPromptKind;
	m_flyPromptKind = kind;
	m_flyPromptOpen = !kind.isEmpty();
	emitPromptIfChanged(oldOpen, oldKind);
}

void GuidedTargetModel::closePrompt() {
	const bool oldOpen = m_flyPromptOpen;
	const QString oldKind = m_flyPromptKind;
	m_flyPromptOpen = false;
	m_flyPromptKind.clear();
	emitPromptIfChanged(oldOpen, oldKind);
}

void GuidedTargetModel::snapshotTarget(const QString& kind) {
	m_snapshot = {};
	m_snapshot.kind = kind;
	if (kind == "go" && m_goTargetValid) {
		m_snapshot.valid = true;
		m_snapshot.latitude = m_goTargetLatitude;
		m_snapshot.longitude = m_goTargetLongitude;
		m_snapshot.altitude = m_goTargetAltitude;
		m_snapshot.heading = m_goTargetHeading;
	} else if (kind == "look" && m_lookTargetValid) {
		m_snapshot.valid = true;
		m_snapshot.latitude = m_lookTargetLatitude;
		m_snapshot.longitude = m_lookTargetLongitude;
		m_snapshot.heading = m_lookTargetHeading;
	}
	m_snapshotValid = true;
	emit snapshotChanged();
}

void GuidedTargetModel::restoreSnapshot() {
	if (!m_snapshotValid || m_snapshot.kind != m_flyPromptKind) {
		return;
	}
	if (m_snapshot.kind == "go") {
		m_goTargetValid = m_snapshot.valid;
		if (m_goTargetValid) {
			m_goTargetLatitude = m_snapshot.latitude;
			m_goTargetLongitude = m_snapshot.longitude;
			m_goTargetAltitude = m_snapshot.altitude;
			m_goTargetHeading = m_snapshot.heading;
		}
	} else if (m_snapshot.kind == "look") {
		m_lookTargetValid = m_snapshot.valid;
		if (m_lookTargetValid) {
			m_lookTargetLatitude = m_snapshot.latitude;
			m_lookTargetLongitude = m_snapshot.longitude;
			m_lookTargetHeading = m_snapshot.heading;
		}
	}
	emit targetsChanged();
}

void GuidedTargetModel::clearSnapshot() {
	if (!m_snapshotValid) {
		return;
	}
	m_snapshot = {};
	m_snapshotValid = false;
	emit snapshotChanged();
}

double GuidedTargetModel::normalizeHeading(double heading) {
	return std::fmod(
		std::fmod(heading, kDegreesCircle) + kDegreesCircle, kDegreesCircle);
}

void GuidedTargetModel::emitPromptIfChanged(
	bool oldOpen, const QString& oldKind) {
	if (oldOpen != m_flyPromptOpen || oldKind != m_flyPromptKind) {
		emit promptChanged();
	}
}

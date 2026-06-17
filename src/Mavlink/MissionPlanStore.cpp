#include "MissionPlanStore.h"

#include "MissionPlanModel.h"

#include <QDateTime>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QUrl>

namespace {
constexpr int kMissionPlanVersion = 1;
// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays)
constexpr char kSettingsGroup[] = "MissionPlanning";
// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays)
constexpr char kSavedMissionPlansKey[] = "savedMissionPlans";
// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays)
constexpr char kSavedMissionPlanKey[] = "savedMissionPlan";
// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays)
constexpr char kUntitledMissionName[] = "Mission";
}  // namespace

MissionPlanStore::MissionPlanStore(QObject* parent) : QObject(parent) {}

// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
QStringList MissionPlanStore::missionNames() const {
	QStringList names = savedMissionStore().keys();
	names.sort(Qt::CaseInsensitive);
	return names;
}

int MissionPlanStore::revision() const {
	return m_revision;
}

QString MissionPlanStore::errorText() const {
	return m_errorText;
}

bool MissionPlanStore::saveMission(
	const QString& name, MissionPlanModel* missionPlan) {
	const QString trimmedName = name.trimmed();
	if (trimmedName.isEmpty()) {
		setError(tr("Name the mission before saving"));
		return false;
	}
	if (missionPlan == nullptr || missionPlan->items().isEmpty()) {
		setError(tr("No mission to save"));
		return false;
	}

	QVariantMap store = savedMissionStore();
	const QVariantMap previous = store.value(trimmedName).toMap();
	const QVariantMap document =
		documentFromPlan(trimmedName, missionPlan, previous);
	store.insert(trimmedName, document);
	writeMissionStore(store);

	QSettings settings;
	settings.beginGroup(QString::fromLatin1(kSettingsGroup));
	settings.setValue(QString::fromLatin1(kSavedMissionPlanKey),
		QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(document))
				.toJson(QJsonDocument::Compact)));
	settings.endGroup();

	clearError();
	bumpRevision();
	return true;
}

bool MissionPlanStore::loadMission(
	const QString& name, MissionPlanModel* missionPlan) {
	if (missionPlan == nullptr) {
		setError(tr("No mission model available"));
		return false;
	}
	const QVariantMap document = missionDocument(name.trimmed());
	if (!isValidDocument(document)) {
		setError(tr("Saved mission draft is invalid"));
		return false;
	}

	missionPlan->setItems(document.value("items").toList());
	missionPlan->setReturnHomeAfterMission(
		document.value("returnHomeAfterMission").toBool());
	clearError();
	return true;
}

bool MissionPlanStore::deleteMission(const QString& name) {
	const QString trimmedName = name.trimmed();
	QVariantMap store = savedMissionStore();
	if (!store.contains(trimmedName)) {
		return false;
	}
	store.remove(trimmedName);
	writeMissionStore(store);
	clearError();
	bumpRevision();
	return true;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
bool MissionPlanStore::exportMission(const QString& fileUrl,
	const QString& name, MissionPlanModel* missionPlan) {
	if (missionPlan == nullptr || missionPlan->items().isEmpty()) {
		setError(tr("No mission to export"));
		return false;
	}
	const QString path = localPathFor(fileUrl);
	if (path.isEmpty()) {
		setError(tr("Choose an export file"));
		return false;
	}

	QFile file(path);
	if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
		setError(tr("Cannot open export file"));
		return false;
	}
	const QString documentName = name.trimmed().isEmpty()
		? QString::fromLatin1(kUntitledMissionName)
		: name.trimmed();
	const QVariantMap document = documentFromPlan(documentName, missionPlan);
	file.write(QJsonDocument(QJsonObject::fromVariantMap(document))
			.toJson(QJsonDocument::Indented));
	clearError();
	return true;
}

bool MissionPlanStore::importMission(
	const QString& fileUrl, MissionPlanModel* missionPlan) {
	if (missionPlan == nullptr) {
		setError(tr("No mission model available"));
		return false;
	}
	const QString path = localPathFor(fileUrl);
	if (path.isEmpty()) {
		setError(tr("Choose an import file"));
		return false;
	}

	QFile file(path);
	if (!file.open(QIODevice::ReadOnly)) {
		setError(tr("Cannot open import file"));
		return false;
	}
	QJsonParseError parseError;
	const QJsonDocument json =
		QJsonDocument::fromJson(file.readAll(), &parseError);
	if (parseError.error != QJsonParseError::NoError || !json.isObject()) {
		setError(tr("Mission file is invalid"));
		return false;
	}
	const QVariantMap document = json.object().toVariantMap();
	if (!isValidDocument(document)) {
		setError(tr("Mission file is invalid"));
		return false;
	}
	missionPlan->setItems(document.value("items").toList());
	missionPlan->setReturnHomeAfterMission(
		document.value("returnHomeAfterMission").toBool());
	clearError();
	return true;
}

// NOLINTNEXTLINE(readability-convert-member-functions-to-static)
QVariantMap MissionPlanStore::missionDocument(const QString& name) const {
	return savedMissionStore().value(name).toMap();
}

QVariantMap MissionPlanStore::savedMissionStore() {
	QSettings settings;
	settings.beginGroup(QString::fromLatin1(kSettingsGroup));
	const QString raw =
		settings.value(QString::fromLatin1(kSavedMissionPlansKey), "{}")
			.toString();
	settings.endGroup();

	const QJsonDocument json = QJsonDocument::fromJson(raw.toUtf8());
	return json.isObject() ? json.object().toVariantMap() : QVariantMap{};
}

void MissionPlanStore::writeMissionStore(const QVariantMap& store) {
	QSettings settings;
	settings.beginGroup(QString::fromLatin1(kSettingsGroup));
	settings.setValue(QString::fromLatin1(kSavedMissionPlansKey),
		QString::fromUtf8(QJsonDocument(QJsonObject::fromVariantMap(store))
				.toJson(QJsonDocument::Compact)));
	settings.endGroup();
}

QVariantMap MissionPlanStore::documentFromPlan(const QString& name,
	MissionPlanModel* missionPlan, const QVariantMap& previousDocument) {
	const QString now = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
	return {{"version", kMissionPlanVersion}, {"name", name},
		{"createdAt", previousDocument.value("createdAt", now)},
		{"modifiedAt", now},
		{"returnHomeAfterMission", missionPlan->returnHomeAfterMission()},
		{"items", missionPlan->items()}};
}

QString MissionPlanStore::localPathFor(const QString& fileUrl) {
	const QUrl url(fileUrl);
	if (url.isLocalFile()) {
		return url.toLocalFile();
	}
	return fileUrl;
}

bool MissionPlanStore::isValidDocument(const QVariantMap& document) {
	return document.value("items").canConvert<QVariantList>() &&
		!document.value("items").toList().isEmpty();
}

void MissionPlanStore::clearError() {
	if (m_errorText.isEmpty()) {
		return;
	}
	m_errorText.clear();
	emit errorTextChanged();
}

void MissionPlanStore::setError(const QString& message) {
	if (m_errorText == message) {
		return;
	}
	m_errorText = message;
	emit errorTextChanged();
}

void MissionPlanStore::bumpRevision() {
	++m_revision;
	emit storeChanged();
}

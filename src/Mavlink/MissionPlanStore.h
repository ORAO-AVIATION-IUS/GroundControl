#pragma once

#include <qqmlintegration.h>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

class MissionPlanModel;

class MissionPlanStore : public QObject {
	Q_OBJECT
	QML_ELEMENT

	Q_PROPERTY(QStringList missionNames READ missionNames NOTIFY storeChanged)
	Q_PROPERTY(int revision READ revision NOTIFY storeChanged)
	Q_PROPERTY(QString errorText READ errorText NOTIFY errorTextChanged)

   public:
	explicit MissionPlanStore(QObject* parent = nullptr);

	[[nodiscard]] QStringList missionNames() const;
	[[nodiscard]] int revision() const;
	[[nodiscard]] QString errorText() const;

	Q_INVOKABLE bool saveMission(
		const QString& name, MissionPlanModel* missionPlan);
	Q_INVOKABLE bool loadMission(
		const QString& name, MissionPlanModel* missionPlan);
	Q_INVOKABLE bool deleteMission(const QString& name);
	Q_INVOKABLE bool exportMission(const QString& fileUrl, const QString& name,
		MissionPlanModel* missionPlan);
	Q_INVOKABLE bool importMission(
		const QString& fileUrl, MissionPlanModel* missionPlan);
	[[nodiscard]] Q_INVOKABLE QVariantMap missionDocument(
		const QString& name) const;

   signals:
	void storeChanged();
	void errorTextChanged();

   private:
	[[nodiscard]] static QVariantMap savedMissionStore();
	static void writeMissionStore(const QVariantMap& store);
	[[nodiscard]] static QVariantMap documentFromPlan(const QString& name,
		MissionPlanModel* missionPlan,
		const QVariantMap& previousDocument = {});
	[[nodiscard]] static QString localPathFor(const QString& fileUrl);
	[[nodiscard]] static bool isValidDocument(const QVariantMap& document);
	void clearError();
	void setError(const QString& message);
	void bumpRevision();

	int m_revision{0};
	QString m_errorText;
};

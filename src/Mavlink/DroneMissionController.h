#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

#include <plugins/mission/mission.hpp>
#include <system.hpp>

#include <memory>

class DroneMissionController : public QObject {
	Q_OBJECT

   public:
	explicit DroneMissionController(
		QString droneName, QObject* parent = nullptr);
	~DroneMissionController() override;

	DroneMissionController(const DroneMissionController&) = delete;
	DroneMissionController& operator=(const DroneMissionController&) = delete;
	DroneMissionController(DroneMissionController&&) = delete;
	DroneMissionController& operator=(DroneMissionController&&) = delete;

	void setDroneName(const QString& droneName);
	void attachSystem(const std::shared_ptr<mavsdk::System>& system);
	void detachSystem();

	void uploadMission(
		const QVariantList& missionItems, bool returnToLaunchAfterMission);
	void startMission();
	void pauseMission();
	void clearMission();
	void downloadMission();

   signals:
	void missionProgressChanged(int current, int total);
	void logMessage(
		const QString& source, const QString& message, const QString& level);
	void missionUploadFinished(bool success, const QString& message);
	void missionStartFinished(bool success, const QString& message);
	void missionPauseFinished(bool success, const QString& message);
	void missionClearFinished(bool success, const QString& message);
	void missionDownloadFinished(bool success, const QString& message,
		const QVariantList& missionItems, bool returnToLaunchAfterMission);

   private:
	template <typename T>
	void onThread(T&& fn);

	QString m_droneName;
	std::unique_ptr<mavsdk::Mission> m_mission;
	mavsdk::Mission::MissionProgressHandle m_missionProgressHandle;
};

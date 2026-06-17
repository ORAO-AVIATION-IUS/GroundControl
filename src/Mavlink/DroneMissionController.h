#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

#include <plugins/mission/mission.hpp>
#include <system.hpp>

#include <cstdint>
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

	[[nodiscard]] bool missionBusy() const;
	[[nodiscard]] QString missionBusyText() const;
	[[nodiscard]] bool missionRunning() const;
	[[nodiscard]] bool missionPaused() const;
	[[nodiscard]] bool missionFinished() const;
	[[nodiscard]] QString missionErrorText() const;
	[[nodiscard]] QString uploadedPlanSignature() const;
	[[nodiscard]] bool missionUploaded(const QString& currentSignature) const;
	[[nodiscard]] bool missionDirty(const QString& currentSignature) const;

	void uploadMission(const QVariantList& missionItems,
		bool returnToLaunchAfterMission, bool landAfterMission,
		const QString& planSignature);
	void startMission();
	void restartMission();
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
	void missionStateChanged();

   private:
	template <typename T>
	void onThread(T&& fn);

	enum class Operation : std::uint8_t {
		None,
		Upload,
		Start,
		Restart,
		Pause,
		Clear,
		Download
	};

	[[nodiscard]] int beginOperation(Operation operation,
		const QString& busyText, const QString& pendingSignature = {});
	[[nodiscard]] bool finishOperation(Operation operation, int operationId,
		bool success, const QString& message);
	void setError(Operation operation, int operationId, const QString& message);
	void resetMissionState();
	void handleUploadResult(int operationId, mavsdk::Mission::Result result);
	[[nodiscard]] bool isCurrentOperation(
		Operation operation, int operationId) const;
	[[nodiscard]] static QString missionSignatureFor(
		const QVariantList& missionItems, bool returnToLaunchAfterMission,
		bool landAfterMission);
	void beginStartLikeMission(Operation operation, const QString& busyText,
		const QString& successMessage);
	void startMissionAsync(
		Operation operation, int operationId, const QString& successMessage);
	void handleMissionProgress(int current, int total);

	QString m_droneName;
	std::unique_ptr<mavsdk::Mission> m_mission;
	mavsdk::Mission::MissionProgressHandle m_missionProgressHandle;
	bool m_missionBusy{false};
	QString m_missionBusyText;
	Operation m_activeOperation{Operation::None};
	int m_operationSequence{0};
	int m_activeOperationId{0};
	QString m_uploadedPlanSignature;
	QString m_pendingPlanSignature;
	QString m_missionErrorText;
	bool m_missionRunning{false};
	bool m_missionPaused{false};
	bool m_missionFinished{false};
	int m_lastProgressCurrent{0};
	int m_lastProgressTotal{0};
};

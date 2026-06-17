#include "DroneMissionController.h"

#include <cmath>
#include <string>
#include <utility>

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QVariantMap>

namespace {
constexpr float kDefaultMissionAltitudeM = 50.0F;
constexpr float kDefaultMissionSpeedMS = 8.0F;
constexpr float kDefaultAcceptanceRadiusM = 3.0F;
constexpr double kMinLatitudeDeg = -90.0;
constexpr double kMaxLatitudeDeg = 90.0;
constexpr double kMinLongitudeDeg = -180.0;
constexpr double kMaxLongitudeDeg = 180.0;
// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays)
constexpr char kCommandTakeoff[] = "takeoff";
// NOLINTNEXTLINE(cppcoreguidelines-avoid-c-arrays,modernize-avoid-c-arrays)
constexpr char kCommandLand[] = "land";

QString missionResultString(mavsdk::Mission::Result result) {
	return QString::fromStdString(std::string(to_string(result)));
}

QVariantList missionPlanToVariantList(
	const mavsdk::Mission::MissionPlan& plan) {
	QVariantList missionItems;
	missionItems.reserve(static_cast<qsizetype>(plan.mission_items.size()));
	for (const mavsdk::Mission::MissionItem& missionItem : plan.mission_items) {
		QVariantMap item;
		item.insert("latitude", missionItem.latitude_deg);
		item.insert("longitude", missionItem.longitude_deg);
		item.insert("altitude", missionItem.relative_altitude_m);
		item.insert("speed",
			missionItem.speed_m_s > 0.0F ? missionItem.speed_m_s
										 : kDefaultMissionSpeedMS);
		item.insert("speedEnabled", missionItem.speed_m_s > 0.0F);
		item.insert("acceptanceRadius",
			missionItem.acceptance_radius_m > 0.0F
				? missionItem.acceptance_radius_m
				: kDefaultAcceptanceRadiusM);
		item.insert(
			"acceptanceRadiusEnabled", missionItem.acceptance_radius_m > 0.0F);
		item.insert("flyThrough", missionItem.is_fly_through);
		item.insert("loiter", missionItem.loiter_time_s);
		item.insert("loiterEnabled", missionItem.loiter_time_s > 0.0F);
		item.insert("heading",
			std::isnan(missionItem.yaw_deg) ? 0.0F : missionItem.yaw_deg);
		item.insert("headingEnabled", !std::isnan(missionItem.yaw_deg));
		if (missionItem.vehicle_action ==
			mavsdk::Mission::MissionItem::VehicleAction::Takeoff) {
			item.insert("command", QString::fromLatin1(kCommandTakeoff));
		} else if (missionItem.vehicle_action ==
			mavsdk::Mission::MissionItem::VehicleAction::Land) {
			item.insert("command", QString::fromLatin1(kCommandLand));
		} else {
			item.insert("command", "waypoint");
		}
		item.insert("altitudeReference", "relative");
		missionItems.push_back(item);
	}
	return missionItems;
}

[[nodiscard]] bool missionItemFromVariant(const QVariantMap& item,
	mavsdk::Mission::MissionItem& missionItem, QString& errorMessage) {
	const double latitude = item.value("latitude").toDouble();
	const double longitude = item.value("longitude").toDouble();
	if (latitude < kMinLatitudeDeg || latitude > kMaxLatitudeDeg ||
		longitude < kMinLongitudeDeg || longitude > kMaxLongitudeDeg) {
		errorMessage =
			QStringLiteral("Cannot upload mission: invalid waypoint");
		return false;
	}

	missionItem.latitude_deg = latitude;
	missionItem.longitude_deg = longitude;
	missionItem.relative_altitude_m = static_cast<float>(
		item.value("altitude", kDefaultMissionAltitudeM).toDouble());
	if (item.value("speedEnabled", false).toBool()) {
		missionItem.speed_m_s = static_cast<float>(
			item.value("speed", kDefaultMissionSpeedMS).toDouble());
	}
	if (item.value("acceptanceRadiusEnabled", false).toBool()) {
		missionItem.acceptance_radius_m = static_cast<float>(
			item.value("acceptanceRadius", kDefaultAcceptanceRadiusM)
				.toDouble());
	}
	missionItem.is_fly_through = item.value("flyThrough", true).toBool();
	if (item.value("loiterEnabled", false).toBool()) {
		missionItem.loiter_time_s =
			static_cast<float>(item.value("loiter", 0.0).toDouble());
	}
	if (item.value("headingEnabled", false).toBool()) {
		missionItem.yaw_deg =
			static_cast<float>(item.value("heading", 0.0).toDouble());
	}
	missionItem.camera_action =
		mavsdk::Mission::MissionItem::CameraAction::None;
	const QString command =
		item.value("command", "waypoint").toString().trimmed().toLower();
	if (command == kCommandTakeoff) {
		missionItem.vehicle_action =
			mavsdk::Mission::MissionItem::VehicleAction::Takeoff;
	} else if (command == kCommandLand) {
		missionItem.vehicle_action =
			mavsdk::Mission::MissionItem::VehicleAction::Land;
	} else {
		missionItem.vehicle_action =
			mavsdk::Mission::MissionItem::VehicleAction::None;
	}
	return true;
}

}  // namespace

DroneMissionController::DroneMissionController(
	QString droneName, QObject* parent)
	: QObject(parent), m_droneName(std::move(droneName)) {}

DroneMissionController::~DroneMissionController() {
	detachSystem();
}

void DroneMissionController::setDroneName(const QString& droneName) {
	m_droneName = droneName;
}

void DroneMissionController::attachSystem(
	const std::shared_ptr<mavsdk::System>& system) {
	if (!system) {
		return;
	}

	detachSystem();
	m_mission = std::make_unique<mavsdk::Mission>(system);
	m_missionProgressHandle = m_mission->subscribe_mission_progress(
		[this](mavsdk::Mission::MissionProgress progress) {
			const int current = static_cast<int>(progress.current);
			const int total = static_cast<int>(progress.total);
			onThread([this, current, total]() {
				handleMissionProgress(current, total);
				emit missionProgressChanged(current, total);
			});
		});
}

void DroneMissionController::detachSystem() {
	if (m_mission && m_missionProgressHandle.valid()) {
		m_mission->unsubscribe_mission_progress(m_missionProgressHandle);
		m_missionProgressHandle = {};
	}
	m_mission.reset();
}

bool DroneMissionController::missionBusy() const {
	return m_missionBusy;
}

QString DroneMissionController::missionBusyText() const {
	return m_missionBusyText;
}

bool DroneMissionController::missionRunning() const {
	return m_missionRunning;
}

bool DroneMissionController::missionPaused() const {
	return m_missionPaused;
}

bool DroneMissionController::missionFinished() const {
	return m_missionFinished;
}

void DroneMissionController::handleMissionProgress(int current, int total) {
	// Log each waypoint as it is reached. MAVSDK reports `current` as the
	// index of the waypoint the vehicle is now heading to, so advancing from
	// k to k+1 means waypoint k has just been reached.
	if (total > 0 && current > m_lastProgressCurrent &&
		m_lastProgressTotal == total) {
		for (int reached = m_lastProgressCurrent; reached < current; ++reached) {
			if (reached <= 0) {
				continue;
			}
			emit logMessage(m_droneName,
				QString("Waypoint %1 of %2 reached").arg(reached).arg(total),
				"info");
		}
	}

	const bool finished = total > 0 && current >= total;
	if (finished && !m_missionFinished) {
		m_missionFinished = true;
		m_missionRunning = false;
		m_missionPaused = false;
		emit logMessage(m_droneName, "Mission complete", "info");
		emit missionStateChanged();
	}

	m_lastProgressCurrent = current;
	m_lastProgressTotal = total;
}

QString DroneMissionController::missionErrorText() const {
	return m_missionErrorText;
}

QString DroneMissionController::uploadedPlanSignature() const {
	return m_uploadedPlanSignature;
}

bool DroneMissionController::missionUploaded(
	const QString& currentSignature) const {
	return !currentSignature.isEmpty() &&
		m_uploadedPlanSignature == currentSignature;
}

bool DroneMissionController::missionDirty(
	const QString& currentSignature) const {
	return !m_uploadedPlanSignature.isEmpty() &&
		m_uploadedPlanSignature != currentSignature;
}

void DroneMissionController::uploadMission(const QVariantList& missionItems,
	bool returnToLaunchAfterMission, bool landAfterMission,
	const QString& planSignature) {
	const int operationId =
		beginOperation(Operation::Upload, "UPLOADING", planSignature);
	if (!m_mission) {
		const QString message = "Cannot upload mission: not connected";
		setError(Operation::Upload, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionUploadFinished(false, message);
		return;
	}
	if (missionItems.size() < 2) {
		const QString message =
			"Cannot upload mission: add at least 2 waypoints";
		setError(Operation::Upload, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionUploadFinished(false, message);
		return;
	}

	mavsdk::Mission::MissionPlan plan;
	plan.mission_items.reserve(static_cast<size_t>(missionItems.size()));
	for (const QVariant& value : missionItems) {
		mavsdk::Mission::MissionItem missionItem{};
		QString message;
		if (!missionItemFromVariant(value.toMap(), missionItem, message)) {
			setError(Operation::Upload, operationId, message);
			emit logMessage(m_droneName, message, "warning");
			emit missionUploadFinished(false, message);
			return;
		}
		plan.mission_items.push_back(missionItem);
	}

	// "Land at end" has no dedicated MAVSDK flag, so append an explicit Land
	// command at the final waypoint's location.
	if (landAfterMission && !plan.mission_items.empty()) {
		const mavsdk::Mission::MissionItem& last = plan.mission_items.back();
		mavsdk::Mission::MissionItem landItem{};
		landItem.latitude_deg = last.latitude_deg;
		landItem.longitude_deg = last.longitude_deg;
		landItem.relative_altitude_m = 0.0F;
		landItem.is_fly_through = false;
		landItem.camera_action =
			mavsdk::Mission::MissionItem::CameraAction::None;
		landItem.vehicle_action =
			mavsdk::Mission::MissionItem::VehicleAction::Land;
		plan.mission_items.push_back(landItem);
	}

	m_mission->set_return_to_launch_after_mission(returnToLaunchAfterMission);
	m_mission->upload_mission_async(
		plan, [this, operationId](mavsdk::Mission::Result result) {
			onThread([this, operationId, result]() {
				handleUploadResult(operationId, result);
			});
		});
}

void DroneMissionController::handleUploadResult(
	int operationId, mavsdk::Mission::Result result) {
	if (result == mavsdk::Mission::Result::Success) {
		const QString message = "Mission uploaded";
		if (!finishOperation(Operation::Upload, operationId, true, message)) {
			return;
		}
		emit logMessage(m_droneName, message, "info");
		emit missionUploadFinished(true, message);
		return;
	}

	const QString message =
		QString("Mission upload failed: %1").arg(missionResultString(result));
	if (!finishOperation(Operation::Upload, operationId, false, message)) {
		return;
	}
	emit logMessage(m_droneName, message, "error");
	emit missionUploadFinished(false, message);
}

void DroneMissionController::startMission() {
	beginStartLikeMission(Operation::Start, "STARTING", "Mission started");
}

void DroneMissionController::restartMission() {
	// Restarting a finished mission requires resetting the active item to 0;
	// otherwise the vehicle reports "No valid mission available" and loiters.
	const int operationId = beginOperation(Operation::Restart, "RESTARTING");
	if (!m_mission) {
		const QString message = "Cannot restart mission: not connected";
		setError(Operation::Restart, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionStartFinished(false, message);
		return;
	}
	m_mission->set_current_mission_item_async(
		0, [this, operationId](mavsdk::Mission::Result result) {
			onThread([this, operationId, result]() {
				if (!isCurrentOperation(Operation::Restart, operationId)) {
					return;
				}
				if (result != mavsdk::Mission::Result::Success) {
					const QString message =
						QString("Mission restart failed: %1")
							.arg(missionResultString(result));
					if (!finishOperation(
							Operation::Restart, operationId, false, message)) {
						return;
					}
					emit logMessage(m_droneName, message, "error");
					emit missionStartFinished(false, message);
					return;
				}
				startMissionAsync(
					Operation::Restart, operationId, "Mission restarted");
			});
		});
}

void DroneMissionController::beginStartLikeMission(Operation operation,
	const QString& busyText, const QString& successMessage) {
	const int operationId = beginOperation(operation, busyText);
	if (!m_mission) {
		const QString message = "Cannot start mission: not connected";
		setError(operation, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionStartFinished(false, message);
		return;
	}
	startMissionAsync(operation, operationId, successMessage);
}

void DroneMissionController::startMissionAsync(
	Operation operation, int operationId, const QString& successMessage) {
	m_mission->start_mission_async(
		[this, operation, operationId, successMessage](
			mavsdk::Mission::Result result) {
			onThread([this, operation, operationId, successMessage, result]() {
				if (result == mavsdk::Mission::Result::Success) {
					if (!finishOperation(
							operation, operationId, true, successMessage)) {
						return;
					}
					emit logMessage(m_droneName, successMessage, "info");
					emit missionStartFinished(true, successMessage);
				} else {
					const QString message = QString("Mission start failed: %1")
												.arg(missionResultString(result));
					if (!finishOperation(
							operation, operationId, false, message)) {
						return;
					}
					emit logMessage(m_droneName, message, "error");
					emit missionStartFinished(false, message);
				}
			});
		});
}

void DroneMissionController::pauseMission() {
	const int operationId = beginOperation(Operation::Pause, "PAUSING");
	if (!m_mission) {
		const QString message = "Cannot pause mission: not connected";
		setError(Operation::Pause, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionPauseFinished(false, message);
		return;
	}
	m_mission->pause_mission_async([this, operationId](
									   mavsdk::Mission::Result result) {
		onThread([this, operationId, result]() {
			if (result == mavsdk::Mission::Result::Success) {
				const QString message = "Mission paused";
				if (!finishOperation(
						Operation::Pause, operationId, true, message)) {
					return;
				}
				emit logMessage(m_droneName, message, "info");
				emit missionPauseFinished(true, message);
			} else {
				const QString message = QString("Mission pause failed: %1")
											.arg(missionResultString(result));
				if (!finishOperation(
						Operation::Pause, operationId, false, message)) {
					return;
				}
				emit logMessage(m_droneName, message, "error");
				emit missionPauseFinished(false, message);
			}
		});
	});
}

void DroneMissionController::clearMission() {
	const int operationId = beginOperation(Operation::Clear, "CLEARING");
	if (!m_mission) {
		const QString message = "Cannot clear mission: not connected";
		setError(Operation::Clear, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionClearFinished(false, message);
		return;
	}
	m_mission->clear_mission_async([this, operationId](
									   mavsdk::Mission::Result result) {
		onThread([this, operationId, result]() {
			if (result == mavsdk::Mission::Result::Success) {
				const QString message = "Mission cleared";
				if (!finishOperation(
						Operation::Clear, operationId, true, message)) {
					return;
				}
				emit missionProgressChanged(0, 0);
				emit logMessage(m_droneName, message, "info");
				emit missionClearFinished(true, message);
			} else {
				const QString message = QString("Mission clear failed: %1")
											.arg(missionResultString(result));
				if (!finishOperation(
						Operation::Clear, operationId, false, message)) {
					return;
				}
				emit logMessage(m_droneName, message, "error");
				emit missionClearFinished(false, message);
			}
		});
	});
}

void DroneMissionController::downloadMission() {
	const int operationId = beginOperation(Operation::Download, "DOWNLOADING");
	if (!m_mission) {
		const QString message = "Cannot download mission: not connected";
		setError(Operation::Download, operationId, message);
		emit logMessage(m_droneName, message, "warning");
		emit missionDownloadFinished(false, message, {}, false);
		return;
	}
	m_mission->download_mission_async(
		[this, operationId](mavsdk::Mission::Result result,
			const mavsdk::Mission::MissionPlan& plan) {
			auto returnToLaunch =
				m_mission->get_return_to_launch_after_mission();
			onThread([this, operationId, result, plan, returnToLaunch]() {
				if (result == mavsdk::Mission::Result::Success) {
					const QVariantList missionItems =
						missionPlanToVariantList(plan);
					const bool rtl =
						returnToLaunch.first == mavsdk::Mission::Result::Success
						? returnToLaunch.second
						: false;
					if (!isCurrentOperation(Operation::Download, operationId)) {
						return;
					}
					m_pendingPlanSignature =
						missionSignatureFor(missionItems, rtl, false);
					const QString message = "Mission downloaded";
					if (!finishOperation(
							Operation::Download, operationId, true, message)) {
						return;
					}
					emit logMessage(m_droneName, message, "info");
					emit missionDownloadFinished(
						true, message, missionItems, rtl);
				} else {
					const QString message =
						QString("Mission download failed: %1")
							.arg(missionResultString(result));
					if (!finishOperation(
							Operation::Download, operationId, false, message)) {
						return;
					}
					emit logMessage(m_droneName, message, "error");
					emit missionDownloadFinished(false, message, {}, false);
				}
			});
		});
}

template <typename T>
void DroneMissionController::onThread(T&& fn) {
	QMetaObject::invokeMethod(this, std::forward<T>(fn), Qt::QueuedConnection);
}

int DroneMissionController::beginOperation(Operation operation,
	const QString& busyText, const QString& pendingSignature) {
	m_missionBusy = true;
	m_missionBusyText = busyText;
	m_activeOperation = operation;
	m_activeOperationId = ++m_operationSequence;
	m_pendingPlanSignature = pendingSignature;
	m_missionErrorText.clear();
	emit missionStateChanged();
	return m_activeOperationId;
}

bool DroneMissionController::finishOperation(Operation operation,
	int operationId, bool success, const QString& message) {
	if (!isCurrentOperation(operation, operationId)) {
		return false;
	}
	m_missionBusy = false;
	m_missionBusyText.clear();
	m_activeOperation = Operation::None;
	m_activeOperationId = 0;
	if (success) {
		m_missionErrorText.clear();
		if (operation == Operation::Upload ||
			operation == Operation::Download) {
			m_uploadedPlanSignature = m_pendingPlanSignature;
			m_missionRunning = false;
			m_missionPaused = false;
			m_missionFinished = false;
			m_lastProgressCurrent = 0;
			m_lastProgressTotal = 0;
		} else if (operation == Operation::Start ||
			operation == Operation::Restart) {
			m_missionRunning = true;
			m_missionPaused = false;
			m_missionFinished = false;
		} else if (operation == Operation::Pause) {
			m_missionRunning = false;
			m_missionPaused = true;
		} else if (operation == Operation::Clear) {
			resetMissionState();
		}
	} else {
		m_missionErrorText = message;
	}
	m_pendingPlanSignature.clear();
	emit missionStateChanged();
	return true;
}

void DroneMissionController::setError(
	Operation operation, int operationId, const QString& message) {
	if (!isCurrentOperation(operation, operationId)) {
		return;
	}
	m_missionBusy = false;
	m_missionBusyText.clear();
	m_activeOperation = Operation::None;
	m_activeOperationId = 0;
	m_pendingPlanSignature.clear();
	m_missionErrorText = message;
	emit missionStateChanged();
}

bool DroneMissionController::isCurrentOperation(
	Operation operation, int operationId) const {
	return m_activeOperation == operation && m_activeOperationId == operationId;
}

void DroneMissionController::resetMissionState() {
	m_uploadedPlanSignature.clear();
	m_pendingPlanSignature.clear();
	m_missionErrorText.clear();
	m_missionRunning = false;
	m_missionPaused = false;
	m_missionFinished = false;
	m_lastProgressCurrent = 0;
	m_lastProgressTotal = 0;
}

QString DroneMissionController::missionSignatureFor(
	const QVariantList& missionItems, bool returnToLaunchAfterMission,
	bool landAfterMission) {
	if (missionItems.isEmpty()) {
		return {};
	}
	QJsonObject root;
	root.insert("returnHomeAfterMission", returnToLaunchAfterMission);
	root.insert("landAfterMission", landAfterMission);
	root.insert("items", QJsonArray::fromVariantList(missionItems));
	return QString::fromUtf8(
		QJsonDocument(root).toJson(QJsonDocument::Compact));
}

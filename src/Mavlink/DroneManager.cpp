#include "DroneManager.h"

#include <cmath>
#include <string>
#include <utility>

#include <QVariantMap>

namespace {
constexpr double kRatePosition = 10.0;
constexpr double kRateAttitude = 10.0;
constexpr double kRateBattery = 1.0;
constexpr double kRateGpsInfo = 1.0;
constexpr double kRateHealth = 1.0;
constexpr double kRateAltitude = 10.0;
constexpr double kRateVelocity = 10.0;
constexpr double kRateFixedwingMetrics = 10.0;
constexpr double kRateInFlight = 10.0;
constexpr int kReadyBatteryPercent = 20;
constexpr float kDefaultMissionAltitudeM = 50.0F;
constexpr float kDefaultMissionSpeedMS = 8.0F;
constexpr float kDefaultAcceptanceRadiusM = 3.0F;
constexpr double kMinLatitudeDeg = -90.0;
constexpr double kMaxLatitudeDeg = 90.0;
constexpr double kMinLongitudeDeg = -180.0;
constexpr double kMaxLongitudeDeg = 180.0;
constexpr uint16_t kMavCmdDoSetHome = 179;
constexpr float kSetExplicitHome = 0.0F;

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
		missionItems.push_back(item);
	}
	return missionItems;
}
}  // namespace

DroneManager::DroneManager(int uid, QString name, QString url, QObject* parent)
	: QObject(parent),
	  m_uid(uid),
	  m_name(std::move(name)),
	  m_connectionUrl(std::move(url)) {}

DroneManager::~DroneManager() {
	teardownTelemetry();
}

int DroneManager::droneUid() const {
	return m_uid;
}

QString DroneManager::droneName() const {
	return m_name;
}

void DroneManager::setDroneName(const QString& name) {
	if (m_name == name) {
		return;
	}
	m_name = name;
	emit droneNameChanged();
}

QString DroneManager::connectionUrl() const {
	return m_connectionUrl;
}

template <typename T>
void DroneManager::onThread(T&& fn) {
	QMetaObject::invokeMethod(this, std::forward<T>(fn), Qt::QueuedConnection);
}

template <typename M, typename V>
void DroneManager::updateAndEmit(
	M& member, const V& value, void (DroneManager::*signal)()) {
	if (member == value) {
		return;
	}
	member = value;
	(this->*signal)();
}

void DroneManager::setConnecting(bool connecting) {
	if (m_connecting == connecting) {
		return;
	}
	m_connecting = connecting;
	emit connectingChanged();
}

void DroneManager::attachSystem(const std::shared_ptr<mavsdk::System>& system) {
	if (!system) {
		return;
	}

	m_system = system;
	m_telemetry = std::make_unique<mavsdk::Telemetry>(system);
	m_action = std::make_unique<mavsdk::Action>(system);
	m_mission = std::make_unique<mavsdk::Mission>(system);
	m_mavlinkPassthrough = std::make_unique<mavsdk::MavlinkPassthrough>(system);

	m_missionProgressHandle = m_mission->subscribe_mission_progress(
		[this](mavsdk::Mission::MissionProgress progress) {
			onThread([this, progress]() {
				updateAndEmit(m_wpCurrent, static_cast<int>(progress.current),
					&DroneManager::wpCurrentChanged);
				updateAndEmit(m_wpTotal, static_cast<int>(progress.total),
					&DroneManager::wpTotalChanged);
			});
		});

	setConnecting(false);

	setupTelemetry();

	emit connectedChanged();
	emit logMessage(m_name, "System attached", "info");
}

void DroneManager::detachSystem() {
	teardownTelemetry();

	if (m_mission && m_missionProgressHandle.valid()) {
		m_mission->unsubscribe_mission_progress(m_missionProgressHandle);
		m_missionProgressHandle = {};
	}
	m_mavlinkPassthrough.reset();
	m_mission.reset();
	m_action.reset();
	m_telemetry.reset();
	m_system.reset();

	setConnecting(false);
	updateAndEmit(m_armed, false, &DroneManager::armedChanged);
	updateAndEmit(m_inFlight, false, &DroneManager::inFlightChanged);
	updateAndEmit(
		m_flightMode, QString("STBY"), &DroneManager::flightModeChanged);
	updateAndEmit(m_sensorImu, false, &DroneManager::sensorImuChanged);
	updateAndEmit(m_sensorGps, false, &DroneManager::sensorGpsChanged);
	updateAndEmit(m_sensorBaro, false, &DroneManager::sensorBaroChanged);
	updateAndEmit(m_sensorMag, false, &DroneManager::sensorMagChanged);

	emit connectedChanged();
	updateReadyToFly();
}

bool DroneManager::isConnected() const {
	return m_system && m_system->is_connected();
}

bool DroneManager::isConnecting() const {
	return m_connecting;
}

bool DroneManager::isArmed() const {
	return m_armed;
}
bool DroneManager::isInFlight() const {
	return m_inFlight;
}
QString DroneManager::flightMode() const {
	return m_flightMode;
}

bool DroneManager::isReadyToFly() const {
	return m_sensorImu && m_sensorGps && m_battery > kReadyBatteryPercent;
}

bool DroneManager::sensorImu() const {
	return m_sensorImu;
}
bool DroneManager::sensorGps() const {
	return m_sensorGps;
}
bool DroneManager::sensorBaro() const {
	return m_sensorBaro;
}
bool DroneManager::sensorMag() const {
	return m_sensorMag;
}

double DroneManager::roll() const {
	return m_roll;
}
double DroneManager::pitch() const {
	return m_pitch;
}
double DroneManager::yaw() const {
	return m_yaw;
}
double DroneManager::altitude() const {
	return m_altitude;
}
double DroneManager::altitudeMsl() const {
	return m_altitudeMsl;
}
double DroneManager::airspeed() const {
	return m_airspeed;
}
double DroneManager::groundspeed() const {
	return m_groundspeed;
}
double DroneManager::climbRate() const {
	return m_climbRate;
}
int DroneManager::throttle() const {
	return m_throttle;
}
double DroneManager::heading() const {
	return m_heading;
}
double DroneManager::latitude() const {
	return m_latitude;
}
double DroneManager::longitude() const {
	return m_longitude;
}

double DroneManager::homeLatitude() const {
	return m_homeLatitude;
}

double DroneManager::homeLongitude() const {
	return m_homeLongitude;
}

double DroneManager::homeAltitude() const {
	return m_homeAltitude;
}

bool DroneManager::homeValid() const {
	return m_homeValid;
}

double DroneManager::voltage() const {
	return m_voltage;
}
double DroneManager::current() const {
	return m_current;
}
int DroneManager::battery() const {
	return m_battery;
}

int DroneManager::wpCurrent() const {
	return m_wpCurrent;
}
int DroneManager::wpTotal() const {
	return m_wpTotal;
}
double DroneManager::wpDist() const {
	return m_wpDist;
}

int DroneManager::ping() const {
	return m_ping;
}
double DroneManager::cpuLoad() const {
	return m_cpuLoad;
}

void DroneManager::arm() {
	if (!m_action) {
		emit logMessage(m_name, "Cannot arm: not connected", "warning");
		return;
	}
	m_action->arm_async([this](mavsdk::Action::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Action::Result::Success) {
				emit logMessage(m_name, "Armed", "info");
			} else {
				emit logMessage(m_name,
					QString("Arm failed: %1")
						.arg(QString::fromStdString(
							std::string(to_string(result)))),
					"error");
			}
		});
	});
}

void DroneManager::disarm() {
	if (!m_action) {
		emit logMessage(m_name, "Cannot disarm: not connected", "warning");
		return;
	}
	m_action->disarm_async([this](mavsdk::Action::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Action::Result::Success) {
				emit logMessage(m_name, "Disarmed", "info");
			} else {
				emit logMessage(m_name,
					QString("Disarm failed: %1")
						.arg(QString::fromStdString(
							std::string(to_string(result)))),
					"error");
			}
		});
	});
}

void DroneManager::takeoff() {
	if (!m_action) {
		emit logMessage(m_name, "Cannot takeoff: not connected", "warning");
		return;
	}
	m_action->takeoff_async([this](mavsdk::Action::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Action::Result::Success) {
				emit logMessage(m_name, "Takeoff command sent", "info");
			} else {
				emit logMessage(m_name,
					QString("Takeoff failed: %1")
						.arg(QString::fromStdString(
							std::string(to_string(result)))),
					"error");
			}
		});
	});
}

void DroneManager::land() {
	if (!m_action) {
		emit logMessage(m_name, "Cannot land: not connected", "warning");
		return;
	}
	m_action->land_async([this](mavsdk::Action::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Action::Result::Success) {
				emit logMessage(m_name, "Land command sent", "info");
			} else {
				emit logMessage(m_name,
					QString("Land failed: %1")
						.arg(QString::fromStdString(
							std::string(to_string(result)))),
					"error");
			}
		});
	});
}

void DroneManager::rth() {
	if (!m_action) {
		emit logMessage(m_name, "Cannot RTH: not connected", "warning");
		return;
	}
	m_action->return_to_launch_async([this](mavsdk::Action::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Action::Result::Success) {
				emit logMessage(m_name, "RTH command sent", "info");
			} else {
				emit logMessage(m_name,
					QString("RTH failed: %1")
						.arg(QString::fromStdString(
							std::string(to_string(result)))),
					"error");
			}
		});
	});
}

void DroneManager::setAltitude(double altitudeMeters) {
	if (!m_action) {
		emit logMessage(
			m_name, "Cannot set altitude: not connected", "warning");
		return;
	}
	if (!isConnected()) {
		emit logMessage(
			m_name, "Cannot set altitude: no system connection", "warning");
		return;
	}

	const double absoluteAlt = m_altitudeMsl + (altitudeMeters - m_altitude);
	m_action->goto_location_async(m_latitude, m_longitude,
		static_cast<float>(absoluteAlt), static_cast<float>(m_heading),
		[this](mavsdk::Action::Result result) {
			onThread([this, result]() {
				if (result == mavsdk::Action::Result::Success) {
					emit logMessage(m_name, "Altitude target sent", "info");
				} else {
					emit logMessage(m_name,
						QString("Set altitude failed: %1")
							.arg(QString::fromStdString(
								std::string(to_string(result)))),
						"error");
				}
			});
		});
}

void DroneManager::uploadMission(
	const QVariantList& missionItems, bool returnToLaunchAfterMission) {
	if (!m_mission) {
		const QString message = "Cannot upload mission: not connected";
		emit logMessage(m_name, message, "warning");
		emit missionUploadFinished(false, message);
		return;
	}
	if (missionItems.size() < 2) {
		const QString message =
			"Cannot upload mission: add at least 2 waypoints";
		emit logMessage(m_name, message, "warning");
		emit missionUploadFinished(false, message);
		return;
	}

	mavsdk::Mission::MissionPlan plan;
	plan.mission_items.reserve(static_cast<size_t>(missionItems.size()));
	for (const QVariant& value : missionItems) {
		const QVariantMap item = value.toMap();
		const double latitude = item.value("latitude").toDouble();
		const double longitude = item.value("longitude").toDouble();
		if (latitude < kMinLatitudeDeg || latitude > kMaxLatitudeDeg ||
			longitude < kMinLongitudeDeg || longitude > kMaxLongitudeDeg) {
			const QString message = "Cannot upload mission: invalid waypoint";
			emit logMessage(m_name, message, "warning");
			emit missionUploadFinished(false, message);
			return;
		}

		mavsdk::Mission::MissionItem missionItem{};
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
		missionItem.camera_action =
			mavsdk::Mission::MissionItem::CameraAction::None;
		missionItem.vehicle_action =
			mavsdk::Mission::MissionItem::VehicleAction::None;
		plan.mission_items.push_back(missionItem);
	}

	m_mission->set_return_to_launch_after_mission(returnToLaunchAfterMission);
	m_mission->upload_mission_async(
		plan, [this](mavsdk::Mission::Result result) {
			onThread([this, result]() {
				if (result == mavsdk::Mission::Result::Success) {
					emit logMessage(m_name, "Mission uploaded", "info");
					emit missionUploadFinished(true, "Mission uploaded");
				} else {
					const QString message =
						QString("Mission upload failed: %1")
							.arg(missionResultString(result));
					emit logMessage(m_name, message, "error");
					emit missionUploadFinished(false, message);
				}
			});
		});
}

void DroneManager::startMission() {
	if (!m_mission) {
		const QString message = "Cannot start mission: not connected";
		emit logMessage(m_name, message, "warning");
		emit missionStartFinished(false, message);
		return;
	}
	m_mission->start_mission_async([this](mavsdk::Mission::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Mission::Result::Success) {
				emit logMessage(m_name, "Mission started", "info");
				emit missionStartFinished(true, "Mission started");
			} else {
				const QString message = QString("Mission start failed: %1")
											.arg(missionResultString(result));
				emit logMessage(m_name, message, "error");
				emit missionStartFinished(false, message);
			}
		});
	});
}

void DroneManager::pauseMission() {
	if (!m_mission) {
		const QString message = "Cannot pause mission: not connected";
		emit logMessage(m_name, message, "warning");
		emit missionPauseFinished(false, message);
		return;
	}
	m_mission->pause_mission_async([this](mavsdk::Mission::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Mission::Result::Success) {
				emit logMessage(m_name, "Mission paused", "info");
				emit missionPauseFinished(true, "Mission paused");
			} else {
				const QString message = QString("Mission pause failed: %1")
											.arg(missionResultString(result));
				emit logMessage(m_name, message, "error");
				emit missionPauseFinished(false, message);
			}
		});
	});
}

void DroneManager::clearMission() {
	if (!m_mission) {
		const QString message = "Cannot clear mission: not connected";
		emit logMessage(m_name, message, "warning");
		emit missionClearFinished(false, message);
		return;
	}
	m_mission->clear_mission_async([this](mavsdk::Mission::Result result) {
		onThread([this, result]() {
			if (result == mavsdk::Mission::Result::Success) {
				updateAndEmit(m_wpCurrent, 0, &DroneManager::wpCurrentChanged);
				updateAndEmit(m_wpTotal, 0, &DroneManager::wpTotalChanged);
				emit logMessage(m_name, "Mission cleared", "info");
				emit missionClearFinished(true, "Mission cleared");
			} else {
				const QString message = QString("Mission clear failed: %1")
											.arg(missionResultString(result));
				emit logMessage(m_name, message, "error");
				emit missionClearFinished(false, message);
			}
		});
	});
}

void DroneManager::downloadMission() {
	if (!m_mission) {
		const QString message = "Cannot download mission: not connected";
		emit logMessage(m_name, message, "warning");
		emit missionDownloadFinished(false, message, {}, false);
		return;
	}
	m_mission->download_mission_async(
		[this](mavsdk::Mission::Result result,
			const mavsdk::Mission::MissionPlan& plan) {
			auto returnToLaunch =
				m_mission->get_return_to_launch_after_mission();
			onThread([this, result, plan, returnToLaunch]() {
				if (result == mavsdk::Mission::Result::Success) {
					const QVariantList missionItems =
						missionPlanToVariantList(plan);
					const bool rtl =
						returnToLaunch.first == mavsdk::Mission::Result::Success
						? returnToLaunch.second
						: false;
					emit logMessage(m_name, "Mission downloaded", "info");
					emit missionDownloadFinished(
						true, "Mission downloaded", missionItems, rtl);
				} else {
					const QString message =
						QString("Mission download failed: %1")
							.arg(missionResultString(result));
					emit logMessage(m_name, message, "error");
					emit missionDownloadFinished(false, message, {}, false);
				}
			});
		});
}

void DroneManager::setHome(double latitude, double longitude, double altitude) {
	if (!m_mavlinkPassthrough) {
		emit logMessage(m_name, "Cannot set home: not connected", "warning");
		return;
	}
	if (latitude < kMinLatitudeDeg || latitude > kMaxLatitudeDeg ||
		longitude < kMinLongitudeDeg || longitude > kMaxLongitudeDeg) {
		emit logMessage(
			m_name, "Cannot set home: invalid coordinate", "warning");
		return;
	}

	mavsdk::MavlinkPassthrough::CommandLong command{};
	command.target_sysid = m_mavlinkPassthrough->get_target_sysid();
	command.target_compid = m_mavlinkPassthrough->get_target_compid();
	command.command = kMavCmdDoSetHome;
	command.param1 = kSetExplicitHome;
	command.param5 = static_cast<float>(latitude);
	command.param6 = static_cast<float>(longitude);
	command.param7 = static_cast<float>(altitude);

	const auto result = m_mavlinkPassthrough->send_command_long(command);
	if (result == mavsdk::MavlinkPassthrough::Result::Success) {
		updateAndEmit(m_homeLatitude, latitude, &DroneManager::homeChanged);
		updateAndEmit(m_homeLongitude, longitude, &DroneManager::homeChanged);
		updateAndEmit(m_homeAltitude, altitude, &DroneManager::homeChanged);
		updateAndEmit(m_homeValid, true, &DroneManager::homeChanged);
		emit logMessage(m_name, "Home point set", "info");
	} else {
		emit logMessage(m_name, "Set home failed", "error");
	}
}

void DroneManager::log(
	const QString& source, const QString& message, const QString& level) {
	emit logMessage(source, message, level);
}

void DroneManager::setupTelemetry() {
	if (!m_telemetry || !m_system) {
		return;
	}

	m_telemetry->set_rate_position(kRatePosition);
	m_telemetry->set_rate_attitude_euler(kRateAttitude);
	m_telemetry->set_rate_battery(kRateBattery);
	m_telemetry->set_rate_gps_info(kRateGpsInfo);
	m_telemetry->set_rate_health(kRateHealth);
	m_telemetry->set_rate_altitude(kRateAltitude);
	m_telemetry->set_rate_velocity_ned(kRateVelocity);
	m_telemetry->set_rate_fixedwing_metrics(kRateFixedwingMetrics);
	m_telemetry->set_rate_in_air(kRateInFlight);
	m_telemetry->set_rate_home(1.0);

	m_positionHandle = m_telemetry->subscribe_position(
		[this](mavsdk::Telemetry::Position pos) {
			onThread([this, pos]() {
				updateAndEmit(m_latitude, pos.latitude_deg,
					&DroneManager::latitudeChanged);
				updateAndEmit(m_longitude, pos.longitude_deg,
					&DroneManager::longitudeChanged);
				updateAndEmit(m_altitude, pos.relative_altitude_m,
					&DroneManager::altitudeChanged);
				updateAndEmit(m_altitudeMsl, pos.absolute_altitude_m,
					&DroneManager::altitudeMslChanged);
			});
		});

	m_attitudeEulerHandle = m_telemetry->subscribe_attitude_euler(
		[this](mavsdk::Telemetry::EulerAngle euler) {
			onThread([this, euler]() {
				updateAndEmit(
					m_roll, euler.roll_deg, &DroneManager::rollChanged);
				updateAndEmit(
					m_pitch, euler.pitch_deg, &DroneManager::pitchChanged);
				updateAndEmit(m_yaw, euler.yaw_deg, &DroneManager::yawChanged);
			});
		});

	m_headingHandle =
		m_telemetry->subscribe_heading([this](mavsdk::Telemetry::Heading hdg) {
			onThread([this, hdg]() {
				updateAndEmit(
					m_heading, hdg.heading_deg, &DroneManager::headingChanged);
			});
		});

	m_batteryHandle =
		m_telemetry->subscribe_battery([this](mavsdk::Telemetry::Battery bat) {
			onThread([this, bat]() {
				updateAndEmit(
					m_voltage, bat.voltage_v, &DroneManager::voltageChanged);
				updateAndEmit(m_current, bat.current_battery_a,
					&DroneManager::currentChanged);
				double remaining = bat.remaining_percent;
				auto pct = static_cast<int>(
					remaining <= 1.0 ? remaining * 100.0 : remaining);
				if (m_battery != pct) {
					m_battery = pct;
					emit batteryChanged();
					updateReadyToFly();
				}
			});
		});

	m_armedHandle = m_telemetry->subscribe_armed([this](bool armed) {
		onThread([this, armed]() {
			updateAndEmit(m_armed, armed, &DroneManager::armedChanged);
		});
	});

	m_inAirHandle = m_telemetry->subscribe_in_air([this](bool inAir) {
		onThread([this, inAir]() {
			updateAndEmit(m_inFlight, inAir, &DroneManager::inFlightChanged);
		});
	});

	m_flightModeHandle = m_telemetry->subscribe_flight_mode(
		[this](mavsdk::Telemetry::FlightMode mode) {
			onThread([this, mode]() {
				auto str = flightModeToString(mode);
				updateAndEmit(
					m_flightMode, str, &DroneManager::flightModeChanged);
			});
		});

	m_healthHandle =
		m_telemetry->subscribe_health([this](mavsdk::Telemetry::Health health) {
			onThread([this, health]() {
				bool imu = health.is_gyrometer_calibration_ok &&
					health.is_accelerometer_calibration_ok;
				bool gps = health.is_global_position_ok;
				bool baro = health.is_local_position_ok;
				bool mag = health.is_magnetometer_calibration_ok;

				updateAndEmit(
					m_sensorImu, imu, &DroneManager::sensorImuChanged);
				updateAndEmit(
					m_sensorGps, gps, &DroneManager::sensorGpsChanged);
				updateAndEmit(
					m_sensorBaro, baro, &DroneManager::sensorBaroChanged);
				updateAndEmit(
					m_sensorMag, mag, &DroneManager::sensorMagChanged);
				updateReadyToFly();
			});
		});

	m_gpsInfoHandle = m_telemetry->subscribe_gps_info(
		[this](mavsdk::Telemetry::GpsInfo info) {
			onThread([this, info]() {
				bool hasFix =
					info.fix_type >= mavsdk::Telemetry::FixType::Fix3D;
				if (m_sensorGps != hasFix) {
					m_sensorGps = hasFix;
					emit sensorGpsChanged();
					updateReadyToFly();
				}
			});
		});

	m_velocityNedHandle = m_telemetry->subscribe_velocity_ned(
		[this](mavsdk::Telemetry::VelocityNed vel) {
			onThread([this, vel]() {
				double gs = std::sqrt((vel.north_m_s * vel.north_m_s) +
					(vel.east_m_s * vel.east_m_s));
				updateAndEmit(
					m_groundspeed, gs, &DroneManager::groundspeedChanged);
				double climb = -vel.down_m_s;
				updateAndEmit(
					m_climbRate, climb, &DroneManager::climbRateChanged);
			});
		});

	m_fixedwingMetricsHandle = m_telemetry->subscribe_fixedwing_metrics(
		[this](mavsdk::Telemetry::FixedwingMetrics fw) {
			onThread([this, fw]() {
				if (!std::isnan(fw.airspeed_m_s)) {
					updateAndEmit(m_airspeed, fw.airspeed_m_s,
						&DroneManager::airspeedChanged);
				}
				if (!std::isnan(fw.throttle_percentage)) {
					updateAndEmit(m_throttle,
						static_cast<int>(fw.throttle_percentage),
						&DroneManager::throttleChanged);
				}
			});
		});

	m_homeHandle = m_telemetry->subscribe_home(
		[this](mavsdk::Telemetry::HomePosition home) {
			onThread([this, home]() {
				if (std::isnan(home.latitude_deg) ||
					std::isnan(home.longitude_deg)) {
					return;
				}
				updateAndEmit(m_homeLatitude, home.latitude_deg,
					&DroneManager::homeChanged);
				updateAndEmit(m_homeLongitude, home.longitude_deg,
					&DroneManager::homeChanged);
				updateAndEmit(m_homeAltitude, home.absolute_altitude_m,
					&DroneManager::homeChanged);
				updateAndEmit(m_homeValid, true, &DroneManager::homeChanged);
			});
		});

	{
		bool armed = m_telemetry->armed();
		bool inAir = m_telemetry->in_air();
		QString mode = flightModeToString(m_telemetry->flight_mode());
		auto position = m_telemetry->position();
		auto hdg = m_telemetry->heading();

		updateAndEmit(m_armed, armed, &DroneManager::armedChanged);
		updateAndEmit(m_inFlight, inAir, &DroneManager::inFlightChanged);
		updateAndEmit(m_flightMode, mode, &DroneManager::flightModeChanged);

		updateAndEmit(
			m_latitude, position.latitude_deg, &DroneManager::latitudeChanged);
		updateAndEmit(m_longitude, position.longitude_deg,
			&DroneManager::longitudeChanged);
		updateAndEmit(m_altitude, position.relative_altitude_m,
			&DroneManager::altitudeChanged);
		updateAndEmit(m_altitudeMsl, position.absolute_altitude_m,
			&DroneManager::altitudeMslChanged);
		updateAndEmit(
			m_heading, hdg.heading_deg, &DroneManager::headingChanged);
	}

	m_isConnectedHandle = m_system->subscribe_is_connected([this](
															   bool connected) {
		onThread([this, connected]() {
			emit logMessage(m_name, connected ? "Connected" : "Disconnected",
				connected ? "info" : "warning");
			emit connectedChanged();
		});
	});
}

void DroneManager::teardownTelemetry() {
	if (m_mission && m_missionProgressHandle.valid()) {
		m_mission->unsubscribe_mission_progress(m_missionProgressHandle);
		m_missionProgressHandle = {};
	}
	if (m_telemetry) {
		if (m_positionHandle.valid()) {
			m_telemetry->unsubscribe_position(m_positionHandle);
			m_positionHandle = {};
		}
		if (m_attitudeEulerHandle.valid()) {
			m_telemetry->unsubscribe_attitude_euler(m_attitudeEulerHandle);
			m_attitudeEulerHandle = {};
		}
		if (m_headingHandle.valid()) {
			m_telemetry->unsubscribe_heading(m_headingHandle);
			m_headingHandle = {};
		}
		if (m_batteryHandle.valid()) {
			m_telemetry->unsubscribe_battery(m_batteryHandle);
			m_batteryHandle = {};
		}
		if (m_armedHandle.valid()) {
			m_telemetry->unsubscribe_armed(m_armedHandle);
			m_armedHandle = {};
		}
		if (m_inAirHandle.valid()) {
			m_telemetry->unsubscribe_in_air(m_inAirHandle);
			m_inAirHandle = {};
		}
		if (m_flightModeHandle.valid()) {
			m_telemetry->unsubscribe_flight_mode(m_flightModeHandle);
			m_flightModeHandle = {};
		}
		if (m_healthHandle.valid()) {
			m_telemetry->unsubscribe_health(m_healthHandle);
			m_healthHandle = {};
		}
		if (m_gpsInfoHandle.valid()) {
			m_telemetry->unsubscribe_gps_info(m_gpsInfoHandle);
			m_gpsInfoHandle = {};
		}
		if (m_velocityNedHandle.valid()) {
			m_telemetry->unsubscribe_velocity_ned(m_velocityNedHandle);
			m_velocityNedHandle = {};
		}
		if (m_fixedwingMetricsHandle.valid()) {
			m_telemetry->unsubscribe_fixedwing_metrics(
				m_fixedwingMetricsHandle);
			m_fixedwingMetricsHandle = {};
		}
		if (m_homeHandle.valid()) {
			m_telemetry->unsubscribe_home(m_homeHandle);
			m_homeHandle = {};
		}
	}
	if (m_system && m_isConnectedHandle.valid()) {
		m_system->unsubscribe_is_connected(m_isConnectedHandle);
		m_isConnectedHandle = {};
	}
}

void DroneManager::updateReadyToFly() {
	emit readyToFlyChanged();
}

QString DroneManager::flightModeToString(mavsdk::Telemetry::FlightMode mode) {
	switch (mode) {
		case mavsdk::Telemetry::FlightMode::Ready:
			return "READY";
		case mavsdk::Telemetry::FlightMode::Takeoff:
			return "TAKEOFF";
		case mavsdk::Telemetry::FlightMode::Hold:
			return "HOLD";
		case mavsdk::Telemetry::FlightMode::Mission:
			return "MISSION";
		case mavsdk::Telemetry::FlightMode::ReturnToLaunch:
			return "RTL";
		case mavsdk::Telemetry::FlightMode::Land:
			return "LAND";
		case mavsdk::Telemetry::FlightMode::Offboard:
			return "OFFBOARD";
		case mavsdk::Telemetry::FlightMode::FollowMe:
			return "FOLLOW_ME";
		case mavsdk::Telemetry::FlightMode::Manual:
			return "MANUAL";
		case mavsdk::Telemetry::FlightMode::Altctl:
			return "ALTCTL";
		case mavsdk::Telemetry::FlightMode::Posctl:
			return "POSCTL";
		case mavsdk::Telemetry::FlightMode::Acro:
			return "ACRO";
		case mavsdk::Telemetry::FlightMode::Stabilized:
			return "STABILIZED";
		case mavsdk::Telemetry::FlightMode::Rattitude:
			return "RATTITUDE";
		default:
			return "UNKNOWN";
	}
}

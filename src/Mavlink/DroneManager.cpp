#include "DroneManager.h"

#include "DroneMissionController.h"
#include "MissionPlanModel.h"

#include <cmath>
#include <utility>

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
constexpr double kMinLatitudeDeg = -90.0;
constexpr double kMaxLatitudeDeg = 90.0;
constexpr double kMinLongitudeDeg = -180.0;
constexpr double kMaxLongitudeDeg = 180.0;
constexpr uint16_t kMavCmdDoSetHome = 179;
constexpr float kSetExplicitHome = 0.0F;
}  // namespace

DroneManager::DroneManager(int uid, QString name, QString url, QObject* parent)
	: QObject(parent),
	  m_uid(uid),
	  m_name(std::move(name)),
	  m_connectionUrl(std::move(url)),
	  m_missionPlan(std::make_unique<MissionPlanModel>(this)),
	  m_missionController(
		  std::make_unique<DroneMissionController>(m_name, this)) {
	connect(m_missionController.get(), &DroneMissionController::logMessage,
		this, &DroneManager::logMessage);
	connect(m_missionController.get(),
		&DroneMissionController::missionUploadFinished, this,
		&DroneManager::missionUploadFinished);
	connect(m_missionController.get(),
		&DroneMissionController::missionStartFinished, this,
		&DroneManager::missionStartFinished);
	connect(m_missionController.get(),
		&DroneMissionController::missionPauseFinished, this,
		&DroneManager::missionPauseFinished);
	connect(m_missionController.get(),
		&DroneMissionController::missionClearFinished, this,
		&DroneManager::missionClearFinished);
	connect(m_missionController.get(),
		&DroneMissionController::missionDownloadFinished, this,
		&DroneManager::missionDownloadFinished);
	connect(m_missionController.get(),
		&DroneMissionController::missionStateChanged, this,
		&DroneManager::missionStateChanged);
	connect(m_missionPlan.get(), &MissionPlanModel::signatureChanged, this,
		&DroneManager::missionStateChanged);
	connect(m_missionController.get(),
		&DroneMissionController::missionProgressChanged, this,
		[this](int current, int total) {
			updateAndEmit(
				m_wpCurrent, current, &DroneManager::wpCurrentChanged);
			updateAndEmit(m_wpTotal, total, &DroneManager::wpTotalChanged);
		});
}

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
	m_missionController->setDroneName(m_name);
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
	m_missionController->attachSystem(system);
	m_mavlinkPassthrough = std::make_unique<mavsdk::MavlinkPassthrough>(system);

	setConnecting(false);

	setupTelemetry();

	emit connectedChanged();
	emit logMessage(m_name, "System attached", "info");
}

void DroneManager::detachSystem() {
	teardownTelemetry();

	m_missionController->detachSystem();
	m_mavlinkPassthrough.reset();
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

MissionPlanModel* DroneManager::missionPlan() const {
	return m_missionPlan.get();
}

bool DroneManager::missionBusy() const {
	return m_missionController->missionBusy();
}

QString DroneManager::missionBusyText() const {
	return m_missionController->missionBusyText();
}

bool DroneManager::missionRunning() const {
	return m_missionController->missionRunning();
}

bool DroneManager::missionPaused() const {
	return m_missionController->missionPaused();
}

bool DroneManager::missionUploaded() const {
	return m_missionController->missionUploaded(m_missionPlan->signature());
}

bool DroneManager::missionDirty() const {
	return m_missionController->missionDirty(m_missionPlan->signature());
}

QString DroneManager::missionErrorText() const {
	return m_missionController->missionErrorText();
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

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
void DroneManager::goToLocation(double latitude, double longitude,
	double altitudeMeters, double headingDegrees) {
	if (!m_action) {
		emit logMessage(
			m_name, "Cannot go to location: not connected", "warning");
		return;
	}
	if (!isConnected()) {
		emit logMessage(
			m_name, "Cannot go to location: no system connection", "warning");
		return;
	}
	if (latitude < kMinLatitudeDeg || latitude > kMaxLatitudeDeg ||
		longitude < kMinLongitudeDeg || longitude > kMaxLongitudeDeg) {
		emit logMessage(
			m_name, "Cannot go to location: invalid coordinate", "warning");
		return;
	}

	const double heading =
		std::fmod(std::fmod(headingDegrees, 360.0) + 360.0, 360.0);
	const double absoluteAlt = m_altitudeMsl + (altitudeMeters - m_altitude);
	m_action->goto_location_async(latitude, longitude,
		static_cast<float>(absoluteAlt), static_cast<float>(heading),
		[this](mavsdk::Action::Result result) {
			onThread([this, result]() {
				if (result == mavsdk::Action::Result::Success) {
					emit logMessage(m_name, "Go Here command sent", "info");
				} else {
					emit logMessage(m_name,
						QString("Go Here failed: %1")
							.arg(QString::fromStdString(
								std::string(to_string(result)))),
						"error");
				}
			});
		});
}

void DroneManager::uploadMission(
	const QVariantList& missionItems, bool returnToLaunchAfterMission) {
	m_missionController->uploadMission(
		missionItems, returnToLaunchAfterMission, m_missionPlan->signature());
}

void DroneManager::startMission() {
	m_missionController->startMission();
}

void DroneManager::pauseMission() {
	m_missionController->pauseMission();
}

void DroneManager::clearMission() {
	m_missionController->clearMission();
}

void DroneManager::downloadMission() {
	m_missionController->downloadMission();
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

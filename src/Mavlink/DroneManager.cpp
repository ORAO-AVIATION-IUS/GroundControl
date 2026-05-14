#include "DroneManager.h"

#include <QDebug>

#include <mavsdk/mavsdk.hpp>
#include <mavsdk/plugins/action/action.hpp>
#include <mavsdk/plugins/telemetry/telemetry.hpp>

#include <cmath>
#include <string>
#include <thread>

using namespace mavsdk;

namespace {

QString resultToString(ConnectionResult r) {
	return QString::fromStdString(std::string(to_string(r)));
}

QString resultToString(Action::Result r) {
	return QString::fromStdString(std::string(to_string(r)));
}

QString flightModeStr(Telemetry::FlightMode mode) {
	return QString::fromStdString(std::string(to_string(mode)));
}

}  // namespace

DroneManager::DroneManager(QObject* parent) : QObject(parent) {}

DroneManager::~DroneManager() {
	disconnect();
}

void DroneManager::connectToDrone(const QString& url) {
	if (m_connected) {
		emit error(tr("Already connected — disconnect first"));
		return;
	}

	m_connectionStatus = tr("Connecting to %1…").arg(url);
	emit connectionStatusChanged();

	std::thread([this, url]() {
		auto mavsdk = std::make_unique<Mavsdk>(
			Mavsdk::Configuration{ComponentType::GroundStation});

		auto result = mavsdk->add_any_connection(url.toStdString());
		if (result != ConnectionResult::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					m_connectionStatus = tr("Connection failed: %1").arg(msg);
					emit connectionStatusChanged();
					emit error(m_connectionStatus);
				},
				Qt::QueuedConnection);
			return;
		}

		auto system = mavsdk->first_autopilot(10.0);
		if (!system) {
			QMetaObject::invokeMethod(
				this,
				[this]() {
					m_connectionStatus =
						tr("Timed out waiting for system");
					emit connectionStatusChanged();
					emit error(m_connectionStatus);
				},
				Qt::QueuedConnection);
			return;
		}

		auto* raw = mavsdk.release();
		auto sys = system.value();
		QMetaObject::invokeMethod(
			this,
			[this, sys, raw]() {
				m_mavsdk.reset(raw);
				m_system = sys;
				setupSystem(sys);
			},
			Qt::QueuedConnection);
	}).detach();
}

void DroneManager::disconnect() {
	m_telemetry.reset();
	m_action.reset();
	m_system.reset();
	m_mavsdk.reset();
	resetTelemetry();

	m_connected = false;
	m_connectionStatus = tr("Disconnected");
	m_armed = false;
	m_flightMode.clear();
	m_inAir = false;

	emit connectedChanged();
	emit connectionStatusChanged();
	emit armedChanged();
	emit flightModeChanged();
	emit inAirChanged();
}

void DroneManager::setupSystem(std::shared_ptr<System> system) {
	m_telemetry = std::make_unique<Telemetry>(system);
	m_action = std::make_unique<Action>(system);

	m_telemetry->set_rate_attitude_euler(10.0);
	m_telemetry->set_rate_position(10.0);
	m_telemetry->set_rate_velocity_ned(10.0);
	m_telemetry->set_rate_battery(1.0);
	m_telemetry->set_rate_in_air(10.0);
	m_telemetry->set_rate_imu(10.0);

	m_telemetry->subscribe_attitude_euler([this](Telemetry::EulerAngle a) {
		m_roll = a.roll_deg;
		m_pitch = a.pitch_deg;
		emit attitudeChanged();
	});

	m_telemetry->subscribe_heading([this](Telemetry::Heading h) {
		m_heading = h.heading_deg;
		emit headingChanged();
	});

	m_telemetry->subscribe_position([this](Telemetry::Position p) {
		m_latitude = p.latitude_deg;
		m_longitude = p.longitude_deg;
		m_absoluteAltitude = p.absolute_altitude_m;
		m_altitude = p.relative_altitude_m;
		emit positionChanged();
		emit altitudeChanged();
	});

	m_telemetry->subscribe_velocity_ned([this](Telemetry::VelocityNed v) {
		m_groundSpeed =
			std::sqrt(v.north_m_s * v.north_m_s +
					  v.east_m_s * v.east_m_s);
		m_verticalSpeed = -v.down_m_s;
		emit speedChanged();
	});

	m_telemetry->subscribe_battery([this](Telemetry::Battery b) {
		m_batteryPercent = b.remaining_percent;
		m_batteryVoltage = b.voltage_v;
		emit batteryChanged();
	});

	m_telemetry->subscribe_armed([this](bool armed) {
		m_armed = armed;
		emit armedChanged();
	});

	m_telemetry->subscribe_flight_mode(
		[this](Telemetry::FlightMode mode) {
			m_flightMode = flightModeStr(mode);
			emit flightModeChanged();
		});

	m_telemetry->subscribe_in_air([this](bool inAir) {
		m_inAir = inAir;
		emit inAirChanged();
	});

	m_telemetry->subscribe_attitude_angular_velocity_body(
		[this](Telemetry::AngularVelocityBody a) {
			m_yawspeed = a.yaw_rad_s;
			emit yawspeedChanged();
		});

	m_telemetry->subscribe_imu([this](Telemetry::Imu i) {
		m_yacc = i.acceleration_frd.right_m_s2 / 9.81;
		emit yaccChanged();
	});

	m_connected = true;
	m_connectionStatus = tr("Connected");
	emit connectedChanged();
	emit connectionStatusChanged();
	qInfo() << "Drone connected";
}

void DroneManager::resetTelemetry() {
	m_latitude = 0.0;
	m_longitude = 0.0;
	m_absoluteAltitude = 0.0;
	m_roll = 0.0;
	m_pitch = 0.0;
	m_heading = 0.0;
	m_altitude = 0.0;
	m_groundSpeed = 0.0;
	m_verticalSpeed = 0.0;
	m_batteryPercent = 0.0;
	m_batteryVoltage = 0.0;
	m_yawspeed = 0.0;
	m_yacc = 0.0;

	emit positionChanged();
	emit attitudeChanged();
	emit headingChanged();
	emit altitudeChanged();
	emit speedChanged();
	emit batteryChanged();
	emit yawspeedChanged();
	emit yaccChanged();
}

void DroneManager::arm() {
	if (!m_action) return;
	std::thread([this]() {
		auto result = m_action->arm();
		if (result != Action::Result::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					emit error(tr("Arm failed: %1").arg(msg));
				},
				Qt::QueuedConnection);
		}
	}).detach();
}

void DroneManager::disarm() {
	if (!m_action) return;
	std::thread([this]() {
		auto result = m_action->disarm();
		if (result != Action::Result::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					emit error(tr("Disarm failed: %1").arg(msg));
				},
				Qt::QueuedConnection);
		}
	}).detach();
}

void DroneManager::takeoff() {
	if (!m_action) return;
	std::thread([this]() {
		auto result = m_action->takeoff();
		if (result != Action::Result::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					emit error(tr("Takeoff failed: %1").arg(msg));
				},
				Qt::QueuedConnection);
		}
	}).detach();
}

void DroneManager::land() {
	if (!m_action) return;
	std::thread([this]() {
		auto result = m_action->land();
		if (result != Action::Result::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					emit error(tr("Land failed: %1").arg(msg));
				},
				Qt::QueuedConnection);
		}
	}).detach();
}

void DroneManager::returnToLaunch() {
	if (!m_action) return;
	std::thread([this]() {
		auto result = m_action->return_to_launch();
		if (result != Action::Result::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					emit error(tr("RTL failed: %1").arg(msg));
				},
				Qt::QueuedConnection);
		}
	}).detach();
}

void DroneManager::setAltitude(double altitudeMeters) {
	if (!m_action) return;
	std::thread([this, altitudeMeters]() {
		// Compute new absolute altitude from relative target
		double newAbsolute = m_absoluteAltitude + (altitudeMeters - m_altitude);
		auto result = m_action->goto_location(
			m_latitude, m_longitude,
			static_cast<float>(newAbsolute),
			static_cast<float>(m_heading));
		if (result != Action::Result::Success) {
			QString msg = resultToString(result);
			QMetaObject::invokeMethod(
				this,
				[this, msg]() {
					emit error(tr("Set altitude failed: %1").arg(msg));
				},
				Qt::QueuedConnection);
		}
	}).detach();
}

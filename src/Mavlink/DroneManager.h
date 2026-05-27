#pragma once

#include <qqmlintegration.h>
#include <QObject>
#include <QQmlEngine>
#include <QString>

#include <plugins/action/action.hpp>
#include <plugins/telemetry/telemetry.hpp>
#include <system.hpp>

#include <memory>

namespace mavsdk {
class System;
}

class DroneManager : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_UNCREATABLE("Created by SwarmManager")

	Q_PROPERTY(int droneUid READ droneUid CONSTANT)
	Q_PROPERTY(QString droneName READ droneName WRITE setDroneName NOTIFY
			droneNameChanged)
	Q_PROPERTY(QString connectionUrl READ connectionUrl CONSTANT)
	Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
	Q_PROPERTY(bool connecting READ isConnecting NOTIFY connectingChanged)

	Q_PROPERTY(bool armed READ isArmed NOTIFY armedChanged)
	Q_PROPERTY(bool inFlight READ isInFlight NOTIFY inFlightChanged)
	Q_PROPERTY(QString flightMode READ flightMode NOTIFY flightModeChanged)
	Q_PROPERTY(bool readyToFly READ isReadyToFly NOTIFY readyToFlyChanged)

	Q_PROPERTY(bool sensorImu READ sensorImu NOTIFY sensorImuChanged)
	Q_PROPERTY(bool sensorGps READ sensorGps NOTIFY sensorGpsChanged)
	Q_PROPERTY(bool sensorBaro READ sensorBaro NOTIFY sensorBaroChanged)
	Q_PROPERTY(bool sensorMag READ sensorMag NOTIFY sensorMagChanged)

	Q_PROPERTY(double roll READ roll NOTIFY rollChanged)
	Q_PROPERTY(double pitch READ pitch NOTIFY pitchChanged)
	Q_PROPERTY(double yaw READ yaw NOTIFY yawChanged)
	Q_PROPERTY(double altitude READ altitude NOTIFY altitudeChanged)
	Q_PROPERTY(double altitudeMsl READ altitudeMsl NOTIFY altitudeMslChanged)
	Q_PROPERTY(double airspeed READ airspeed NOTIFY airspeedChanged)
	Q_PROPERTY(double groundspeed READ groundspeed NOTIFY groundspeedChanged)
	Q_PROPERTY(double climbRate READ climbRate NOTIFY climbRateChanged)
	Q_PROPERTY(int throttle READ throttle NOTIFY throttleChanged)
	Q_PROPERTY(double heading READ heading NOTIFY headingChanged)
	Q_PROPERTY(double latitude READ latitude NOTIFY latitudeChanged)
	Q_PROPERTY(double longitude READ longitude NOTIFY longitudeChanged)

	Q_PROPERTY(double voltage READ voltage NOTIFY voltageChanged)
	Q_PROPERTY(double current READ current NOTIFY currentChanged)
	Q_PROPERTY(int battery READ battery NOTIFY batteryChanged)

	Q_PROPERTY(int wpCurrent READ wpCurrent NOTIFY wpCurrentChanged)
	Q_PROPERTY(int wpTotal READ wpTotal NOTIFY wpTotalChanged)
	Q_PROPERTY(double wpDist READ wpDist NOTIFY wpDistChanged)

	Q_PROPERTY(int ping READ ping NOTIFY pingChanged)
	Q_PROPERTY(double cpuLoad READ cpuLoad NOTIFY cpuLoadChanged)

   public:
	explicit DroneManager(
		int uid, QString name, QString url, QObject* parent = nullptr);
	~DroneManager() override;

	DroneManager(const DroneManager&) = delete;
	DroneManager& operator=(const DroneManager&) = delete;
	DroneManager(DroneManager&&) = delete;
	DroneManager& operator=(DroneManager&&) = delete;

	[[nodiscard]] int droneUid() const;
	[[nodiscard]] QString droneName() const;
	void setDroneName(const QString& name);
	[[nodiscard]] QString connectionUrl() const;

	void attachSystem(const std::shared_ptr<mavsdk::System>& system);
	void detachSystem();
	void setConnecting(bool connecting);

	[[nodiscard]] bool isConnected() const;
	[[nodiscard]] bool isConnecting() const;

	[[nodiscard]] bool isArmed() const;
	[[nodiscard]] bool isInFlight() const;
	[[nodiscard]] QString flightMode() const;
	[[nodiscard]] bool isReadyToFly() const;

	[[nodiscard]] bool sensorImu() const;
	[[nodiscard]] bool sensorGps() const;
	[[nodiscard]] bool sensorBaro() const;
	[[nodiscard]] bool sensorMag() const;

	[[nodiscard]] double roll() const;
	[[nodiscard]] double pitch() const;
	[[nodiscard]] double yaw() const;
	[[nodiscard]] double altitude() const;
	[[nodiscard]] double altitudeMsl() const;
	[[nodiscard]] double airspeed() const;
	[[nodiscard]] double groundspeed() const;
	[[nodiscard]] double climbRate() const;
	[[nodiscard]] int throttle() const;
	[[nodiscard]] double heading() const;
	[[nodiscard]] double latitude() const;
	[[nodiscard]] double longitude() const;

	[[nodiscard]] double voltage() const;
	[[nodiscard]] double current() const;
	[[nodiscard]] int battery() const;

	[[nodiscard]] int wpCurrent() const;
	[[nodiscard]] int wpTotal() const;
	[[nodiscard]] double wpDist() const;

	[[nodiscard]] int ping() const;
	[[nodiscard]] double cpuLoad() const;

	Q_INVOKABLE void arm();
	Q_INVOKABLE void disarm();
	Q_INVOKABLE void takeoff();
	Q_INVOKABLE void land();
	Q_INVOKABLE void rth();
	Q_INVOKABLE void setAltitude(double altitudeMeters);
	Q_INVOKABLE void log(
		const QString& source, const QString& message, const QString& level);

   signals:
	void droneNameChanged();
	void connectedChanged();
	void connectingChanged();

	void armedChanged();
	void inFlightChanged();
	void flightModeChanged();
	void readyToFlyChanged();

	void sensorImuChanged();
	void sensorGpsChanged();
	void sensorBaroChanged();
	void sensorMagChanged();

	void rollChanged();
	void pitchChanged();
	void yawChanged();
	void altitudeChanged();
	void altitudeMslChanged();
	void airspeedChanged();
	void groundspeedChanged();
	void climbRateChanged();
	void throttleChanged();
	void headingChanged();
	void latitudeChanged();
	void longitudeChanged();

	void voltageChanged();
	void currentChanged();
	void batteryChanged();

	void wpCurrentChanged();
	void wpTotalChanged();
	void wpDistChanged();

	void pingChanged();
	void cpuLoadChanged();

	void logMessage(
		const QString& source, const QString& message, const QString& level);

   private:
	void setupTelemetry();
	void teardownTelemetry();
	void updateReadyToFly();

	template <typename T>
	void onThread(T&& fn);

	template <typename M, typename V>
	void updateAndEmit(
		M& member, const V& value, void (DroneManager::*signal)());

	static QString flightModeToString(mavsdk::Telemetry::FlightMode mode);

	int m_uid;
	QString m_name;
	QString m_connectionUrl;
	bool m_connecting{false};

	std::shared_ptr<mavsdk::System> m_system;
	std::unique_ptr<mavsdk::Telemetry> m_telemetry;
	std::unique_ptr<mavsdk::Action> m_action;

	bool m_armed{false};
	bool m_inFlight{false};
	QString m_flightMode{"STBY"};

	bool m_sensorImu{false};
	bool m_sensorGps{false};
	bool m_sensorBaro{false};
	bool m_sensorMag{false};

	double m_roll{0.0};
	double m_pitch{0.0};
	double m_yaw{0.0};
	double m_altitude{0.0};
	double m_altitudeMsl{0.0};
	double m_airspeed{0.0};
	double m_groundspeed{0.0};
	double m_climbRate{0.0};
	int m_throttle{0};
	double m_heading{0.0};
	double m_latitude{0.0};
	double m_longitude{0.0};

	double m_voltage{0.0};
	double m_current{0.0};
	int m_battery{0};

	int m_wpCurrent{0};
	int m_wpTotal{0};
	double m_wpDist{0.0};

	int m_ping{0};
	double m_cpuLoad{0.0};

	mavsdk::Telemetry::PositionHandle m_positionHandle;
	mavsdk::Telemetry::AttitudeEulerHandle m_attitudeEulerHandle;
	mavsdk::Telemetry::HeadingHandle m_headingHandle;
	mavsdk::Telemetry::BatteryHandle m_batteryHandle;
	mavsdk::Telemetry::ArmedHandle m_armedHandle;
	mavsdk::Telemetry::InAirHandle m_inAirHandle;
	mavsdk::Telemetry::FlightModeHandle m_flightModeHandle;
	mavsdk::Telemetry::HealthHandle m_healthHandle;
	mavsdk::Telemetry::GpsInfoHandle m_gpsInfoHandle;
	mavsdk::Telemetry::VelocityNedHandle m_velocityNedHandle;
	mavsdk::Telemetry::FixedwingMetricsHandle m_fixedwingMetricsHandle;
	mavsdk::System::IsConnectedHandle m_isConnectedHandle;
};

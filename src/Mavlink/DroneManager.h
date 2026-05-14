#pragma once

#include <QObject>
#include <QString>

#include <memory>

namespace mavsdk {
class Mavsdk;
class System;
class Telemetry;
class Action;
}  // namespace mavsdk

class DroneManager : public QObject {
	Q_OBJECT

	// Connection state
	Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
	Q_PROPERTY(QString connectionStatus READ connectionStatus NOTIFY
				   connectionStatusChanged)

	// Vehicle state
	Q_PROPERTY(bool armed READ armed NOTIFY armedChanged)
	Q_PROPERTY(QString flightMode READ flightMode NOTIFY flightModeChanged)
	Q_PROPERTY(bool inAir READ inAir NOTIFY inAirChanged)

	// Position
	Q_PROPERTY(double latitude READ latitude NOTIFY positionChanged)
	Q_PROPERTY(double longitude READ longitude NOTIFY positionChanged)

	// Telemetry
	Q_PROPERTY(double roll READ roll NOTIFY attitudeChanged)
	Q_PROPERTY(double pitch READ pitch NOTIFY attitudeChanged)
	Q_PROPERTY(double heading READ heading NOTIFY headingChanged)
	Q_PROPERTY(double altitude READ altitude NOTIFY altitudeChanged)
	Q_PROPERTY(double groundSpeed READ groundSpeed NOTIFY speedChanged)
	Q_PROPERTY(double verticalSpeed READ verticalSpeed NOTIFY speedChanged)
	Q_PROPERTY(double batteryPercent READ batteryPercent NOTIFY batteryChanged)
	Q_PROPERTY(double batteryVoltage READ batteryVoltage NOTIFY batteryChanged)
	Q_PROPERTY(double yawspeed READ yawspeed NOTIFY yawspeedChanged)
	Q_PROPERTY(double yacc READ yacc NOTIFY yaccChanged)

   public:
	explicit DroneManager(QObject* parent = nullptr);
	~DroneManager() override;

	bool connected() const { return m_connected; }
	QString connectionStatus() const { return m_connectionStatus; }
	bool armed() const { return m_armed; }
	QString flightMode() const { return m_flightMode; }
	bool inAir() const { return m_inAir; }
	double latitude() const { return m_latitude; }
	double longitude() const { return m_longitude; }
	double roll() const { return m_roll; }
	double pitch() const { return m_pitch; }
	double heading() const { return m_heading; }
	double altitude() const { return m_altitude; }
	double groundSpeed() const { return m_groundSpeed; }
	double verticalSpeed() const { return m_verticalSpeed; }
	double batteryPercent() const { return m_batteryPercent; }
	double batteryVoltage() const { return m_batteryVoltage; }
	double yawspeed() const { return m_yawspeed; }
	double yacc() const { return m_yacc; }

	Q_INVOKABLE void connectToDrone(const QString& url);
	Q_INVOKABLE void disconnect();
	Q_INVOKABLE void arm();
	Q_INVOKABLE void disarm();
	Q_INVOKABLE void takeoff();
	Q_INVOKABLE void land();
	Q_INVOKABLE void returnToLaunch();

   signals:
	void connectedChanged();
	void connectionStatusChanged();
	void armedChanged();
	void flightModeChanged();
	void inAirChanged();
	void positionChanged();
	void attitudeChanged();
	void headingChanged();
	void altitudeChanged();
	void speedChanged();
	void batteryChanged();
	void yawspeedChanged();
	void yaccChanged();
	void error(const QString& message);

   private:
	void discoverSystem(const QString& url);
	void setupSystem(std::shared_ptr<mavsdk::System> system);
	void resetTelemetry();

	std::unique_ptr<mavsdk::Mavsdk> m_mavsdk;
	std::shared_ptr<mavsdk::System> m_system;
	std::unique_ptr<mavsdk::Telemetry> m_telemetry;
	std::unique_ptr<mavsdk::Action> m_action;

	bool m_connected = false;
	QString m_connectionStatus;
	bool m_armed = false;
	QString m_flightMode;
	bool m_inAir = false;
	double m_latitude = 0.0;
	double m_longitude = 0.0;
	double m_roll = 0.0;
	double m_pitch = 0.0;
	double m_heading = 0.0;
	double m_altitude = 0.0;
	double m_groundSpeed = 0.0;
	double m_verticalSpeed = 0.0;
	double m_batteryPercent = 0.0;
	double m_batteryVoltage = 0.0;
	double m_yawspeed = 0.0;
	double m_yacc = 0.0;
};

#pragma once

#include <qqmlintegration.h>
#include <QObject>
#include <QQmlEngine>
#include <QString>

class DroneManager : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_UNCREATABLE("Created by SwarmManager")

	Q_PROPERTY(int droneUid READ droneUid CONSTANT)
	Q_PROPERTY(QString droneName READ droneName WRITE setDroneName NOTIFY
				   droneNameChanged)
	Q_PROPERTY(QString connectionUrl READ connectionUrl CONSTANT)
	Q_PROPERTY(bool connected READ isConnected WRITE setConnected NOTIFY
				   connectedChanged)

	// state
	Q_PROPERTY(bool armed READ isArmed NOTIFY armedChanged)
	Q_PROPERTY(QString flightMode READ flightMode NOTIFY flightModeChanged)
	Q_PROPERTY(QString activeMode READ activeMode NOTIFY activeModeChanged)
	Q_PROPERTY(bool readyToFly READ isReadyToFly NOTIFY readyToFlyChanged)

	// sensors
	Q_PROPERTY(bool sensorImu READ sensorImu NOTIFY sensorImuChanged)
	Q_PROPERTY(bool sensorGps READ sensorGps NOTIFY sensorGpsChanged)
	Q_PROPERTY(bool sensorBaro READ sensorBaro NOTIFY sensorBaroChanged)
	Q_PROPERTY(bool sensorMag READ sensorMag NOTIFY sensorMagChanged)

	// telemetry
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

	// battery
	Q_PROPERTY(double voltage READ voltage NOTIFY voltageChanged)
	Q_PROPERTY(double current READ current NOTIFY currentChanged)
	Q_PROPERTY(int battery READ battery NOTIFY batteryChanged)

	// mission
	Q_PROPERTY(int wpCurrent READ wpCurrent NOTIFY wpCurrentChanged)
	Q_PROPERTY(int wpTotal READ wpTotal NOTIFY wpTotalChanged)
	Q_PROPERTY(double wpDist READ wpDist NOTIFY wpDistChanged)

	// link
	Q_PROPERTY(int ping READ ping NOTIFY pingChanged)

	Q_PROPERTY(double cpuLoad READ cpuLoad NOTIFY cpuLoadChanged)

   public:
	explicit DroneManager(int uid, const QString& name, const QString& url,
						  QObject* parent = nullptr);
	~DroneManager() override;

	DroneManager(const DroneManager&) = delete;
	DroneManager& operator=(const DroneManager&) = delete;
	DroneManager(DroneManager&&) = delete;
	DroneManager& operator=(DroneManager&&) = delete;

	// identity
	[[nodiscard]] int droneUid() const;
	[[nodiscard]] QString droneName() const;
	void setDroneName(const QString& name);
	[[nodiscard]] QString connectionUrl() const;

	// connection
	[[nodiscard]] bool isConnected() const;
	void setConnected(bool connected);

	// state
	[[nodiscard]] bool isArmed() const;
	[[nodiscard]] QString flightMode() const;
	[[nodiscard]] QString activeMode() const;
	[[nodiscard]] bool isReadyToFly() const;

	// sensors
	[[nodiscard]] bool sensorImu() const;
	[[nodiscard]] bool sensorGps() const;
	[[nodiscard]] bool sensorBaro() const;
	[[nodiscard]] bool sensorMag() const;

	// telemetry
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

	// battery
	[[nodiscard]] double voltage() const;
	[[nodiscard]] double current() const;
	[[nodiscard]] int battery() const;

	// mission
	[[nodiscard]] int wpCurrent() const;
	[[nodiscard]] int wpTotal() const;
	[[nodiscard]] double wpDist() const;

	// link
	[[nodiscard]] int ping() const;

	[[nodiscard]] double cpuLoad() const;

	// commands
	Q_INVOKABLE void arm();
	Q_INVOKABLE void disarm();
	Q_INVOKABLE void takeoff();
	Q_INVOKABLE void land();
	Q_INVOKABLE void rth();
	Q_INVOKABLE void setMode(const QString& mode);
	Q_INVOKABLE void cycleMode();
	Q_INVOKABLE void log(const QString& source, const QString& message,
						 const QString& level);

   signals:
	void droneNameChanged();
	void connectedChanged();

	void armedChanged();
	void flightModeChanged();
	void activeModeChanged();
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

	void logMessage(const QString& source, const QString& message,
					const QString& level);

   private:
	void updateReadyToFly();

	int m_uid;
	QString m_name;
	QString m_connectionUrl;
	bool m_connected{false};

	bool m_armed{false};
	QString m_flightMode{"STBY"};
	QString m_activeMode{"STBY"};

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
};

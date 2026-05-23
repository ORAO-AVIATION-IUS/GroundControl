#include "DroneManager.h"

#include <QStringList>

DroneManager::DroneManager(int uid, const QString& name,
                           const QString& url, QObject* parent)
    : QObject(parent), m_uid(uid), m_name(name), m_connectionUrl(url) {}

DroneManager::~DroneManager() = default;


int DroneManager::droneUid() const { return m_uid; }

QString DroneManager::droneName() const { return m_name; }

void DroneManager::setDroneName(const QString& name) {
    if (m_name == name) return;
    m_name = name;
    emit droneNameChanged();
}

QString DroneManager::connectionUrl() const { return m_connectionUrl; }


bool DroneManager::isConnected() const { return m_connected; }

void DroneManager::setConnected(bool connected) {
    if (m_connected == connected) return;
    m_connected = connected;
    emit connectedChanged();
}


bool DroneManager::isArmed() const { return m_armed; }

QString DroneManager::flightMode() const { return m_flightMode; }

QString DroneManager::activeMode() const { return m_activeMode; }

bool DroneManager::isReadyToFly() const {
    return m_sensorImu && m_sensorGps && m_sensorBaro && m_sensorMag &&
           m_battery > 20;
}


bool DroneManager::sensorImu() const { return m_sensorImu; }
bool DroneManager::sensorGps() const { return m_sensorGps; }
bool DroneManager::sensorBaro() const { return m_sensorBaro; }
bool DroneManager::sensorMag() const { return m_sensorMag; }


double DroneManager::roll() const { return m_roll; }
double DroneManager::pitch() const { return m_pitch; }
double DroneManager::yaw() const { return m_yaw; }
double DroneManager::altitude() const { return m_altitude; }
double DroneManager::altitudeMsl() const { return m_altitudeMsl; }
double DroneManager::airspeed() const { return m_airspeed; }
double DroneManager::groundspeed() const { return m_groundspeed; }
double DroneManager::climbRate() const { return m_climbRate; }
int DroneManager::throttle() const { return m_throttle; }
double DroneManager::heading() const { return m_heading; }
double DroneManager::latitude() const { return m_latitude; }
double DroneManager::longitude() const { return m_longitude; }


double DroneManager::voltage() const { return m_voltage; }
double DroneManager::current() const { return m_current; }
int DroneManager::battery() const { return m_battery; }


int DroneManager::wpCurrent() const { return m_wpCurrent; }
int DroneManager::wpTotal() const { return m_wpTotal; }
double DroneManager::wpDist() const { return m_wpDist; }


int DroneManager::ping() const { return m_ping; }

double DroneManager::cpuLoad() const { return m_cpuLoad; }


void DroneManager::arm() {
    if (m_armed) return;
    m_armed = true;
    m_flightMode = m_activeMode;
    emit armedChanged();
    emit flightModeChanged();
    emit logMessage(m_name, "Armed — motor check OK", "info");
}

void DroneManager::disarm() {
    if (!m_armed) return;
    m_armed = false;
    m_flightMode = "STBY";
    m_activeMode = "STBY";
    emit armedChanged();
    emit flightModeChanged();
    emit activeModeChanged();
    emit logMessage(m_name, "Disarmed", "info");
}

void DroneManager::takeoff() {
    emit logMessage(m_name, "TAKEOFF command sent", "info");
}

void DroneManager::land() {
    emit logMessage(m_name, "LAND command sent", "info");
}

void DroneManager::rth() {
    emit logMessage(m_name, "RTH command sent", "info");
}

void DroneManager::setMode(const QString& mode) {
    if (m_activeMode == mode) return;
    m_activeMode = mode;
    emit activeModeChanged();
    if (m_armed) {
        m_flightMode = mode;
        emit flightModeChanged();
    }
    emit logMessage(m_name, "Mode changed to " + mode, "info");
}

void DroneManager::cycleMode() {
    static const QStringList modes = {"STBY", "GUIDED", "AUTO",
                                      "RTL",  "LOITER", "LAND"};
    int idx = modes.indexOf(m_activeMode);
    if (idx < 0) idx = 0;
    setMode(modes.at((idx + 1) % modes.size()));
}

void DroneManager::log(const QString& source, const QString& message,
                        const QString& level) {
    emit logMessage(source, message, level);
}


void DroneManager::updateReadyToFly() { emit readyToFlyChanged(); }

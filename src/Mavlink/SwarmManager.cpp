#include "SwarmManager.h"

#include "DroneManager.h"

SwarmManager::SwarmManager(QQmlEngine* engine, QObject* parent)
    : QObject(parent), m_engine(engine) {}

SwarmManager* SwarmManager::create(QQmlEngine* qmlEngine, QJSEngine* /*jsEngine*/) {
    return new SwarmManager(qmlEngine, qmlEngine);
}

SwarmManager::~SwarmManager() = default;

QList<DroneManager*> SwarmManager::drones() const { return m_drones; }

int SwarmManager::droneCount() const { return m_drones.size(); }

int SwarmManager::selectedDroneIndex() const { return m_selectedIndex; }

DroneManager* SwarmManager::selectedDrone() const {
    if (m_selectedIndex >= 0 && m_selectedIndex < m_drones.size())
        return m_drones.at(m_selectedIndex);
    return nullptr;
}

DroneManager* SwarmManager::droneAt(int index) const {
    if (index >= 0 && index < m_drones.size()) return m_drones.at(index);
    return nullptr;
}

DroneManager* SwarmManager::droneByUid(int uid) const {
    for (auto* d : m_drones) {
        if (d->droneUid() == uid) return d;
    }
    return nullptr;
}

int SwarmManager::addDrone(const QString& name, const QString& url) {
    if (name.isEmpty() || url.isEmpty()) return -1;

    int uid = m_nextUid++;
    auto* drone = new DroneManager(uid, name, url, this);
    drone->setConnected(true);
    m_drones.append(drone);

    emit dronesChanged();

    // auto-select if this is the first drone
    if (m_drones.size() == 1) {
        selectDrone(0);
    }

    return uid;
}

void SwarmManager::removeDroneByUid(int uid) {
    int idx = -1;
    for (int i = 0; i < m_drones.size(); ++i) {
        if (m_drones.at(i)->droneUid() == uid) {
            idx = i;
            break;
        }
    }
    if (idx < 0) return;

    auto* drone = m_drones.takeAt(idx);
    drone->deleteLater();

    emit dronesChanged();
    handleSelectionAfterRemoval(idx);
}

void SwarmManager::selectDrone(int index) {
    if (index < 0 || index >= m_drones.size()) {
        clearSelection();
        return;
    }
    if (m_selectedIndex == index) return;

    m_selectedIndex = index;
    emit selectedDroneIndexChanged();
    emit selectedDroneChanged();
}

void SwarmManager::clearSelection() {
    if (m_selectedIndex == -1) return;

    m_selectedIndex = -1;
    emit selectedDroneIndexChanged();
    emit selectedDroneChanged();
}

void SwarmManager::handleSelectionAfterRemoval(int removedIndex) {
    // Clear selection — user must explicitly reselect.
    // This avoids confusion after a drone disappears.
    m_selectedIndex = -1;
    emit selectedDroneIndexChanged();
    emit selectedDroneChanged();
}

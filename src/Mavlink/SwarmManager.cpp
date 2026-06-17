#include "SwarmManager.h"

#include "DroneManager.h"
#include "LogEntry.h"
#include "LogManager.h"

#include <mavsdk.hpp>

#include <algorithm>

namespace {

// Map the textual level used by DroneManager::logMessage to the numeric
// LogLevel understood by LogManager::emitLog.
int logLevelFromString(const QString& level) {
	const QString l = level.toLower();
	if (l == "debug") {
		return static_cast<int>(agc::LogLevel::Debug);
	}
	if (l == "warn" || l == "warning") {
		return static_cast<int>(agc::LogLevel::Warning);
	}
	if (l == "err" || l == "error") {
		return static_cast<int>(agc::LogLevel::Error);
	}
	if (l == "critical" || l == "fatal") {
		return static_cast<int>(agc::LogLevel::Critical);
	}
	return static_cast<int>(agc::LogLevel::Info);
}

}  // namespace

struct SwarmManager::Impl {
	struct DroneConnection {
		DroneManager* drone{nullptr};
		mavsdk::Mavsdk::ConnectionHandle handle;
		mavsdk::System* system{nullptr};
	};

	std::unique_ptr<mavsdk::Mavsdk> mavsdk;
	QList<DroneConnection> connections;
};

SwarmManager::SwarmManager(QQmlEngine* engine, QObject* parent)
	: QObject(parent), m_engine(engine), m_impl(std::make_unique<Impl>()) {
	m_impl->mavsdk = std::make_unique<mavsdk::Mavsdk>(
		mavsdk::Mavsdk::Configuration{mavsdk::ComponentType::GroundStation});
	m_impl->mavsdk->subscribe_on_new_system(
		[this]() { onNewSystemDiscovered(); });
}

SwarmManager* SwarmManager::create(
	QQmlEngine* qmlEngine, QJSEngine* /*jsEngine*/) {
	// NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
	return new SwarmManager(qmlEngine, qmlEngine);
}

SwarmManager::~SwarmManager() = default;

QList<DroneManager*> SwarmManager::drones() const {
	return m_drones;
}

QVariantList SwarmManager::droneList() const {
	QVariantList list;
	list.reserve(m_drones.size());
	for (auto* drone : m_drones) {
		list.append(QVariant::fromValue(drone));
	}
	return list;
}

int SwarmManager::droneCount() const {
	return static_cast<int>(m_drones.size());
}

int SwarmManager::selectedDroneIndex() const {
	return m_selectedIndex;
}

DroneManager* SwarmManager::selectedDrone() const {
	if (m_selectedIndex >= 0 && m_selectedIndex < m_drones.size()) {
		return m_drones.at(m_selectedIndex);
	}
	return nullptr;
}

DroneManager* SwarmManager::droneAt(int index) const {
	if (index >= 0 && index < m_drones.size()) {
		return m_drones.at(index);
	}
	return nullptr;
}

DroneManager* SwarmManager::droneByUid(int uid) const {
	for (auto* drone : m_drones) {
		if (drone->droneUid() == uid) {
			return drone;
		}
	}
	return nullptr;
}

bool SwarmManager::isSystemAttached(
	const std::shared_ptr<mavsdk::System>& system) const {
	return std::ranges::any_of(m_impl->connections,
		[&system](const Impl::DroneConnection& connection) {
			return connection.system == system.get();
		});
}

int SwarmManager::addDrone(const QString& name, const QString& url) {
	if (name.isEmpty() || url.isEmpty()) {
		return -1;
	}

	auto [result, handle] =
		m_impl->mavsdk->add_any_connection_with_handle(url.toStdString());
	if (result != mavsdk::ConnectionResult::Success) {
		qWarning() << "Connection failed for" << name << "at" << url << ":"
				   << QString::fromStdString(
						  std::string(mavsdk::to_string(result)));
		return -1;
	}

	int uid = m_nextUid++;
	auto* drone = new DroneManager(uid, name, url, this);
	drone->setConnecting(true);

	// Route every drone's log messages into the central LogManager so they
	// appear in the log panel / per-drone log view and are persisted to file.
	QObject::connect(drone, &DroneManager::logMessage, this,
		[](const QString& source, const QString& message,
			const QString& level) {
			agc::LogManager::instance().emitLog(
				source, logLevelFromString(level), message);
		});

	m_drones.append(drone);
	m_pending.append(drone);
	m_impl->connections.append(
		{.drone = drone, .handle = handle, .system = nullptr});

	emit dronesChanged();

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
	if (idx < 0) {
		return;
	}

	emit droneAboutToBeRemoved(uid);

	auto* drone = m_drones.takeAt(idx);
	m_pending.removeOne(drone);

	for (int i = 0; i < m_impl->connections.size(); ++i) {
		if (m_impl->connections.at(i).drone != drone) {
			continue;
		}
		m_impl->mavsdk->remove_connection(m_impl->connections.at(i).handle);
		m_impl->connections.removeAt(i);
		break;
	}

	drone->detachSystem();
	drone->deleteLater();

	emit dronesChanged();
	handleSelectionAfterRemoval(idx);
}

void SwarmManager::selectDrone(int index) {
	if (index < 0 || index >= m_drones.size()) {
		clearSelection();
		return;
	}
	if (m_selectedIndex == index) {
		return;
	}

	m_selectedIndex = index;
	emit selectedDroneIndexChanged();
	emit selectedDroneChanged();
}

void SwarmManager::clearSelection() {
	if (m_selectedIndex == -1) {
		return;
	}

	m_selectedIndex = -1;
	emit selectedDroneIndexChanged();
	emit selectedDroneChanged();
}

void SwarmManager::handleSelectionAfterRemoval(int /*removedIndex*/) {
	m_selectedIndex = -1;
	emit selectedDroneIndexChanged();
	emit selectedDroneChanged();
}

void SwarmManager::onNewSystemDiscovered() {
	QMetaObject::invokeMethod(
		this,
		[this]() {
			if (m_pending.isEmpty()) {
				return;
			}

			const auto systems = m_impl->mavsdk->systems();
			for (const auto& system : systems) {
				if (!system->has_autopilot()) {
					continue;
				}
				if (!system->is_connected()) {
					continue;
				}
				if (isSystemAttached(system)) {
					continue;
				}
				if (m_pending.isEmpty()) {
					break;
				}

				auto* drone = m_pending.takeFirst();
				for (auto& connection : m_impl->connections) {
					if (connection.drone != drone) {
						continue;
					}
					connection.system = system.get();
					break;
				}
				drone->attachSystem(system);
			}
		},
		Qt::QueuedConnection);
}

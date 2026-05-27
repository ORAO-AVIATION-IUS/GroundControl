#pragma once

#include <qqmlintegration.h>
#include <QJSEngine>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QVariantList>

#include <memory>

namespace mavsdk {
class System;
}  // namespace mavsdk

class DroneManager;

class SwarmManager : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_SINGLETON

	Q_PROPERTY(QList<DroneManager*> drones READ drones NOTIFY dronesChanged)
	Q_PROPERTY(QVariantList droneList READ droneList NOTIFY dronesChanged)
	Q_PROPERTY(int droneCount READ droneCount NOTIFY dronesChanged)
	Q_PROPERTY(int selectedDroneIndex READ selectedDroneIndex NOTIFY
			selectedDroneIndexChanged)
	Q_PROPERTY(DroneManager* selectedDrone READ selectedDrone NOTIFY
			selectedDroneChanged)

   public:
	explicit SwarmManager(QQmlEngine* engine, QObject* parent = nullptr);
	~SwarmManager() override;

	SwarmManager(const SwarmManager&) = delete;
	SwarmManager& operator=(const SwarmManager&) = delete;
	SwarmManager(SwarmManager&&) = delete;
	SwarmManager& operator=(SwarmManager&&) = delete;

	static SwarmManager* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);

	[[nodiscard]] QList<DroneManager*> drones() const;
	[[nodiscard]] QVariantList droneList() const;
	[[nodiscard]] int droneCount() const;
	[[nodiscard]] int selectedDroneIndex() const;
	[[nodiscard]] DroneManager* selectedDrone() const;

	Q_INVOKABLE [[nodiscard]] DroneManager* droneAt(int index) const;
	Q_INVOKABLE [[nodiscard]] DroneManager* droneByUid(int uid) const;

	Q_INVOKABLE int addDrone(const QString& name, const QString& url);
	Q_INVOKABLE void removeDroneByUid(int uid);
	Q_INVOKABLE void selectDrone(int index);
	Q_INVOKABLE void clearSelection();

   signals:
	void dronesChanged();
	void selectedDroneIndexChanged();
	void selectedDroneChanged();

   private:
	struct Impl;

	void handleSelectionAfterRemoval(int removedIndex);
	void onNewSystemDiscovered();

	[[nodiscard]] bool isSystemAttached(
		const std::shared_ptr<mavsdk::System>& system) const;

	QQmlEngine* m_engine;
	QList<DroneManager*> m_drones;
	QList<DroneManager*> m_pending;
	int m_selectedIndex{-1};
	int m_nextUid{1};
	std::unique_ptr<Impl> m_impl;
};

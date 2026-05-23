#pragma once

#include <qqmlintegration.h>
#include <QJSEngine>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QString>

class DroneManager;

class SwarmManager : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_SINGLETON

	Q_PROPERTY(QList<DroneManager*> drones READ drones NOTIFY dronesChanged)
	Q_PROPERTY(int droneCount READ droneCount NOTIFY dronesChanged)
	Q_PROPERTY(int selectedDroneIndex READ selectedDroneIndex NOTIFY
				   selectedDroneIndexChanged)
	Q_PROPERTY(DroneManager* selectedDrone READ selectedDrone NOTIFY
				   selectedDroneChanged)

   public:
	explicit SwarmManager(QQmlEngine* engine, QObject* parent = nullptr);

	static SwarmManager* create(QQmlEngine* qmlEngine, QJSEngine* jsEngine);
	~SwarmManager() override;

	SwarmManager(const SwarmManager&) = delete;
	SwarmManager& operator=(const SwarmManager&) = delete;
	SwarmManager(SwarmManager&&) = delete;
	SwarmManager& operator=(SwarmManager&&) = delete;

	[[nodiscard]] QList<DroneManager*> drones() const;
	[[nodiscard]] int droneCount() const;
	[[nodiscard]] int selectedDroneIndex() const;
	[[nodiscard]] DroneManager* selectedDrone() const;

	Q_INVOKABLE [[nodiscard]] DroneManager* droneAt(int index) const;
	Q_INVOKABLE [[nodiscard]] DroneManager* droneByUid(int uid) const;

	// Returns the uid of the newly created drone (-1 on failure).
	Q_INVOKABLE int addDrone(const QString& name, const QString& url);
	Q_INVOKABLE void removeDroneByUid(int uid);
	Q_INVOKABLE void selectDrone(int index);
	Q_INVOKABLE void clearSelection();

   signals:
	void dronesChanged();
	void droneCountChanged();
	void selectedDroneIndexChanged();
	void selectedDroneChanged();

   private:
	void handleSelectionAfterRemoval(int removedIndex);

	QQmlEngine* m_engine;
	QList<DroneManager*> m_drones;
	int m_selectedIndex{-1};
	int m_nextUid{1};
};

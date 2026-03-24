#ifndef MAVLINKMANAGER_H
#define MAVLINKMANAGER_H

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include "third_party/c_library_v2/common/mavlink.h"

class MAVLinkManager : public QObject {
	Q_OBJECT
	Q_PROPERTY(double pitch READ pitch NOTIFY attitudeChanged)
	Q_PROPERTY(double roll READ roll NOTIFY attitudeChanged)
	Q_PROPERTY(double yaw READ yaw NOTIFY attitudeChanged)
	Q_PROPERTY(double altitude READ altitude NOTIFY vfrHudChanged)
	Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectionChanged)
	Q_PROPERTY(int batteryRemaining READ batteryRemaining NOTIFY batteryChanged)
	Q_PROPERTY(QString flightMode READ flightMode NOTIFY flightModeChanged)
	Q_PROPERTY(double airspeed READ airspeed NOTIFY vfrHudChanged)
	Q_PROPERTY(double gForce READ gForce NOTIFY imuDataChanged)
	Q_PROPERTY(double gyroX READ gyroX NOTIFY imuDataChanged)
   public:
	explicit MAVLinkManager(QObject* parent = nullptr);

	double pitch() const { return _pitch; }
	double roll() const { return _roll; }
	double yaw() const { return _yaw; }
	double altitude() const { return _altitude; }
	bool isConnected() const { return _isConnected; }
	int batteryRemaining() const { return _batteryRemaining; }
	void setPitch(double pitch);
	QString flightMode() const { return _flightMode; }
	double airspeed() const { return _airspeed; }
	double gForce() const { return _gForce; }
	double gyroX() const { return _gyroX; }

   signals:
	void attitudeChanged();   // Pitch, Roll ve Yaw için ortak sinyal
	void vfrHudChanged();     // İrtifa için
	void connectionChanged(); // Bağlantı için
	void batteryChanged();    // Batarya için
	void flightModeChanged();
	void imuDataChanged();
   private:
	double _pitch = 0.0;
	double _roll =0.0;
	double _yaw=0.0;
	double _altitude=0.0;
	int _batteryRemaining=0;
	bool _isConnected = false;
	QString _flightMode = "DISCONNECTED"; // Varsayılan değer
	QUdpSocket* socket;
	QTimer* connectionTimer; // Bağlantı kopmasını anlamak için
	double _airspeed = 0.0;
	double _gForce = 1.0; // Dünya üzerinde dururken 1G'dir
	double _gyroX = 0.0;

	void handleMessage(const mavlink_message_t& msg);
	void updateConnectionStatus(bool connected);
};

#endif

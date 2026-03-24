#include "MAVLinkManager.h"
#include <QDebug>

MAVLinkManager::MAVLinkManager(QObject* parent) : QObject(parent) {
	socket = new QUdpSocket(this);
	connectionTimer = new QTimer(this);

	// 3 saniye boyunca veri gelmezse bağlantıyı koptu say
	connectionTimer->setInterval(3000);
	connect(connectionTimer, &QTimer::timeout, this, [=]() {
		updateConnectionStatus(false);
	});

	// 14550 portunu dinlemeye başla
	//qFatal("KOD BURAYA GIRDI - TEST");
	bool ok = socket->bind(QHostAddress::Any, 14550);

	if (ok) {
		qDebug() << "-----------------------------------------";
		qDebug() << "UDP SOKET BAŞLATILDI: Port 14550 dinleniyor...";
		qDebug() << "-----------------------------------------";
	} else {
		qDebug() << "!!! SOKET HATASI: 14550 portu meşgul veya açılamadı!";
	}

	connect(socket, &QUdpSocket::readyRead, this, [=]() {
		while (socket->hasPendingDatagrams()) {
			QByteArray datagram;
			datagram.resize(socket->pendingDatagramSize());
			socket->readDatagram(datagram.data(), datagram.size());

			mavlink_message_t msg;
			mavlink_status_t status;

			for (int i = 0; i < datagram.size(); i++) {
				if (mavlink_parse_char(MAVLINK_COMM_0, (uint8_t)datagram.at(i), &msg, &status)) {
					// Mesaj geldiyse bağlantıyı aktif et ve zamanlayıcıyı sıfırla
					updateConnectionStatus(true);
					connectionTimer->start();

					handleMessage(msg);
				}
			}
		}
	});
}

// Eksik olan Setter fonksiyonu
void MAVLinkManager::setPitch(double pitch) {
	if (qFuzzyCompare(_pitch, pitch)) return;
	_pitch = pitch;
	emit attitudeChanged(); // Olmayan sinyal yerine attitudeChanged çakıyoruz
}
void MAVLinkManager::updateConnectionStatus(bool connected) {
	if (_isConnected == connected) return;
	_isConnected = connected;

	if (_isConnected) {
		qDebug() << "[SİSTEM] MAVLink Bağlantısı Kuruldu!";
	} else {
		qDebug() << "[UYARI] MAVLink Bağlantısı Koptu! Veri bekleniyor...";
	}
	emit connectionChanged();
}
void MAVLinkManager::handleMessage(const mavlink_message_t& msg) {
	switch (msg.msgid) {
		case MAVLINK_MSG_ID_ATTITUDE: {
			mavlink_attitude_t att;
			mavlink_msg_attitude_decode(&msg, &att);

			// Radyandan Dereceye çevrim (* 57.2958)
			_pitch = att.pitch * 57.2958;
			_roll = att.roll * 57.2958;
			_yaw = att.yaw * 57.2958;

			emit attitudeChanged();
			break;
		}
		case MAVLINK_MSG_ID_VFR_HUD: {
			mavlink_vfr_hud_t hud;
			mavlink_msg_vfr_hud_decode(&msg, &hud);

			_altitude = hud.alt; // Metre cinsinden rakım
			emit vfrHudChanged();
			break;
		}
		case MAVLINK_MSG_ID_SYS_STATUS: {
			mavlink_sys_status_t status;
			mavlink_msg_sys_status_decode(&msg, &status);

			// battery_remaining: -1 ise gönderilmiyor demektir, değilse % değeridir
			if (status.battery_remaining != -1) {
				_batteryRemaining = status.battery_remaining;
				emit batteryChanged();
			}
			break;
		}
		case MAVLINK_MSG_ID_HEARTBEAT: {
			mavlink_heartbeat_t hb;
			mavlink_msg_heartbeat_decode(&msg, &hb);

			QString modeStr;
			switch (hb.custom_mode) {
				case 0: modeStr = "MANUAL"; break;
				case 2: modeStr = "STABILIZE"; break;
				case 5: modeStr = "FBWA"; break;
				case 10: modeStr = "AUTO"; break;
				case 11: modeStr = "RTL"; break;
				case 15: modeStr = "GUIDED"; break;
				default: modeStr = QString("MODE %1").arg(hb.custom_mode); break;
			}

			if (_flightMode != modeStr) {
				_flightMode = modeStr;
				emit flightModeChanged();
			}
			break;
		}
	}
}

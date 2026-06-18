#pragma once

#include <QByteArray>
#include <QList>
#include <QMutex>
#include <QObject>
#include <QProcess>
#include <QSize>
#include <QString>

struct Detection {
	float x = 0.0F;
	float y = 0.0F;
	float w = 0.0F;
	float h = 0.0F;
	QString label;
	float score = 0.0F;
};

Q_DECLARE_METATYPE(Detection)
Q_DECLARE_METATYPE(QList<Detection>)

class DetectionWorker : public QObject {
	Q_OBJECT

   public:
	explicit DetectionWorker(
		int streamId, double confidenceThreshold, QObject* parent = nullptr);
	~DetectionWorker() override;

	DetectionWorker(const DetectionWorker&) = delete;
	DetectionWorker& operator=(const DetectionWorker&) = delete;
	DetectionWorker(DetectionWorker&&) = delete;
	DetectionWorker& operator=(DetectionWorker&&) = delete;

	void start();
	void stop();

	// Called from the GStreamer streaming thread. Keeps only the most recent
	// frame while the detector process is busy.
	void submitFrame(const QByteArray& bgrData, QSize frameSize);

   signals:
	void detectionsReady(int streamId, QList<Detection> detections);
	void alertReady(int streamId, QString alert);

   private:
	void onReadyRead();
	void onProcessError(QProcess::ProcessError error);
	void writeFrame(const QByteArray& data, QSize frameSize);
	void sendPendingFrame();

	int m_streamId;
	double m_confidenceThreshold = 0.0;
	QProcess* m_process = nullptr;
	QMutex m_frameMutex;
	QByteArray m_pendingFrame;
	QSize m_pendingSize;
	bool m_hasPending = false;
	bool m_busy = false;
};

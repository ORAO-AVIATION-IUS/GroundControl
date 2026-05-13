#pragma once

#include <QQuickImageProvider>

class BreezeIconProvider : public QQuickImageProvider {
   public:
	BreezeIconProvider();

	QPixmap requestPixmap(const QString& id, QSize* size,
						  const QSize& requestedSize) override;
};

QQuickImageProvider* createBreezeIconProvider();

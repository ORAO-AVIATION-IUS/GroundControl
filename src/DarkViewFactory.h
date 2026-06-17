#pragma once

#include <kddockwidgets/qtquick/ViewFactory.h>

/// Dark-themed ViewFactory for KDDockWidgets QtQuick.
/// Provides custom QML views that use a dark colour palette
/// matching the rest of the Ground Control application.
class DarkViewFactory : public KDDockWidgets::QtQuick::ViewFactory {
	Q_OBJECT

   public:
	DarkViewFactory() = default;
	~DarkViewFactory() override = default;

	QUrl separatorFilename() const override;
	QUrl titleBarFilename() const override;
	QUrl groupFilename() const override;
	QUrl floatingWindowFilename() const override;
	QUrl tabbarFilename() const override;
};

#include "MessageHandler.h"

#include <QDebug>

namespace {

// Silence specific third-party warnings that are harmless but noisy.
// The handler is installed once and lives for the lifetime of the application.
bool shouldSuppress(QtMsgType type, const QString& message) {
	if (type != QtWarningMsg) {
		return false;
	}

	// MapLibre's internal mbgl::util::Timer passes an unclamped
	// std::chrono::duration to QTimer::start(), which overflows
	// INT_MAX ms. Qt clamps it internally, so the warning is harmless.
	if (message.contains("QTimer::start: interval exceeds maximum")) {
		return true;
	}

	return false;
}

QtMessageHandler& previousHandler() {
	static QtMessageHandler handler = nullptr;
	return handler;
}

void filteredHandler(
	QtMsgType type, const QMessageLogContext& ctx, const QString& msg) {
	if (shouldSuppress(type, msg)) {
		return;
	}
	if (previousHandler() != nullptr) {
		previousHandler()(type, ctx, msg);
	}
}

}  // namespace

void installMessageHandler() {
	previousHandler() = qInstallMessageHandler(filteredHandler);
}

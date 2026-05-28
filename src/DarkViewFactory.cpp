#include "DarkViewFactory.h"

QUrl DarkViewFactory::separatorFilename() const {
	return QUrl("qrc:/resources/kddw-dark/Separator.qml");
}

QUrl DarkViewFactory::titleBarFilename() const {
	return QUrl("qrc:/resources/kddw-dark/TitleBar.qml");
}

QUrl DarkViewFactory::groupFilename() const {
	return QUrl("qrc:/resources/kddw-dark/Group.qml");
}

QUrl DarkViewFactory::floatingWindowFilename() const {
	return QUrl("qrc:/resources/kddw-dark/FloatingWindow.qml");
}

QUrl DarkViewFactory::tabbarFilename() const {
	return QUrl("qrc:/resources/kddw-dark/TabBar.qml");
}

import QtQuick 2.6

Item {
	id: rootAttitude
	property int indWidth: 200
	property int indHeight: 200

	width: indWidth
	height: indHeight

	Image {
		anchors.fill: parent
		// Yeni klasör yapısına göre göreli yol (relative path)
		source: "imagesOfComponents/AttitudeIndicator.png"
		fillMode: Image.PreserveAspectFit
	}
}

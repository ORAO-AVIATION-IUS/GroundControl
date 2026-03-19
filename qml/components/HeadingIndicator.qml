import QtQuick 2.6

Item {
	id: rootHeading
	property int indWidth: 150
	property int indHeight: 150

	width: indWidth
	height: indHeight

	Image {
		anchors.fill: parent
		source: "imagesOfComponents/AttitudeIndicator.png"
		fillMode: Image.PreserveAspectFit
	}
}

import QtQuick 2.6
import QtQuick.Controls 2.15

Rectangle {
	width: 400
	height: 400
	color: '#ffffff'

	Rectangle {
		id: compassContainer

		width: 220
		height: 220
		radius: width / 2
		color: "transparent"
		border.color: "black"
		border.width: 3
		anchors.centerIn: parent
		property real heading: 0

		Image {

			id: compassImage
			source: "qrc:/assets/compass.png"
			anchors.centerIn: parent
			fillMode: Image.PreserveAspectFit
			height: parent.height
			width: parent.width
			x: 0
			y: 0
		}
		SequentialAnimation {
			onStopped: {
				compassImage.rotation = 0;	
				compassContainer.heading = 0;
			}
			running: true
			loops: Animation.Infinite
			PropertyAnimation {
				target: compassImage
				property: "rotation"
				duration: 2000
				easing.type: Easing.InOutQuad
				from: 0
				to: 45
			}
			PauseAnimation {
				duration: 500
			}
			PropertyAnimation {
				target: compassImage
				property: "rotation"
				duration: 2000
				easing.type: Easing.InOutQuad
				from: 45
				to: 90
			}
			PropertyAnimation {
				target: compassImage
				property: "rotation"
				duration: 2000
				easing.type: Easing.InOutQuad
				from: 90
				to: -45
			}
		}
	}
}

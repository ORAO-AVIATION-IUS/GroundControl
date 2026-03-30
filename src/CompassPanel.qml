import QtQuick
import QtQuick.Controls // Slider ve Butonlar için gerekli

Rectangle {
	id: panelBackground
	color: '#ffffff'
	anchors.fill: parent

	CompassIndicator {
		id: myCompass
		anchors.rightMargin: 40
		anchors.topMargin: 40
		anchors.right: parent.right
		anchors.top: parent.top
		heading: headingSlider.value
	}

	AttitudeIndicator {
		id: myAttitude
		anchors.leftMargin: 40
		anchors.topMargin: 40
		anchors.left: parent.left
		anchors.top: parent.top
		pitch: pitchSlider.value
		roll: rollSlider.value
	}

	AirspeedIndicator {
			id: myAirspeed
			anchors.top: myAttitude.bottom
			anchors.topMargin: 40
			anchors.horizontalCenter : myAttitude.horizontalCenter
			airspeedMs: airspeedSlider.value / 1.94384 
	}

	Rectangle {
		width: 450
		height: 220
		color: "#f8f9fa"
		border.color: "#dee2e6"
		border.width: 1
		radius: 12
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 40
		anchors.horizontalCenter: parent.horizontalCenter

		Column {
			anchors.centerIn: parent
			spacing: 15

			Row {
				spacing: 15
				Text {
					text: "Pitch: " + Math.round(pitchSlider.value) + "°"
					width: 90
					font.pixelSize: 15
					font.bold: true
					color: "#2c3e50"
				}
				Slider {
					id: pitchSlider
					width: 250
					from: -45
					to: 45
					value: 0
					stepSize: 1
				}
			}

			Row {
				spacing: 15
				Text {
					text: "Roll: " + Math.round(rollSlider.value) + "°"
					width: 90
					font.pixelSize: 15
					font.bold: true
					color: "#2c3e50"
				}
				Slider {
					id: rollSlider
					width: 250
					from: -180
					to: 180
					value: 0
					stepSize: 1
				}
			}

			Row {
				spacing: 15
				Text {
					text: "Heading: " + Math.round(headingSlider.value) + "°"
					width: 90
					font.pixelSize: 15
					font.bold: true
					color: "#2c3e50"
				}
				Slider {
					id: headingSlider
					width: 250
					from: 0
					to: 360
					value: 0
					stepSize: 1
				}
			}
			Row {
				spacing: 15
				Text {
					text: "Airspeed: " + Math.round(airspeedSlider.value) + " knots"
					width: 90
					font.pixelSize: 15
					font.bold: true
					color: "#2c3e50"
				}
				Slider {
					id: airspeedSlider
					width: 250
					from: 0
					to: 200
					value: 0
					stepSize: 1
				}
			}
			Button {
				text: "Reset"
				anchors.horizontalCenter: parent.horizontalCenter
				onClicked: {
					pitchSlider.value = 0;
					rollSlider.value = 0;
					headingSlider.value = 0;
				}
			}
		}
	}
}

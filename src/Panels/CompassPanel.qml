import QtQuick
import QtQuick.Controls
import com.kdab.dockwidgets as KDDW
import Agc.Components

KDDW.DockWidget {
	id: root
	uniqueName: "compassPanel"
	title: qsTr("Compass Panel")

	Rectangle {
		anchors.fill: parent
		id: panelBackground
		color: "#ffffff"

		CompassIndicator {
			id: myCompass
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.rightMargin: 40
			anchors.topMargin: 40
			heading: headingSlider.value
		}

		AttitudeIndicator {
			id: myAttitude
			anchors.left: parent.left
			anchors.top: parent.top
			anchors.leftMargin: 40
			anchors.topMargin: 40
			pitch: pitchSlider.value
			roll: rollSlider.value
		}

		AirspeedIndicator {
			id: myAirspeed
			anchors.top: myAttitude.bottom
			anchors.topMargin: 40
			anchors.horizontalCenter: myAttitude.horizontalCenter
			airspeedMs: airspeedSlider.value / 1.94384
		}

		HeadingIndicator {
			id: myHeading
			anchors.top: myCompass.bottom
			anchors.topMargin: 40
			anchors.horizontalCenter: myCompass.horizontalCenter
			heading: headingSlider.value
		}

		TurnController {
			id: myTurnCoordinator
			anchors.top: parent.top
			anchors.topMargin: 40
			anchors.horizontalCenter: parent.horizontalCenter
			yawspeed: yawspeedSlider.value
			yacc: yaccSlider.value
		}

		Rectangle {
			width: 560
			height: 260
			color: "#f8f9fa"
			border.color: "#dee2e6"
			border.width: 1
			radius: 12
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 2
			anchors.horizontalCenter: parent.horizontalCenter

			Column {
				anchors.centerIn: parent
				spacing: 5

				Row {
					spacing: 5
					Text {
						text: "Pitch: " + Math.round(pitchSlider.value) + "°"
						width: 130
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
					}
					Slider {
						id: pitchSlider
						width: 280
						from: -45
						to: 45
						value: 0
						stepSize: 1
					}
				}

				Row {
					spacing: 5
					Text {
						text: "Roll: " + Math.round(rollSlider.value) + "°"
						width: 130
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
					}
					Slider {
						id: rollSlider
						width: 280
						from: -180
						to: 180
						value: 0
						stepSize: 1
					}
				}

				Row {
					spacing: 5
					Text {
						text: "Heading: " + Math.round(headingSlider.value) + "°"
						width: 130
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
					}
					Slider {
						id: headingSlider
						width: 280
						from: 0
						to: 360
						value: 0
						stepSize: 1
					}
				}

				Row {
					spacing: 5
					Text {
						text: "Airspeed: " + Math.round(airspeedSlider.value) + " kt"
						width: 130
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
					}
					Slider {
						id: airspeedSlider
						width: 280
						from: 0
						to: 200
						value: 20
						stepSize: 1
					}
				}

				Row {
					spacing: 5
					Text {
						text: "Yawspeed: " + yawspeedSlider.value.toFixed(2) + " r/s"
						width: 130
						font.pixelSize: 15
						font.bold: true
					}
					Slider {
						id: yawspeedSlider
						width: 280
						from: -5.0
						to: 5.0
						value: 0
						stepSize: 0.01
					}
				}

				Row {
					spacing: 5
					Text {
						text: "Yacc: " + yaccSlider.value.toFixed(2) + " mg"
						width: 130
						font.pixelSize: 15
						font.bold: true
					}
					Slider {
						id: yaccSlider
						width: 280
						from: -3.0
						to: 3.0
						value: 0
						stepSize: 0.01
					}
				}

				Button {
					text: "Reset All"
					anchors.horizontalCenter: parent.horizontalCenter
					onClicked: {
						pitchSlider.value = 0;
						rollSlider.value = 0;
						headingSlider.value = 0;
						airspeedSlider.value = 0;
						yawspeedSlider.value = 0;
						yaccSlider.value = 0;
					}
				}
			}
		}
	}
}

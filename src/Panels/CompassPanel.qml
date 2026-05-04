import Agc.Components
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: root
	uniqueName: "compassPanel"
	title: qsTr("Compass Panel")

	Rectangle {
		id: panelBackground
		anchors.fill: parent
		color: "#ffffff"

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 10
			spacing: 10

			GridLayout {
				id: instrumentGrid
				Layout.fillWidth: true
				Layout.fillHeight: true
				columns: 3
				rowSpacing: 10
				columnSpacing: 10

				AttitudeIndicator {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.minimumWidth: 80
					Layout.minimumHeight: 80
					pitch: pitchSlider.value
					roll: rollSlider.value
				}

				AirspeedIndicator {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.minimumWidth: 80
					Layout.minimumHeight: 80
					airspeedMs: airspeedSlider.value / 1.94384
				}

				TurnController {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.minimumWidth: 80
					Layout.minimumHeight: 80
					yawspeed: yawspeedSlider.value
					yacc: yaccSlider.value
				}

				CompassIndicator {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.minimumWidth: 80
					Layout.minimumHeight: 80
					heading: headingSlider.value
				}

				HeadingIndicator {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.minimumWidth: 80
					Layout.minimumHeight: 80
					heading: headingSlider.value
				}

				Item {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: height
					Layout.minimumWidth: 80
					Layout.minimumHeight: 80
				}
			}

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: testGrid.implicitHeight + 24
				color: "#f8f9fa"
				border.color: "#dee2e6"
				border.width: 1
				radius: 12

				GridLayout {
					id: testGrid
					anchors.centerIn: parent
					columns: 2
					columnSpacing: 8
					rowSpacing: 5

					Label {
						text: "Pitch: " + Math.round(pitchSlider.value) + "°"
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
						Layout.preferredWidth: 130
					}
					Slider {
						id: pitchSlider
						from: -45
						to: 45
						value: 0
						stepSize: 1
						Layout.fillWidth: true
						Layout.minimumWidth: 150
					}

					Label {
						text: "Roll: " + Math.round(rollSlider.value) + "°"
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
						Layout.preferredWidth: 130
					}
					Slider {
						id: rollSlider
						from: -180
						to: 180
						value: 0
						stepSize: 1
						Layout.fillWidth: true
						Layout.minimumWidth: 150
					}

					Label {
						text: "Heading: " + Math.round(headingSlider.value) + "°"
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
						Layout.preferredWidth: 130
					}
					Slider {
						id: headingSlider
						from: 0
						to: 360
						value: 0
						stepSize: 1
						Layout.fillWidth: true
						Layout.minimumWidth: 150
					}

					Label {
						text: "Airspeed: " + Math.round(airspeedSlider.value) + " kt"
						font.pixelSize: 15
						font.bold: true
						color: "#2c3e50"
						Layout.preferredWidth: 130
					}
					Slider {
						id: airspeedSlider
						from: 0
						to: 200
						value: 20
						stepSize: 1
						Layout.fillWidth: true
						Layout.minimumWidth: 150
					}

					Label {
						text: "Yawspeed: " + yawspeedSlider.value.toFixed(2) + " r/s"
						font.pixelSize: 15
						font.bold: true
					}
					Slider {
						id: yawspeedSlider
						from: -5.0
						to: 5.0
						value: 0
						stepSize: 0.01
						Layout.fillWidth: true
						Layout.minimumWidth: 150
					}

					Label {
						text: "Yacc: " + yaccSlider.value.toFixed(2) + " mg"
						font.pixelSize: 15
						font.bold: true
					}
					Slider {
						id: yaccSlider
						from: -3.0
						to: 3.0
						value: 0
						stepSize: 0.01
						Layout.fillWidth: true
						Layout.minimumWidth: 150
					}

					Item {
						Layout.fillWidth: true
					}
					Button {
						text: "Reset All"
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
}

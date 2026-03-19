import QtQuick 2.6
import "components"

Rectangle {
	color: "#d0e0e0"

	Text {
		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.topMargin: 20
		text: qsTr("Right Panel")
		font.pixelSize: 24
	}

	Grid {
		anchors.centerIn: parent
		columns: 3
		spacing: 30

		Column {
			spacing: 10

			AirspeedIndicator {
				indWidth: 150
				indHeight: 150
			}

			TelemetryBox {
				boxWidth: 150
				boxHeight: 50
			}
		}

		Column {
			spacing: 10

			Altimeter {
				indWidth: 150
				indHeight: 150
			}

			TelemetryBox {
				boxWidth: 150
				boxHeight: 50
			}
		}

		Column {
			spacing: 10

			AttitudeIndicator {
				indWidth: 150
				indHeight: 150
			}

			TelemetryBox {
				boxWidth: 150
				boxHeight: 50
			}
		}

		Column {
			spacing: 10

			HeadingIndicator {
				indWidth: 150
				indHeight: 150
			}

			TelemetryBox {
				boxWidth: 150
				boxHeight: 50
			}
		}

		Column {
			spacing: 10

			TurnCoordinator {
				indWidth: 150
				indHeight: 150
			}

			TelemetryBox {
				boxWidth: 150
				boxHeight: 50
			}
		}

		Column {
			spacing: 10

			VerticalSpeedIndicator {
				indWidth: 150
				indHeight: 150
			}

			TelemetryBox {
				boxWidth: 150
				boxHeight: 50
			}
		}
	}
}

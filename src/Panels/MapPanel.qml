import Agc.Components
import QtPositioning
import QtQuick
import com.kdab.dockwidgets as KDDW

KDDW.DockWidget {
	id: dockRoot
	uniqueName: "mapPanel"
	title: qsTr("Map")

	MapView {
		anchors.fill: parent

		// Static test telemetry — replace with MAVLink bindings.
		dronePosition: QtPositioning.coordinate(41.0082, 28.9784)
		droneAltitude: 120
		droneHeading: 45

		flightPath: [
			QtPositioning.coordinate(41.0080, 28.9780),
			QtPositioning.coordinate(41.0082, 28.9784),
			QtPositioning.coordinate(41.0085, 28.9790),
			QtPositioning.coordinate(41.0089, 28.9795),
			QtPositioning.coordinate(41.0092, 28.9800)
		]
	}
}

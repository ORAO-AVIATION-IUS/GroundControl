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

		threeD: false
		lightMode: false

		// Static test telemetry — replace with MAVLink bindings.
		drones: [({
					position: QtPositioning.coordinate(41.0082, 28.9784),
					altitude: 120,
					heading: 45
				}), ({
					position: QtPositioning.coordinate(41.0078, 28.9788),
					altitude: 80,
					heading: -30
				})]

		flightPaths: [[QtPositioning.coordinate(41.0080, 28.9780), QtPositioning.coordinate(41.0082, 28.9784), QtPositioning.coordinate(41.0085, 28.9790), QtPositioning.coordinate(41.0089, 28.9795), QtPositioning.coordinate(41.0092, 28.9800)], [QtPositioning.coordinate(41.0082, 28.9784), QtPositioning.coordinate(41.0078, 28.9788), QtPositioning.coordinate(41.0074, 28.9793), QtPositioning.coordinate(41.0070, 28.9799)]]
	}
}

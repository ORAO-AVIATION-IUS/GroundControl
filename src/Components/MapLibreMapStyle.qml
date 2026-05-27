pragma ComponentBehavior: Bound

import MapLibre.Location
import QtQml

Style {
	id: root

	property var drones: []
	property int selectedDroneUid: -1
	property bool threeD: true
	property bool satelliteMode: false
	property var trackedPaths: []
	property int revision: 0
	property real zoomLevel: 0

	MapGeometry {
		id: geometry
	}

	SourceParameter {
		styleId: "satellite-source"
		type: "raster"
		property var tiles: ["https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}", "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"]
		property int tileSize: 256
		property int maxzoom: 19
	}
	LayerParameter {
		styleId: "satellite-layer"
		type: "raster"
		property string source: "satellite-source"
		// qmllint disable incompatible-type
		layout: ({
				"visibility": root.satelliteMode ? "visible" : "none"
			})
	}

	SourceParameter {
		styleId: "drone-body-source"
		type: "geojson"
		property var data: root.threeD ? geometry.droneBodyGeoJson(root.drones, root.revision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "drone-body-layer"
		type: "fill-extrusion"
		property string source: "drone-body-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#2a2a2a",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.95
			})
	}

	SourceParameter {
		styleId: "drone-rotor-source"
		type: "geojson"
		property var data: root.threeD ? geometry.rotorGeoJson(root.drones, root.revision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "drone-rotor-layer"
		type: "fill-extrusion"
		property string source: "drone-rotor-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#ff3030",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.95
			})
	}

	SourceParameter {
		styleId: "tether-source"
		type: "geojson"
		property var data: root.threeD ? geometry.tetherSegmentsGeoJson(root.drones, root.revision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "tether-layer"
		type: "fill-extrusion"
		property string source: "tether-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#00d0ff",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.9
			})
	}

	SourceParameter {
		styleId: "ground-marker-source"
		type: "geojson"
		property var data: geometry.groundMarkerGeoJson(root.drones, root.selectedDroneUid, root.zoomLevel, root.revision)
	}
	LayerParameter {
		styleId: "ground-marker-layer"
		type: "fill"
		property string source: "ground-marker-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-color": ["get", "fill"],
				"fill-opacity": 0.9
			})
	}
	LayerParameter {
		styleId: "ground-marker-outline"
		type: "line"
		property string source: "ground-marker-source"
		// qmllint disable incompatible-type
		paint: ({
				"line-color": "#ffffff",
				"line-width": ["get", "outlineWidth"]
			})
	}

	SourceParameter {
		styleId: "flight-path-source"
		type: "geojson"
		property var data: geometry.flightPathGeoJson(root.trackedPaths)
	}
	LayerParameter {
		styleId: "flight-path-layer"
		type: "line"
		property string source: "flight-path-source"
		// qmllint disable incompatible-type
		paint: ({
				"line-color": "#ffaa00",
				"line-width": 3,
				"line-opacity": 0.85
			})
	}
}

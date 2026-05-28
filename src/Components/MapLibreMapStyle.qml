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
	property var missionItems: []
	property int mapMode: 0
	property int selectedMissionItemIndex: -1
	property int currentMissionItemIndex: 0
	property double homeLatitude: 0
	property double homeLongitude: 0
	property bool homeValid: false
	property bool returnHomeAfterMission: false
	property bool showMissionInsertHandles: false
	property int revision: 0
	property int missionRevision: 0
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
				"line-color": "#ff3030",
				"line-width": 3,
				"line-opacity": 0.85
			})
	}

	SourceParameter {
		styleId: "mission-segment-3d-source"
		type: "geojson"
		property var data: root.threeD ? geometry.missionSegmentExtrusionGeoJson(root.missionItems, root.missionRevision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "mission-segment-3d-layer"
		type: "fill-extrusion"
		property string source: "mission-segment-3d-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#ff9d00",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.92
			})
	}

	SourceParameter {
		styleId: "return-home-3d-source"
		type: "geojson"
		property var data: root.threeD ? geometry.returnHomeSegmentExtrusionGeoJson(root.missionItems, root.homeLatitude, root.homeLongitude, root.homeValid, root.returnHomeAfterMission, root.missionRevision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "return-home-3d-layer"
		type: "fill-extrusion"
		property string source: "return-home-3d-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#ff9d00",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.72
			})
	}

	SourceParameter {
		styleId: "mission-tether-source"
		type: "geojson"
		property var data: root.threeD ? geometry.missionTetherGeoJson(root.missionItems, root.missionRevision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "mission-tether-layer"
		type: "fill-extrusion"
		property string source: "mission-tether-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#8fe8ff",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.55
			})
	}

	SourceParameter {
		styleId: "mission-waypoint-3d-source"
		type: "geojson"
		property var data: root.threeD ? geometry.missionWaypointExtrusionGeoJson(root.missionItems, root.missionRevision) : geometry.emptyFeatureCollection
	}
	LayerParameter {
		styleId: "mission-waypoint-3d-layer"
		type: "fill-extrusion"
		property string source: "mission-waypoint-3d-source"
		// qmllint disable incompatible-type
		paint: ({
				"fill-extrusion-color": "#ffb000",
				"fill-extrusion-base": ["get", "base"],
				"fill-extrusion-height": ["get", "height"],
				"fill-extrusion-opacity": 0.95
			})
	}

	SourceParameter {
		styleId: "mission-path-source"
		type: "geojson"
		property var data: geometry.missionPathGeoJson(root.missionItems, root.missionRevision)
	}
	LayerParameter {
		styleId: "mission-path-layer"
		type: "line"
		property string source: "mission-path-source"
		// qmllint disable incompatible-type
		paint: ({
				"line-color": "#ff9d00",
				"line-width": 4,
				"line-opacity": 0.9,
				"line-dasharray": [1.5, 0.8]
			})
	}

	SourceParameter {
		styleId: "mission-insert-source"
		type: "geojson"
		property var data: geometry.missionInsertHandleGeoJson(root.missionItems, root.showMissionInsertHandles, root.missionRevision)
	}
	LayerParameter {
		styleId: "mission-insert-layer"
		type: "circle"
		property string source: "mission-insert-source"
		// qmllint disable incompatible-type
		paint: ({
				"circle-color": "#ffffff",
				"circle-radius": 4,
				"circle-stroke-color": "#ff9d00",
				"circle-stroke-width": 1.5,
				"circle-opacity": 0.58
			})
	}

	SourceParameter {
		styleId: "mission-waypoint-source"
		type: "geojson"
		property var data: geometry.missionWaypointGeoJson(root.missionItems, root.selectedMissionItemIndex, root.currentMissionItemIndex, root.mapMode, root.missionRevision)
	}
	LayerParameter {
		styleId: "mission-waypoint-layer"
		type: "circle"
		property string source: "mission-waypoint-source"
		// qmllint disable incompatible-type
		paint: ({
				"circle-color": ["get", "fill"],
				"circle-radius": ["get", "radius"],
				"circle-stroke-color": "#ffffff",
				"circle-stroke-width": ["get", "strokeWidth"],
				"circle-opacity": root.threeD ? 0.55 : 0.95
			})
	}

	SourceParameter {
		styleId: "return-home-source"
		type: "geojson"
		property var data: geometry.returnHomePathGeoJson(root.missionItems, root.homeLatitude, root.homeLongitude, root.homeValid, root.returnHomeAfterMission, root.missionRevision)
	}
	LayerParameter {
		styleId: "return-home-layer"
		type: "line"
		property string source: "return-home-source"
		// qmllint disable incompatible-type
		paint: ({
				"line-color": "#ff9d00",
				"line-width": 4,
				"line-opacity": 0.82,
				"line-dasharray": [0.8, 1.2]
			})
	}

	SourceParameter {
		styleId: "home-source"
		type: "geojson"
		property var data: geometry.homeGeoJson(root.homeLatitude, root.homeLongitude, root.homeValid)
	}
	LayerParameter {
		styleId: "home-layer"
		type: "circle"
		property string source: "home-source"
		// qmllint disable incompatible-type
		paint: ({
				"circle-color": "#6bffb8",
				"circle-radius": 8,
				"circle-stroke-color": "#ffffff",
				"circle-stroke-width": 2,
				"circle-opacity": 0.95
			})
	}
}
